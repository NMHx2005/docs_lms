# TỐI ƯU HÓA HIỆU SUẤT TRUY VẤN — LMS (MongoDB)

Mục tiêu: giảm độ trễ truy vấn (p95 < 200ms), tối ưu throughput, và đảm bảo tính nhất quán với chi phí hợp lý.

---

## 1) Nguyên tắc cốt lõi
- Thiết kế index theo query patterns (equality → sort → projection)
- Ưu tiên compound indexes; tránh index thừa trùng lặp
- Dùng projections (`fields`) + `.lean()` (Mongoose) để giảm chi phí deserialization
- Tránh `$regex` đầu chuỗi `^.*term` (không dùng được index); dùng `$text` hoặc prefix index
- Hạn chế `$lookup` sâu trong hot-path; cân nhắc denormalized fields/counters
- Phân trang: ưu tiên keyset pagination (seek) thay vì skip/limit cho dataset lớn

---

## 2) Query patterns & Index khuyến nghị

### 2.1 Courses listing (landing/search)
- Bộ lọc: `isPublished=true`, `isApproved=true`, `domain?`, `level?`, `search?`
- Sắp xếp: `-createdAt` (mới nhất), có thể `-upvotes` cho featured

Index đề xuất:
```js
// Filter theo trạng thái, instructor; sort theo createdAt
// Equality fields đặt trước, sort ở cuối
 db.courses.createIndex(
   { isPublished: 1, isApproved: 1, domain: 1, level: 1, createdAt: -1 },
   { name: 'idx_courses_filters_createdAt' }
);

// Text search trên title + description
 db.courses.createIndex(
   { title: 'text', description: 'text' },
   { name: 'txt_courses_title_desc', default_language: 'none' }
);

// Featured theo upvotes (tuỳ chọn)
 db.courses.createIndex(
   { isPublished: 1, isApproved: 1, upvotes: -1, createdAt: -1 },
   { name: 'idx_courses_featured' }
);
```

Mẫu truy vấn (Mongoose):
```ts
// Projection tối thiểu và .lean() để giảm overhead
Course.find({ isPublished: true, isApproved: true, ...(domain && { domain }), ...(level && { level }) })
  .sort({ createdAt: -1 })
  .select('title thumbnail domain level price upvotes createdAt')
  .limit(12)
  .lean();
```

Keyset pagination (seek):
```ts
// Với anchor createdAt + _id để ổn định thứ tự
const filters = { isPublished: true, isApproved: true };
if (domain) filters.domain = domain;
if (level) filters.level = level;
if (cursorCreatedAt && cursorId) {
  filters.$or = [
    { createdAt: { $lt: cursorCreatedAt } },
    { createdAt: cursorCreatedAt, _id: { $lt: cursorId } },
  ];
}
Course.find(filters)
  .sort({ createdAt: -1, _id: -1 })
  .limit(12)
  .lean();
```

### 2.2 Course detail + sections/lessons
- Truy vấn: `course by _id`, `sections by courseId sort order`, `lessons by sectionId sort order`

Indexes:
```js
 db.sections.createIndex({ courseId: 1, order: 1 }, { unique: true, name: 'uniq_section_order_in_course' });
 db.lessons.createIndex({ sectionId: 1, order: 1 }, { unique: true, name: 'uniq_lesson_order_in_section' });
```

Truy vấn:
```ts
await Promise.all([
  Course.findById(courseId).select('-relatedLinks -reports').lean(),
  Section.find({ courseId }).sort({ order: 1 }).lean(),
]);
// Lấy lessons theo nhiều sectionId với 1 query
Lesson.find({ sectionId: { $in: sectionIds } }).sort({ order: 1 }).lean();
```

### 2.3 Enrollments (dashboard học viên)
- Truy vấn: `by studentId`, phân trang theo `enrolledAt`

Indexes:
```js
 db.enrollments.createIndex({ studentId: 1, enrolledAt: -1 }, { name: 'idx_enrollments_by_student' });
 db.enrollments.createIndex({ studentId: 1, courseId: 1 }, { unique: true, name: 'uniq_enrollment_student_course' });
```

### 2.4 Submissions (giáo viên/chấm điểm)
- Truy vấn: `by assignmentId`, phân trang theo `submittedAt`

Indexes:
```js
 db.submissions.createIndex({ assignmentId: 1, submittedAt: -1 }, { name: 'idx_submissions_by_assignment' });
 db.submissions.createIndex({ assignmentId: 1, studentId: 1 }, { unique: true, name: 'uniq_submission_assignment_student' });
```

### 2.5 Ratings (upvote/report)
- Đếm nhanh theo courseId và type

Indexes:
```js
 db.course_ratings.createIndex({ courseId: 1, type: 1 }, { name: 'idx_ratings_course_type' });
 db.course_ratings.createIndex({ studentId: 1, courseId: 1, type: 1 }, { unique: true, name: 'uniq_rating_student_course_type' });
```

### 2.6 Bills/Refunds (lịch sử thanh toán)
- Truy vấn: theo `studentId`, lọc `status`, sort `paidAt`

Indexes:
```js
 db.bills.createIndex({ studentId: 1, paidAt: -1 }, { name: 'idx_bills_by_student' });
 db.bills.createIndex({ courseId: 1, paidAt: -1 }, { name: 'idx_bills_by_course' });
 db.refund_requests.createIndex({ studentId: 1, requestedAt: -1 }, { name: 'idx_refunds_by_student' });
```

---

## 3) Projections và lean() (Mongoose)
- Dùng `.select()` để chỉ lấy trường cần thiết cho UI
- Dùng `.lean()` để trả về plain objects (giảm ~30-50% CPU/mem với list lớn)
- Ví dụ:
```ts
Course.find(filter).select('title thumbnail price upvotes').limit(20).lean();
```

---

## 4) Phân trang: Keyset vs Offset
- Offset (skip/limit): đơn giản nhưng chậm khi `skip` lớn
- Keyset (seek): dùng cặp `(sortField, _id)` để phân trang nhanh, ổn định
- Index phải bao gồm các trường sort để seek hiệu quả

---

## 5) Caching (Redis) — đề xuất
- Cache nóng:
  - Landing courses (filters phổ biến): 30–120s
  - Course detail: 60–300s
  - Counts (upvotes/reports/enrollmentsCount): 60–300s
- Cache key: `courses:list:{filters_hash}`, `course:detail:{id}`
- Invalidate:
  - Khi cập nhật course/publish/approve → xóa các key liên quan
  - Khi cập nhật rating/enrollment → cập nhật counter + xóa key

---

## 6) Denormalized counters an toàn
- Trường: `courses.upvotes`, `courses.reports`, (tuỳ chọn) `courses.enrollmentsCount`
- Cập nhật:
```ts
// on rating create/delete
Courses.updateOne({ _id: courseId }, { $inc: { upvotes: +1 } });
// job định kỳ đối soát (nightly): aggregate từ course_ratings và sync
```

---

## 7) Text search vs Prefix search
- Toàn văn: dùng `text index` (tiếng Việt: `default_language: 'none'`), tránh stopwords không phù hợp
- Autocomplete/prefix: cân nhắc tạo `searchPrefix` (lowercase, không dấu) và index `{ searchPrefix: 1 }`, query `^prefix`
- Tránh `$regex: '.*term'` vì không dùng index

---

## 8) Aggregation pipelines tối ưu
- Đặt `$match` sớm để sử dụng index
- Dùng `$project` để loại bỏ field không cần thiết càng sớm càng tốt
- Tránh `$lookup` nặng trong hot-path; nếu cần, đảm bảo có index ở collection tham gia
- Dùng `$facet` để trả nhiều kết quả (list + counts) trong 1 round-trip nếu hợp lý

Ví dụ counts nhanh:
```js
// Đếm courses theo domain/level đã publish/approve
 db.courses.aggregate([
  { $match: { isPublished: true, isApproved: true } },
  { $group: { _id: { domain: '$domain', level: '$level' }, total: { $sum: 1 } } },
  { $sort: { 'total': -1 } }
]);
```

---

## 9) Monitoring & Explain plans
- Bật profiler mức slow query (ví dụ > 100ms)
```js
 db.setProfilingLevel(1, { slowms: 100 });
```
- Dùng `.explain('executionStats')` để kiểm tra index scan vs COLLSCAN
- Theo dõi metrics: p95/p99 latency, scanned docs/returned ratio (< 100 tốt), cache hit rate (Redis)

---

## 10) Housekeeping & Data lifecycle
- TTL collections (nếu có logs/tokens):
```js
 db.tokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
```
- Archive dữ liệu cũ (bills/refunds > 12–24 tháng) sang collection archive
- Xoá soft-delete → index có `partialFilterExpression: { deletedAt: { $exists: false } }`

---

## 11) Sharding (tương lai quy mô lớn)
- Khuyến nghị shard keys:
  - `enrollments`: `{ studentId: 1, courseId: 1 }` (truy vấn theo studentId)
  - `submissions`: `{ assignmentId: 1, studentId: 1 }`
  - `courses`: `{ domain: 1, _id: 1 }` (tránh hotspot)
- Bảo đảm query pattern có include shard key; tránh broadcast

---

## 12) Checklist áp dụng nhanh
- [ ] Tạo các index đã nêu (đặc biệt compound theo filters + sort)
- [ ] Chuyển list APIs sang `.select()` + `.lean()`
- [ ] Áp dụng keyset pagination cho list lớn
- [ ] Thêm Redis cache cho landing + detail + counters
- [ ] Dùng profiler + explain để tối ưu các truy vấn còn COLLSCAN
- [ ] Định kỳ đối soát counters (job nightly)

---

## 13) Phụ lục: Lệnh tạo index tổng hợp
```js
// Courses
 db.courses.createIndex({ isPublished: 1, isApproved: 1, domain: 1, level: 1, createdAt: -1 }, { name: 'idx_courses_filters_createdAt' });
 db.courses.createIndex({ title: 'text', description: 'text' }, { name: 'txt_courses_title_desc', default_language: 'none' });
 db.courses.createIndex({ isPublished: 1, isApproved: 1, upvotes: -1, createdAt: -1 }, { name: 'idx_courses_featured' });

// Sections & Lessons
 db.sections.createIndex({ courseId: 1, order: 1 }, { unique: true, name: 'uniq_section_order_in_course' });
 db.lessons.createIndex({ sectionId: 1, order: 1 }, { unique: true, name: 'uniq_lesson_order_in_section' });

// Enrollments
 db.enrollments.createIndex({ studentId: 1, enrolledAt: -1 }, { name: 'idx_enrollments_by_student' });
 db.enrollments.createIndex({ studentId: 1, courseId: 1 }, { unique: true, name: 'uniq_enrollment_student_course' });

// Submissions
 db.submissions.createIndex({ assignmentId: 1, submittedAt: -1 }, { name: 'idx_submissions_by_assignment' });
 db.submissions.createIndex({ assignmentId: 1, studentId: 1 }, { unique: true, name: 'uniq_submission_assignment_student' });

// Ratings
 db.course_ratings.createIndex({ courseId: 1, type: 1 }, { name: 'idx_ratings_course_type' });
 db.course_ratings.createIndex({ studentId: 1, courseId: 1, type: 1 }, { unique: true, name: 'uniq_rating_student_course_type' });

// Bills & Refunds
 db.bills.createIndex({ studentId: 1, paidAt: -1 }, { name: 'idx_bills_by_student' });
 db.bills.createIndex({ courseId: 1, paidAt: -1 }, { name: 'idx_bills_by_course' });
 db.refund_requests.createIndex({ studentId: 1, requestedAt: -1 }, { name: 'idx_refunds_by_student' });
```
