# CHUẨN HÓA CƠ SỞ DỮ LIỆU — LMS

Mục tiêu: Đảm bảo dữ liệu nhất quán, giảm dư thừa, tránh anomaly; vẫn cho phép denormalization có kiểm soát cho hiệu năng.

Áp dụng cho MongoDB (document DB) theo hướng hybrid: Normalized references + denormalized counters/indexed lookups.

---

## 1) Định nghĩa khóa và phụ thuộc (FDs) rút gọn
- USERS: email → (user)
- COURSES: _id → (title, level, instructorId, ...)
- SECTIONS: (courseId, order) → section; _id → (courseId, title, order)
- LESSONS: (sectionId, order) → lesson; _id → (sectionId, title, ...)
- ASSIGNMENTS: _id → (lessonId, ...)
- SUBMISSIONS: (assignmentId, studentId) → submission
- ENROLLMENTS: (studentId, courseId) → enrollment
- BILLS: _id → (studentId, courseId, ...)
- REFUND_REQUESTS: _id → (billId, ...)
- COURSE_RATINGS: (studentId, courseId, type) → rating

---

## 2) Kiểm tra Normal Forms

### 1NF (Dữ liệu nguyên tử, có khóa chính)
- Đạt: Tất cả collection có `_id` và trường primitive/reference.
- Lưu ý:
  - `users.roles` là mảng nhỏ có kích thước hạn chế — chấp nhận trong MongoDB (không cần tách bảng).
  - `assignments.questions[]` là cấu trúc lồng: chấp nhận nếu số lượng nhỏ; nếu cần phân tích/đánh version → tách sang collection riêng (xem mục 5).

### 2NF (Không phụ thuộc bộ phận vào khóa tổng hợp)
- Đạt: Các collection dùng `_id` làm khóa. Với khóa tổng hợp:
  - `enrollments(studentId, courseId)`: tất cả thuộc tính phụ thuộc đầy đủ vào cặp khóa.
  - `submissions(assignmentId, studentId)`: tương tự.

### 3NF (Không phụ thuộc bắc cầu vào khóa)
- Vi phạm phổ biến cần xử lý:
  - `courses.enrolledStudents[]` dư thừa so với `enrollments` → đề xuất loại bỏ để tránh bất nhất (xem mục 4).
  - Các trường đếm như `courses.upvotes`, `courses.reports` có thể giữ lại (denormalized counters) nếu cập nhật có kiểm soát (xem mục 6).

### BCNF (Khóa xác định tất cả FDs)
- Các FDs chính đã dựa trên khóa hoặc khóa tổng hợp. Giữ nguyên mô hình; tăng cường unique indexes để cưỡng bức.

---

## 3) Ràng buộc khóa/unique nên áp dụng

- USERS
  - Unique: `email`
- ENROLLMENTS
  - Unique composite: `(studentId, courseId)`
- SUBMISSIONS
  - Unique composite: `(assignmentId, studentId)`
- COURSE_RATINGS
  - Unique composite: `(studentId, courseId, type)`
- SECTIONS
  - Unique composite: `(courseId, order)` để đảm bảo thứ tự duy nhất trong khóa học
- LESSONS
  - Unique composite: `(sectionId, order)` để đảm bảo thứ tự duy nhất trong section

---

## 4) Refactor cấu trúc để chuẩn hóa

- COURSES
  - Loại bỏ: `enrolledStudents[]` (dư thừa so với ENROLLMENTS)
  - Giữ: `upvotes`, `reports` (đếm) — denormalized nhưng cập nhật theo transaction ứng dụng
- ENROLLMENTS
  - Nguồn chân lý cho đăng ký và progress
- COURSE_RATINGS
  - Một record cho mỗi `(studentId, courseId, type)`; đếm tổng hợp lưu ở `courses`
- SUBMISSIONS
  - Một record cho mỗi `(assignmentId, studentId)`; lần nộp nhiều → thêm trường `attempt` hoặc tách collection `SUBMISSION_ATTEMPTS`

---

## 5) Tuỳ chọn tách chi tiết Quiz (nếu cần phân tích sâu)

- ASSIGNMENT_QUESTIONS
  - Fields: `assignmentId`, `order`, `question`, `explanations?`
  - Unique: `(assignmentId, order)`
- ASSIGNMENT_OPTIONS
  - Fields: `questionId`, `order`, `text`, `isCorrect`
  - Unique: `(questionId, order)`
- SUBMISSION_ANSWERS
  - Fields: `submissionId`, `questionId`, `selectedOptionId[]`
  - Unique: `(submissionId, questionId)`

Nếu yêu cầu đơn giản hoặc quy mô nhỏ, có thể giữ `assignments.questions[]` như hiện tại.

---

## 6) Denormalization có kiểm soát

- `courses.upvotes`, `courses.reports`: cập nhật đồng thời khi tạo/sửa/xóa `course_ratings`
- `courses.enrollmentsCount` (tuỳ chọn): giữ bộ đếm để tối ưu hiển thị, cập nhật khi thêm/xoá `enrollment`
- Nguyên tắc: mọi giá trị đếm đều có thể rebuild từ collection nguồn (jobs định kỳ để đối soát)

---

## 7) Indexes & Constraints (MongoDB)

```js
// USERS
// unique email
 db.users.createIndex({ email: 1 }, { unique: true, name: 'uniq_user_email' });

// ENROLLMENTS
// mỗi học viên đăng ký 1 course tối đa 1 lần
 db.enrollments.createIndex(
   { studentId: 1, courseId: 1 },
   { unique: true, name: 'uniq_enrollment_student_course' }
 );

// SUBMISSIONS
// mỗi học viên nộp 1 submission/assignment (nếu cho nhiều lần nộp, thêm field attempt)
 db.submissions.createIndex(
   { assignmentId: 1, studentId: 1 },
   { unique: true, name: 'uniq_submission_assignment_student' }
 );

// COURSE_RATINGS
// 1 loại hành động/1 học viên/1 course
 db.course_ratings.createIndex(
   { studentId: 1, courseId: 1, type: 1 },
   { unique: true, name: 'uniq_rating_student_course_type' }
 );

// SECTIONS
// thứ tự duy nhất trong 1 course
 db.sections.createIndex(
   { courseId: 1, order: 1 },
   { unique: true, name: 'uniq_section_order_in_course' }
 );

// LESSONS
// thứ tự duy nhất trong 1 section
 db.lessons.createIndex(
   { sectionId: 1, order: 1 },
   { unique: true, name: 'uniq_lesson_order_in_section' }
 );

// COURSES
// tìm kiếm phổ biến
 db.courses.createIndex({ instructorId: 1, isPublished: 1, isApproved: 1 }, { name: 'idx_course_instructor_publish_approve' });
 db.courses.createIndex({ domain: 1 }, { name: 'idx_course_domain' });
 db.courses.createIndex({ level: 1 }, { name: 'idx_course_level' });
 db.courses.createIndex({ title: 'text', description: 'text' }, { name: 'txt_course_title_description' });
```

---

## 8) Migration đề xuất (MongoDB scripts)

### 8.1 Loại bỏ `courses.enrolledStudents[]`
```js
// 1) Snapshot (nếu cần tham chiếu tạm): backup sang collection tạm
// db.courses.find({ enrolledStudents: { $exists: true, $type: 'array', $ne: [] } }).forEach(...)

// 2) Drop field dư thừa
 db.courses.updateMany(
   { enrolledStudents: { $exists: true } },
   { $unset: { enrolledStudents: '' } }
 );
```

### 8.2 Backfill counters (tùy chọn)
```js
// Rebuild upvotes/reports từ course_ratings
const ratingsByCourse = db.course_ratings.aggregate([
  { $group: {
      _id: { courseId: '$courseId', type: '$type' },
      count: { $sum: 1 }
  }}
]);
// Apply: set courses.upvotes / courses.reports theo _id.type
```

### 8.3 Thêm unique indexes (an toàn)
```js
// Dùng createIndex (idempotent). Nếu dữ liệu trùng, xử lý duplicates trước.
```

---

## 9) Validation (Mongoose JSON schema gợi ý)
- Bảo đảm pattern email, minLength password, enum cho `roles`, `level`, `status`, `type`.
- Custom validator: `price >= 0`, `progress ∈ [0,100]`, `dueDate >= now` (nếu cần).

---

## 10) Checklist áp dụng
- [ ] Gỡ `courses.enrolledStudents[]`
- [ ] Tạo unique indexes cho composite keys (Enrollments, Submissions, Ratings)
- [ ] Tạo unique order cho Sections/Lessons theo cha
- [ ] Thiết lập text index cho tìm kiếm courses
- [ ] Viết hooks/service đảm bảo cập nhật counters nhất quán
- [ ] (Tùy chọn) Tách quiz sang collections riêng nếu nhu cầu phân tích cao

---

## 11) Lợi ích sau chuẩn hóa
- Tránh bất nhất đăng ký (1 học viên/1 course) và trùng bài nộp
- Truy vấn nhanh hơn nhờ indexes đúng mục tiêu
- Chi phí bảo trì thấp, dễ mở rộng; counters vẫn đáp ứng hiệu năng UI
