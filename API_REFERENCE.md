# LMS API Reference (Detailed)

Tài liệu mô tả toàn bộ API của hệ thống LMS, dùng làm chuẩn khi triển khai để giảm lỗi. Bao gồm conventions, xác thực, lỗi chuẩn, và đặc tả chi tiết từng endpoint.

- Base URL (dev): `http://localhost:4000`
- Base URL (prod): tuỳ môi trường deploy
- Tất cả thời gian: ISO 8601 (UTC)
- ID dạng: MongoDB ObjectId (24 hex chars)

---

## 0) Conventions & Standards

### 0.1 Xác thực
- Scheme: `Authorization: Bearer <access_token>`
- Vai trò: `student`, `teacher`, `admin`
- Refresh token: qua endpoint `POST /api/auth/refresh`

### 0.2 Response envelope
- Thành công:
```json
{ "success": true, "data": <payload>, "meta": { /* optional */ } }
```
- Lỗi:
```json
{ "success": false, "error": "<message>", "errorCode": <number>, "details": { /* optional */ } }
```

### 0.3 Phân trang & lọc
- Query: `page` (>=1, default 1), `limit` (1..100, default 10)
- Trả về:
```json
{
  "success": true,
  "data": [/* items */],
  "meta": { "page": 1, "limit": 10, "total": 123, "totalPages": 13 }
}
```
- Có thể hỗ trợ keyset pagination cho list lớn (sort theo `createdAt, _id`).

### 0.4 Mã lỗi chuẩn (trích yếu)
| Code | Mô tả |
|------|------|
| 1001 | Email already exists |
| 1002 | Invalid email format |
| 1003 | Password too short |
| 1201 | Invalid credentials |
| 1202 | Token expired |
| 1203 | Invalid token |
| 2001 | Course title validation failed |
| 2002 | Course not found |
| 2003 | Subscription limit exceeded |
| 3001 | Payment failed |
| 3002 | Insufficient funds |
| 4001 | AI feature requires subscription |
| 4002 | Content moderation failed |
| 5001 | File upload failed |
| 5002 | File too large |
| 9999 | Internal server error |

---

## 1) Authentication

### POST /api/auth/register
- Mục đích: Đăng ký tài khoản mới
- Auth: Public
- Body:
```json
{ "email":"user@example.com", "password":"min6", "name":"Nguyễn Văn A", "role":"student" }
```
- Validation: email hợp lệ; password >= 6; role ∈ {student,teacher}
- 201:
```json
{ "success": true, "data": { "user": {"_id":"...","email":"...","roles":["student"]}, "token":"<jwt>" } }
```
- 400: `{ errorCode: 1001|1002|1003 }`

### POST /api/auth/login
- Body: `{ "email":"...", "password":"..." }`
- 200: `{ success, data: { user, token } }`
- 401: `{ errorCode: 1201 }`

### POST /api/auth/refresh
- Header: `Authorization: Bearer <refresh_token>`
- 200: `{ success, data: { token: "<new_access_token>" } }`

### POST /api/auth/logout
- 200: `{ success: true }`

### GET /api/auth/me
- Auth: Any logged-in
- 200: `{ success, data: user }`

---

## 2) Users

### GET /api/users/me
- Auth: Any logged-in
- 200: thông tin user hiện tại

### PUT /api/users/me
- Body (optional fields): `{ name?, avatar? }`
- 200: user cập nhật

### GET /api/users
- Auth: admin
- Query: `page,limit,role?`
- 200: danh sách users

### GET /api/users/:id
- Auth: admin hoặc chính chủ (giới hạn trường)
- 200: user

### PATCH /api/users/:id/roles
- Auth: admin
- Body: `{ roles: ["student","teacher"] }`
- 200: user

### PATCH /api/users/:id/status
- Auth: admin
- Body: `{ isActive: true|false }`
- 200: user

---

## 3) Courses

### GET /api/courses
- Auth: Public
- Query: `page,limit,domain?,level?,search?`
- 200: danh sách khoá được publish & approve

### POST /api/courses
- Auth: teacher | admin
- Body:
```json
{
  "title":"...", "description":"...", "domain":"IT", "level":"beginner",
  "price": 500000, "prerequisites":[], "benefits":[], "relatedLinks":[], "thumbnail":"..."
}
```
- Validation: title 1..200; description >= 10; level ∈ enum; price >= 0
- 201: course (isPublished=false, isApproved=false)

### GET /api/courses/:id
- Auth: Public (nếu isPublished & isApproved) / Owner/Admin xem draft
- 200: course chi tiết

### PUT /api/courses/:id
- Auth: owner (teacher) hoặc admin
- Body: giống POST (fields optional)
- 200: course đã cập nhật

### DELETE /api/courses/:id
- Auth: owner hoặc admin
- 204

### PATCH /api/courses/:id/publish
- Auth: admin
- Body: `{ isPublished: true|false }`
- 200: course

### PATCH /api/courses/:id/approve
- Auth: admin
- Body: `{ isApproved: true|false }`
- 200: course

---

## 4) Sections

### GET /api/courses/:courseId/sections
- Auth: Public nếu course public; owner/admin nếu draft
- 200: list sections sort `order`

### POST /api/courses/:courseId/sections
- Auth: owner/admin
- Body: `{ title, order }`
- 201: section

### PUT /api/sections/:id
- Auth: owner/admin
- Body: `{ title?, order? }`
- 200: section

### DELETE /api/sections/:id
- Auth: owner/admin
- 204

---

## 5) Lessons

### GET /api/sections/:sectionId/lessons
- 200: list lessons sort `order`

### POST /api/sections/:sectionId/lessons
- Auth: owner/admin
- Body: `{ title, type, content?, videoUrl?, videoDuration?, fileUrl?, order, isRequired }`
- Validation: type ∈ enum; if type=video cần `videoUrl`
- 201: lesson

### PUT /api/lessons/:id
- Auth: owner/admin
- Body: như POST (optional)
- 200: lesson

### DELETE /api/lessons/:id
- Auth: owner/admin
- 204

---

## 6) Assignments

### GET /api/lessons/:lessonId/assignments
- 200: list assignments

### POST /api/lessons/:lessonId/assignments
- Auth: owner/admin
- Body: `{ title, description, type, dueDate?, maxScore, questions? }`
- 201: assignment

### GET /api/assignments/:id
- Auth: enrolled student/owner/admin
- 200: assignment

### PUT /api/assignments/:id
- Auth: owner/admin
- 200

### DELETE /api/assignments/:id
- Auth: owner/admin
- 204

---

## 7) Submissions

### GET /api/submissions?assignmentId=...&page&limit
- Auth: teacher owner của course hoặc admin
- 200: danh sách submissions

### POST /api/submissions
- Auth: enrolled student
- Body (tuỳ type):
```json
{ "assignmentId":"...", "answers":["A","C"], "fileUrl":"..." }
```
- Rule: unique per `(assignmentId, studentId)` (nếu không cho nhiều lượt nộp)
- 201: submission

### GET /api/submissions/:id
- Auth: owner (student) / teacher / admin
- 200

### PATCH /api/submissions/:id/score
- Auth: teacher/admin
- Body: `{ score: 0..maxScore }`
- 200: submission graded

---

## 8) Enrollments & Progress

### GET /api/enrollments?student=me&page&limit
- Auth: logged-in
- 200: danh sách enrollments của chính user

### GET /api/courses/:courseId/enrollment
- Auth: logged-in
- 200: enrollment của user hiện tại (nếu có)

### PATCH /api/enrollments/:id/progress
- Auth: logged-in (owner)
- Body: `{ completedLessonId?, progress? }`
- 200: enrollment cập nhật

### POST /api/progress/track-video
- Auth: logged-in (enrolled)
- Body: `{ lessonId, watchedSeconds }`
- 200: cập nhật tiến độ; auto-complete nếu >= 50% thời lượng

---

## 9) Payments & Bills

### POST /api/payments/create-payment
- Auth: logged-in (student)
- Body: `{ courseId, amount, currency:"VND" }`
- 200: `{ paymentIntent, clientSecret }`

### POST /api/payments/confirm
- Auth: logged-in
- Body: `{ paymentIntentId, courseId }`
- 200: `{ success, data: { enrollment, bill } }`

### GET /api/bills?student=me&page&limit
- Auth: logged-in
- 200: danh sách bills của user

### GET /api/bills/:id
- Auth: owner/admin
- 200: bill

---

## 10) Refunds

### POST /api/refunds/request
- Auth: logged-in (owner bill)
- Body: `{ courseId, billId, reason }`
- Rule: chỉ trong 7 ngày từ `paidAt`; bill.status = completed
- 201: refund request (status=pending)

### PUT /api/refunds/:id/approve
- Auth: admin
- 200: cập nhật refund (status=approved) + revoke access + cập nhật bill

### PUT /api/refunds/:id/reject
- Auth: admin
- 200: status=rejected

### GET /api/refunds?status=&page&limit
- Auth: admin (toàn bộ) / student (chỉ của mình)
- 200

---

## 11) Ratings (Upvote/Report)

### POST /api/courses/:id/rate
- Auth: logged-in (enrolled hoặc public tuỳ policy)
- Body: `{ type: "upvote" | "report", reason? }`
- Rule: unique per `(studentId, courseId, type)`; giới hạn 7 ngày giữa các lần
- 201: rating

### DELETE /api/courses/:id/rate?type=upvote|report
- Auth: owner rating / admin
- 204

### GET /api/courses/:id/ratings?page&limit&type?
- Auth: admin
- 200: danh sách ratings

---

## 12) AI Integration

### POST /api/ai/generate-avatar
- Auth: logged-in; yêu cầu plan `pro|advanced`
- Body: `{ name, description }`
- 200: `{ avatarUrl }` | 402 `{ errorCode: 4001 }`

### POST /api/ai/generate-thumbnail
- Auth: teacher/admin; plan `pro|advanced`
- Body: `{ title, description }`
- 200: `{ thumbnailUrl }`

### POST /api/ai/moderate-content
- Auth: admin | teacher (advanced)
- Body: `{ content, contentType: "title|description|lesson" }`
- 200: `{ isAppropriate, confidence, suggestions[] }`

---

## 13) Validation rules (tóm tắt chống lỗi)
- Email: RFC5322 (dùng validator chuẩn)
- Password: ≥ 6 ký tự; hash bằng bcrypt (10 rounds)
- Title: 1..200; Description: ≥ 10
- Price: number ≥ 0; Currency: `VND`
- Enum: kiểm tra strict (không auto-cast)
- ObjectId: validate dạng hex 24 chars
- Authorization: kiểm tra ownership (teacher owner course/lesson/assignment)
- Rate limiting: đăng nhập, AI endpoints, payment endpoints (tối thiểu)

---

## 14) Idempotency & Side effects
- Payments confirm: idempotent theo `paymentIntentId`
- Ratings: idempotent theo `(studentId, courseId, type)` (unique index)
- Submissions: idempotent theo `(assignmentId, studentId)` (tuỳ policy)

---

## 15) Security notes
- Bắt buộc HTTPS ở production
- JWT bí mật mạnh (`JWT_SECRET`), thời hạn access phù hợp
- CORS: whitelist domain frontend
- Upload: kiểm tra loại file, kích thước; quét virus nếu có
- Logging: không log token/password; log error với correlation id

---

## 16) Examples (curl)

Đăng nhập:
```bash
curl -X POST http://localhost:4000/api/auth/login -H 'Content-Type: application/json' -d '{"email":"user@example.com","password":"pass123"}'
```
Tạo khoá học:
```bash
curl -X POST http://localhost:4000/api/courses -H 'Authorization: Bearer <TOKEN>' -H 'Content-Type: application/json' -d '{"title":"React","description":"...","domain":"IT","level":"beginner","price":500000}'
```
Tạo thanh toán:
```bash
curl -X POST http://localhost:4000/api/payments/create-payment -H 'Authorization: Bearer <TOKEN>' -H 'Content-Type: application/json' -d '{"courseId":"<id>","amount":500000,"currency":"VND"}'
```

---

Tài liệu này là chuẩn để dev backend/QA dựa vào khi implement/test, nhằm giảm lỗi do sai yêu cầu, thiếu validate, lệch quy ước. Khi bổ sung tính năng mới, hãy cập nhật file này đồng bộ với ERD và cấu trúc DB.
