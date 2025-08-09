# Tài liệu chi tiết cấu trúc Database — LMS (MongoDB)

Tài liệu này mô tả chi tiết mô hình dữ liệu của hệ thống LMS sử dụng MongoDB theo hướng normalized tham chiếu + denormalized counters có kiểm soát. Nội dung gồm: chuẩn đặt tên, schema từng collection, indexes, quan hệ, ràng buộc nghiệp vụ, ví dụ documents và truy vấn mẫu.

- Kiểu CSDL: MongoDB (document-based)
- Định danh: `_id` kiểu `ObjectId` cho tất cả collections
- Trường thời gian: mỗi document có `createdAt`, `updatedAt` (`Date`, ISO)

Tham chiếu nhanh:
- ERD: xem `document_database/ERD.md`
- Chuẩn hoá: `document_database/NORMALIZATION.md`
- Tối ưu: `document_database/PERFORMANCE_OPTIMIZATION.md`

---

## 1. Chuẩn đặt tên & kiểu dữ liệu

- Tên collection: chữ thường, số nhiều (ví dụ: `users`, `courses`)
- Field boolean: tiền tố `is...` (ví dụ: `isActive`, `isPublished`)
- Enum lưu ở dạng chuỗi chữ thường (ví dụ: `roles: ['student','teacher','admin']`)
- Ngày giờ: `Date` (ISO 8601)

Các enum dùng trong hệ thống:
- User roles: `student | teacher | admin`
- Course level: `beginner | intermediate | advanced`
- Assignment type: `file | quiz`
- Lesson type: `video | text | file | link`
- Bill status: `pending | completed | failed | refunded`
- Bill purpose: `course_purchase | subscription | refund`
- Refund status: `pending | approved | rejected`
- Rating type: `upvote | report`

---

## 2. Collections chi tiết

### 2.1 `users`
Quản lý tài khoản người dùng.

Trường chính:
- `email` (string, unique): Email đăng nhập
- `password` (string, hashed): Mật khẩu mã hoá (bcrypt)
- `name` (string): Tên hiển thị
- `avatar` (string, optional): URL ảnh đại diện
- `roles` (string[]): Danh sách vai trò
- `subscriptionPlan` (string): `free | pro | advanced`
- `subscriptionExpiresAt` (Date, optional)
- `isActive` (bool, default: true)
- `emailVerified` (bool, default: false)
- `createdAt` (Date), `updatedAt` (Date)

Ví dụ:
```json
{
  "_id": "64f0c...",
  "email": "user@example.com",
  "password": "$2b$10$...",
  "name": "Nguyễn Văn A",
  "roles": ["student"],
  "subscriptionPlan": "free",
  "isActive": true,
  "emailVerified": false,
  "createdAt": "2025-08-01T07:00:00.000Z",
  "updatedAt": "2025-08-01T07:00:00.000Z"
}
```

Indexes:
- `{ email: 1 }` unique
- `{ roles: 1 }`

---

### 2.2 `courses`
Thông tin khoá học, trạng thái duyệt/publish.

Trường chính:
- `title` (string), `description` (string)
- `thumbnail` (string, optional)
- `domain` (string): Lĩnh vực (VD: `IT`, `Economics`, ...)
- `level` (string): `beginner | intermediate | advanced`
- `prerequisites` (string[]), `benefits` (string[]), `relatedLinks` (string[])
- `instructorId` (ObjectId → `users`)
- `price` (number)
- `isPublished` (bool), `isApproved` (bool)
- Denormalized counters: `upvotes` (number), `reports` (number)
- `createdAt` (Date), `updatedAt` (Date)

Ví dụ:
```json
{
  "_id": "64f0d...",
  "title": "React Fundamentals",
  "description": "Khoá học React từ cơ bản đến nâng cao",
  "domain": "IT",
  "level": "beginner",
  "instructorId": "64f0c...",
  "price": 500000,
  "isPublished": true,
  "isApproved": true,
  "upvotes": 25,
  "reports": 0,
  "createdAt": "2025-08-02T03:00:00.000Z",
  "updatedAt": "2025-08-02T03:00:00.000Z"
}
```

Indexes:
- `{ isPublished:1, isApproved:1, domain:1, level:1, createdAt:-1 }`
- `{ isPublished:1, isApproved:1, upvotes:-1, createdAt:-1 }` (featured)
- `{ instructorId:1, isPublished:1, isApproved:1 }`
- `{ domain:1 }`, `{ level:1 }`
- Text: `{ title: 'text', description: 'text' }`

---

### 2.3 `sections`
Phần/chương của khoá học.

Trường chính:
- `courseId` (ObjectId → `courses`)
- `title` (string)
- `order` (number): Thứ tự trong khoá học (duy nhất theo `courseId`)
- `createdAt` (Date), `updatedAt` (Date)

Indexes:
- Unique: `{ courseId:1, order:1 }`
- `{ courseId:1 }`

---

### 2.4 `lessons`
Bài học thuộc section.

Trường chính:
- `sectionId` (ObjectId → `sections`)
- `title` (string)
- `content` (string, rich text)
- `type` (string): `video | text | file | link`
- `videoUrl` (string, optional), `videoDuration` (number, seconds)
- `fileUrl` (string, optional)
- `order` (number, unique theo `sectionId`)
- `isRequired` (bool)
- `createdAt` (Date), `updatedAt` (Date)

Indexes:
- Unique: `{ sectionId:1, order:1 }`
- `{ sectionId:1 }`, `{ type:1 }`

---

### 2.5 `assignments`
Bài tập/bài kiểm tra trong bài học.

Trường chính:
- `lessonId` (ObjectId → `lessons`)
- `title` (string), `description` (string)
- `type` (string): `file | quiz`
- `dueDate` (Date, optional)
- `maxScore` (number)
- `questions` (array, optional cho `quiz`): `{ question, options[], correctAnswer }`
- `createdAt` (Date), `updatedAt` (Date)

Indexes:
- `{ lessonId:1 }`, `{ dueDate:1 }`

Gợi ý mở rộng nếu quiz lớn/phân tích sâu: tách `ASSIGNMENT_QUESTIONS`, `ASSIGNMENT_OPTIONS`, `SUBMISSION_ANSWERS` (xem NORMALIZATION.md).

---

### 2.6 `submissions`
Bài nộp của học viên.

Trường chính:
- `assignmentId` (ObjectId → `assignments`)
- `studentId` (ObjectId → `users`)
- `answers` (string[], optional cho quiz)
- `fileUrl` (string, optional cho file)
- `score` (number, optional)
- `submittedAt` (Date), `gradedAt` (Date, optional)

Ràng buộc nghiệp vụ: mặc định 1 submission cho mỗi `(assignmentId, studentId)`. Nếu cần nhiều lượt nộp, thêm trường `attempt` hoặc collection riêng cho attempts.

Indexes:
- `{ assignmentId:1, submittedAt:-1 }`
- Unique: `{ assignmentId:1, studentId:1 }`

---

### 2.7 `enrollments`
Đăng ký khoá học + tiến độ học.

Trường chính:
- `studentId` (ObjectId → `users`)
- `courseId` (ObjectId → `courses`)
- `enrolledAt` (Date), `completedAt` (Date, optional)
- `progress` (number 0-100)
- `completedLessons` (ObjectId[] → `lessons`)
- `certificate` (string, optional URL)
- `createdAt` (Date), `updatedAt` (Date)

Ràng buộc: mỗi `(studentId, courseId)` duy nhất.

Indexes:
- Unique: `{ studentId:1, courseId:1 }`
- `{ studentId:1, enrolledAt:-1 }`

---

### 2.8 `bills`
Lịch sử thanh toán.

Trường chính:
- `studentId` (ObjectId → `users`)
- `courseId` (ObjectId → `courses`)
- `amount` (number), `currency` (string, ví dụ `VND`)
- `paymentMethod` (string, ví dụ `stripe`)
- `status` (string): `pending | completed | failed | refounded`
- `transactionId` (string)
- `purpose` (string): `course_purchase | subscription | refund`
- `paidAt` (Date, optional), `refundedAt` (Date, optional)
- `createdAt` (Date), `updatedAt` (Date)

Indexes:
- `{ studentId:1, paidAt:-1 }`
- `{ courseId:1, paidAt:-1 }`
- `{ status:1 }`, `{ purpose:1 }`

---

### 2.9 `refund_requests`
Yêu cầu hoàn tiền.

Trường chính:
- `studentId` (ObjectId → `users`)
- `courseId` (ObjectId → `courses`)
- `billId` (ObjectId → `bills`)
- `reason` (string)
- `status` (string): `pending | approved | rejected`
- `adminNotes` (string, optional)
- `requestedAt` (Date), `processedAt` (Date, optional)
- `createdAt` (Date), `updatedAt` (Date)

Indexes:
- `{ studentId:1, requestedAt:-1 }`
- `{ courseId:1, requestedAt:-1 }`
- `{ billId:1 }`, `{ status:1 }`

---

### 2.10 `course_ratings`
Upvote/report của học viên với khoá học.

Trường chính:
- `courseId` (ObjectId → `courses`)
- `studentId` (ObjectId → `users`)
- `type` (string): `upvote | report`
- `reason` (string, optional cho report)
- `lastActionAt` (Date) — phục vụ giới hạn 7 ngày giữa các lần
- `createdAt` (Date), `updatedAt` (Date)

Ràng buộc: duy nhất cho mỗi `(studentId, courseId, type)`.

Indexes:
- `{ courseId:1, type:1 }`
- Unique: `{ studentId:1, courseId:1, type:1 }`

---

## 3. Quan hệ & ràng buộc nghiệp vụ

- `users` 1–N `courses` (giảng viên → khoá học)
- `courses` 1–N `sections` → 1–N `lessons`
- `lessons` 1–N `assignments` → 1–N `submissions`
- `users` 1–N `enrollments` (học viên đăng ký nhiều khoá)
- `users` 1–N `bills` / 1–N `refund_requests`
- `users` 1–N `course_ratings`

Ràng buộc khoá tổng hợp (enforced bằng unique index):
- `enrollments(studentId, courseId)` — mỗi học viên chỉ có 1 enrollment/khoá
- `submissions(assignmentId, studentId)` — mỗi học viên 1 bài nộp/assignment (mặc định)
- `course_ratings(studentId, courseId, type)` — 1 loại rating/1 học viên/1 khoá

Counters denormalized (trong `courses`):
- `upvotes`, `reports` được cập nhật đồng bộ khi tạo/sửa/xoá bản ghi `course_ratings`. Có thể đối soát định kỳ bằng job aggregate.

---

## 4. Quy ước validate & mặc định

- Email hợp lệ, unique trên `users`
- Mật khẩu bcrypt (không lưu plain text)
- `price >= 0`, `progress ∈ [0,100]`
- Enum đúng giá trị quy định
- `dueDate` (nếu có) phải ≥ `now` (nếu áp chính sách hạn nộp)

---

## 5. Truy vấn mẫu (MongoDB/Mongoose)

- Danh sách khoá học hiển thị landing (đã duyệt + publish), phân trang theo thời gian mới nhất:
```js
// filters: { domain?, level? }
db.courses.find({ isPublished: true, isApproved: true })
  .sort({ createdAt: -1 })
  .project({ title: 1, thumbnail: 1, domain: 1, level: 1, price: 1, upvotes: 1, createdAt: 1 })
  .limit(12)
```

- Lấy sections và lessons của một khoá:
```js
const sections = db.sections.find({ courseId }).sort({ order: 1 }).toArray();
const lessons = db.lessons.find({ sectionId: { $in: sections.map(s => s._id) } }).sort({ order: 1 }).toArray();
```

- Kiểm tra enrollment duy nhất:
```js
db.enrollments.createIndex({ studentId: 1, courseId: 1 }, { unique: true });
```

- Tính nhanh tổng upvotes cho một khoá (đối soát):
```js
db.course_ratings.countDocuments({ courseId, type: 'upvote' });
```

---

## 6. Dữ liệu mẫu (seed tối thiểu)

```json
// users
{ "email": "admin@example.com", "password": "<bcrypt>", "name": "Admin", "roles": ["admin"], "subscriptionPlan": "free", "isActive": true, "emailVerified": true }

// courses
{ "title": "Node.js Essentials", "description": "Học Node căn bản", "domain": "IT", "level": "beginner", "instructorId": "<userId>", "price": 300000, "isPublished": true, "isApproved": true, "upvotes": 0, "reports": 0 }

// sections
{ "courseId": "<courseId>", "title": "Giới thiệu", "order": 1 }

// lessons
{ "sectionId": "<sectionId>", "title": "Node là gì?", "type": "video", "videoUrl": "https://...", "videoDuration": 900, "order": 1, "isRequired": true }

// enrollments
{ "studentId": "<userId>", "courseId": "<courseId>", "enrolledAt": "2025-08-01T07:00:00.000Z", "progress": 0, "completedLessons": [] }
```

---

## 7. Lưu ý triển khai & vận hành

- Tạo indexes theo danh sách ở từng collection để bảo đảm hiệu năng.
- Dùng `.select()` và `.lean()` ở Mongoose cho danh sách lớn.
- Sử dụng keyset pagination (seek) cho danh sách khoá học nhiều trang.
- Backups: xem `document_database/DB_BACKUP_GUIDE.md` (hỗ trợ local/Atlas, Task Scheduler, restore + checksum).

---

## 8. Phiên bản & mở rộng tương lai

- Có thể bổ sung `soft delete` (trường `deletedAt`) với partial index
- Phân tích sâu quiz: tách collections chi tiết như khuyến nghị trong `NORMALIZATION.md`
- Chuẩn bị cho sharding: khoá shard gợi ý ở `PERFORMANCE_OPTIMIZATION.md`

---

Tài liệu này là chuẩn tham chiếu khi phát triển API, viết migration, và tối ưu truy vấn. Hãy giữ đồng bộ với ERD, Normalization và Performance để hệ thống ổn định và mở rộng tốt.
