# TÀI LIỆU ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS) - PHIÊN BẢN CẬP NHẬT
## HỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) - LEARNING MANAGEMENT SYSTEM

---

## 1. GIỚI THIỆU

### 1.1 Mục đích
Tài liệu này mô tả chi tiết các yêu cầu chức năng và phi chức năng của hệ thống Quản lý Học tập (LMS), cung cấp một nền tảng học tập trực tuyến toàn diện với các tính năng đặc biệt như hệ thống subscription, tích hợp AI, theo dõi video, và quản lý hoàn tiền. Tài liệu này được sử dụng bởi các bên liên quan bao gồm khách hàng, đội ngũ phát triển, kiểm thử và bảo trì để đảm bảo sự hiểu biết chung về mục tiêu và phạm vi dự án.

### 1.2 Phạm vi
Hệ thống LMS cung cấp các tính năng chính sau:

- **Quản lý người dùng và phân quyền**: Đăng ký, đăng nhập, phân quyền theo vai trò (Student, Teacher, Admin)
- **Quản lý khóa học và nội dung học tập**: Tạo, chỉnh sửa, quản lý khóa học với cấu trúc section/lesson
- **Hệ thống bài tập và kiểm tra**: Bài tập nộp file và trắc nghiệm với một đáp án đúng
- **Hệ thống subscription**: 3 gói dịch vụ (Free, Pro, Advanced) với giới hạn tính năng
- **Thanh toán và hoàn tiền**: Luồng thanh toán qua Admin, chính sách hoàn tiền 7 ngày
- **Tích hợp AI**: Tạo avatar, thumbnail, và duyệt nội dung tự động
- **Theo dõi tiến độ học tập**: Tracking video, link, và bài đọc
- **Hệ thống đánh giá và báo cáo**: Upvote, report với giới hạn thời gian
- **Chứng chỉ**: Tự động tạo khi hoàn thành khóa học
- **Thông báo real-time**: Socket.io cho các sự kiện quan trọng

### 1.3 Đối tượng sử dụng

#### 1.3.1 Học viên (Student)
- **Chức năng chính:**
  - Duyệt và mua khóa học
  - Truy cập khóa học đã mua
  - Xem bài giảng (video embed/link, text)
  - Nộp bài tập (file upload) và làm bài trắc nghiệm
  - Theo dõi tiến độ học tập tự động
  - Đánh giá/báo cáo khóa học (upvote/report)
  - Xem thống kê cá nhân (số khóa học, số hoàn thành, số bài tập, số tiền đã chi)
  - Yêu cầu hoàn tiền (trong vòng 7 ngày)
  - Nhận chứng chỉ khi hoàn thành khóa học

#### 1.3.2 Giảng viên (Teacher)
- **Chức năng chính:**
  - Tạo và chỉnh sửa khóa học với cấu trúc section/lesson
  - Quản lý nội dung (video embed/link, text, file upload)
  - Tạo bài tập (nộp file và trắc nghiệm một đáp án đúng)
  - Xem phân tích khóa học (số học viên, doanh thu, thu nhập sau phí nền tảng)
  - Nhận thông báo (bình luận, đánh giá, báo cáo)
  - Quản lý subscription plan và giới hạn tính năng
  - Sử dụng tính năng AI (tùy theo plan)

#### 1.3.3 Quản trị viên (Admin)
- **Chức năng chính:**
  - Quản lý người dùng và phân quyền
  - Duyệt/từ chối khóa học trước khi publish
  - Xử lý yêu cầu hoàn tiền và refund
  - Cấu hình hệ thống và subscription plans
  - Phân tích và báo cáo toàn hệ thống
  - Quản lý nội dung bị báo cáo
  - Thanh toán hàng tháng cho giảng viên
  - Quản lý tính năng AI và giới hạn sử dụng

### 1.4 Định nghĩa và từ viết tắt
- **LMS**: Learning Management System - Hệ thống Quản lý Học tập
- **API**: Application Programming Interface - Giao diện lập trình ứng dụng
- **UI/UX**: User Interface/User Experience - Giao diện người dùng/Trải nghiệm người dùng
- **SRS**: Software Requirements Specification - Đặc tả Yêu cầu Phần mềm
- **JWT**: JSON Web Token - Token xác thực người dùng
- **AI**: Artificial Intelligence - Trí tuệ nhân tạo
- **Subscription**: Gói đăng ký dịch vụ
- **Refund**: Hoàn tiền
- **Upvote/Report**: Đánh giá tích cực/Báo cáo nội dung
- **Embed Video**: Video nhúng trực tiếp
- **Video Tracking**: Theo dõi thời gian xem video

---

## 2. YÊU CẦU CHỨC NĂNG CHI TIẾT

### 2.1 Module Xác thực và Phân quyền

#### 2.1.1 Đăng ký và Đăng nhập
**UR1.1: Đăng ký tài khoản**
- Đăng ký bằng email, mật khẩu và thông tin cá nhân
- Xác thực email trước khi kích hoạt tài khoản
- Đăng nhập bằng Google OAuth
- Mặc định role là Student khi đăng ký
- Mã hóa password bằng bcrypt

**UR1.2: Phân quyền động**
- Một tài khoản có thể có cả 2 role: Student và Teacher
- Khi tạo khóa học đầu tiên, tự động thêm role Teacher
- Admin có quyền truy cập không giới hạn vào tất cả khóa học
- JWT token chứa thông tin role để kiểm soát truy cập

### 2.2 Module Quản lý Khóa học

#### 2.2.1 Cấu trúc Khóa học
**UR2.1: Thông tin cơ bản**
- Tên khóa học, ảnh thumbnail, mô tả
- Domain (IT, Kinh tế, Luật, ...)
- Level (Beginner, Intermediate, Advanced)
- Prerequisites (kiến thức cần có trước khi học)
- Benefits (những gì sẽ học được)
- Links liên quan (source code, nhóm trao đổi)

**UR2.2: Cấu trúc nội dung**
- Khóa học gồm nhiều Section
- Mỗi Section chứa nhiều Lesson
- Cho phép thêm, sửa, xóa Section và Lesson
- Sắp xếp thứ tự Section và Lesson

#### 2.2.2 Loại nội dung bài học
**UR2.3: Video bài giảng**
- Upload video trực tiếp hoặc nhúng link
- Tích hợp YouTube hoặc VideoCipher
- Embed video để xem trực tiếp trên trang
- Tracking thời gian xem video

**UR2.4: Bài giảng text và file**
- Nội dung text với rich text editor
- Upload file tài liệu (PDF, DOC, PPT)
- Link video ngoài (YouTube, Vimeo)

#### 2.2.3 Kiểm duyệt và đánh giá
**UR2.5: Hệ thống kiểm duyệt**
- Khóa học mới cần được Admin duyệt trước khi publish
- Admin có thể reject hoặc approve khóa học
- Thông báo kết quả duyệt cho Teacher

**UR2.6: Hệ thống đánh giá**
- Upvote khóa học (giới hạn 7 ngày giữa các lần)
- Report khóa học (giới hạn 7 ngày)
- Khóa học upvote nhiều ưu tiên hiển thị trên landing page
- Khóa học report nhiều sẽ được Admin xem xét

### 2.3 Module Bài tập và Kiểm tra

#### 2.3.1 Bài tập nộp file
**UR3.1: Tạo bài tập file**
- Teacher upload file đề bài
- Student nộp file lời giải
- Hỗ trợ nhiều định dạng file
- Giới hạn kích thước file upload

#### 2.3.2 Bài tập trắc nghiệm
**UR3.2: Tạo bài trắc nghiệm**
- Form tạo câu hỏi với nhiều đáp án
- Tối thiểu 2 đáp án, chỉ 1 đáp án đúng
- Nút thêm câu hỏi mới
- Nút thêm đáp án cho mỗi câu hỏi
- Không tính thời gian làm bài

**UR3.3: Chấm điểm tự động**
- Tính phần trăm làm đúng
- Hiển thị đáp án đúng và đáp án đã chọn
- Lưu kết quả và thời gian nộp bài

### 2.4 Module Theo dõi Tiến độ Học tập

#### 2.4.1 Tracking video
**UR4.1: Video embed**
- Tự động đánh dấu hoàn thành sau 50% thời lượng
- Tracking thời gian xem thực tế
- Tính cả trường hợp tua video

**UR4.2: Video link ngoài**
- Tracking khi Student click vào link
- Đánh dấu hoàn thành sau 10 phút từ lúc click
- Lưu thời gian click và thời gian hoàn thành

#### 2.4.2 Tracking bài đọc
**UR4.3: Bài giảng text**
- Đánh dấu hoàn thành sau 10 phút xem
- Tracking thời gian đọc thực tế
- Auto-save trạng thái đọc

### 2.5 Module Subscription và Giới hạn

#### 2.5.1 Các gói dịch vụ
**UR5.1: Free Plan**
- Giới hạn: 1 khóa học, 3 sections/khóa, 5 bài trắc nghiệm/khóa
- Không có tính năng AI
- Cơ bản về thống kê

**UR5.2: Pro Plan**
- Giới hạn: 5 khóa học, 10 sections/khóa, 20 bài trắc nghiệm/khóa
- Tính năng AI cơ bản (tạo avatar, thumbnail)
- Thống kê chi tiết

**UR5.3: Advanced Plan**
- Giới hạn: Không giới hạn khóa học, sections, bài trắc nghiệm
- Tất cả tính năng AI (bao gồm duyệt nội dung)
- Thống kê nâng cao và analytics

#### 2.5.2 Quản lý subscription
**UR5.4: Upgrade/Downgrade plan**
- Teacher có thể thay đổi plan
- Tính toán lại giới hạn khi thay đổi plan
- Thông báo khi vượt quá giới hạn

### 2.6 Module Thanh toán và Hoàn tiền

#### 2.6.1 Luồng thanh toán
**UR6.1: Mua khóa học**
- Student thanh toán cho tài khoản Admin
- Tạo bill với thông tin đầy đủ
- Lưu trạng thái giao dịch
- Gửi email xác nhận thanh toán

#### 2.6.2 Hệ thống hoàn tiền
**UR6.2: Yêu cầu hoàn tiền**
- Student có thể yêu cầu refund trong 7 ngày
- Form yêu cầu hoàn tiền với lý do
- Admin xem xét và phê duyệt/từ chối
- Tự động thu hồi quyền truy cập khóa học sau khi refund

**UR6.3: Thanh toán cho Teacher**
- Hệ thống quét bill hàng tháng
- Tính toán thu nhập cho Teacher (sau khi trừ phí nền tảng)
- Tự động chuyển tiền cho Teacher
- Báo cáo tài chính chi tiết

### 2.7 Module Tích hợp AI

#### 2.7.1 Tính năng AI cơ bản
**UR7.1: Tạo avatar**
- Sử dụng OpenAI API
- Tạo avatar dựa trên tên hoặc mô tả
- Chỉ có trong Pro và Advanced plan

**UR7.2: Tạo thumbnail khóa học**
- Tạo ảnh bìa dựa trên tên và mô tả khóa học
- Tích hợp với Cloudinary để lưu trữ
- Chỉ có trong Pro và Advanced plan

#### 2.7.2 AI duyệt nội dung
**UR7.3: Duyệt khóa học tự động**
- Sử dụng OpenAI API để đánh giá nội dung
- Kiểm tra tính phù hợp và chất lượng
- Đưa ra gợi ý approve/reject
- Chỉ có trong Advanced plan

### 2.8 Module Chứng chỉ

#### 2.8.1 Tạo chứng chỉ
**UR8.1: Chứng chỉ tự động**
- Tự động tạo khi Student hoàn thành khóa học
- Form chứng chỉ với thông tin: tên khóa học, tên người học, email
- Template chứng chỉ cố định
- Cho phép download PDF

### 2.9 Module Thông báo

#### 2.9.1 Thông báo real-time
**UR9.1: Socket.io integration**
- Thông báo khi mua khóa học thành công
- Thông báo khi hoàn thành khóa học
- Thông báo cho Teacher khi có bình luận, upvote, report
- Thông báo khi có yêu cầu hoàn tiền

---

## 3. YÊU CẦU PHI CHỨC NĂNG

### 3.1 Hiệu suất
- Hỗ trợ 1000+ người dùng đồng thời
- Thời gian phản hồi API < 2 giây
- Tải trang web < 3 giây trên 4G
- Video streaming mượt mà

### 3.2 Bảo mật
- Mã hóa dữ liệu nhạy cảm (AES-256)
- JWT authentication với refresh token
- Rate limiting cho API
- Bảo vệ chống SQL injection, XSS, CSRF

### 3.3 Khả năng mở rộng
- Kiến trúc microservices
- Database sharding cho tăng trưởng
- CDN cho video và file
- Auto-scaling infrastructure

### 3.4 Khả năng sử dụng
- Giao diện responsive (mobile-first)
- Hỗ trợ đa ngôn ngữ (Việt, Anh)
- Accessibility (WCAG 2.1)
- Intuitive navigation

---

## 4. KIẾN TRÚC HỆ THỐNG

### 4.1 Technology Stack
**Frontend:**
- React 18 + TypeScript
- Material-UI components
- Redux Toolkit cho state management
- Socket.io client cho real-time
- React Query cho data fetching

**Backend:**
- Node.js + Express + TypeScript
- MongoDB + Mongoose
- JWT authentication
- Multer cho file upload
- Socket.io server

**Third-party Services:**
- Cloudinary cho media storage
- Stripe cho payment processing
- OpenAI API cho AI features
- YouTube API cho video embedding
- SendGrid cho email

### 4.2 Database Schema

#### 4.2.1 Users Collection
```javascript
{
  _id: ObjectId,
  email: String (unique),
  password: String (hashed),
  name: String,
  avatar: String,
  roles: [String], // ['student', 'teacher', 'admin']
  subscriptionPlan: String, // 'free', 'pro', 'advanced'
  subscriptionExpiresAt: Date,
  isActive: Boolean,
  emailVerified: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

#### 4.2.2 Courses Collection
```javascript
{
  _id: ObjectId,
  title: String,
  description: String,
  thumbnail: String,
  domain: String, // 'IT', 'Economics', 'Law', ...
  level: String, // 'beginner', 'intermediate', 'advanced'
  prerequisites: [String],
  benefits: [String],
  relatedLinks: [String],
  instructorId: ObjectId (ref: 'Users'),
  price: Number,
  isPublished: Boolean,
  isApproved: Boolean,
  upvotes: Number,
  reports: Number,
  enrolledStudents: [ObjectId],
  createdAt: Date,
  updatedAt: Date
}
```

#### 4.2.3 Sections Collection
```javascript
{
  _id: ObjectId,
  courseId: ObjectId (ref: 'Courses'),
  title: String,
  order: Number,
  createdAt: Date,
  updatedAt: Date
}
```

#### 4.2.4 Lessons Collection
```javascript
{
  _id: ObjectId,
  sectionId: ObjectId (ref: 'Sections'),
  title: String,
  content: String,
  type: String, // 'video', 'text', 'file', 'link'
  videoUrl: String,
  videoDuration: Number,
  fileUrl: String,
  order: Number,
  isRequired: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

#### 4.2.5 Assignments Collection
```javascript
{
  _id: ObjectId,
  lessonId: ObjectId (ref: 'Lessons'),
  title: String,
  description: String,
  type: String, // 'file', 'quiz'
  dueDate: Date,
  maxScore: Number,
  questions: [{
    question: String,
    options: [String],
    correctAnswer: String
  }],
  createdAt: Date,
  updatedAt: Date
}
```

#### 4.2.6 Submissions Collection
```javascript
{
  _id: ObjectId,
  assignmentId: ObjectId (ref: 'Assignments'),
  studentId: ObjectId (ref: 'Users'),
  answers: [String],
  fileUrl: String,
  score: Number,
  submittedAt: Date,
  gradedAt: Date
}
```

#### 4.2.7 Enrollments Collection
```javascript
{
  _id: ObjectId,
  studentId: ObjectId (ref: 'Users'),
  courseId: ObjectId (ref: 'Courses'),
  enrolledAt: Date,
  completedAt: Date,
  progress: Number,
  completedLessons: [ObjectId],
  certificate: String,
  createdAt: Date,
  updatedAt: Date
}
```

#### 4.2.8 Bills Collection
```javascript
{
  _id: ObjectId,
  studentId: ObjectId (ref: 'Users'),
  courseId: ObjectId (ref: 'Courses'),
  amount: Number,
  currency: String,
  paymentMethod: String,
  status: String, // 'pending', 'completed', 'failed', 'refunded'
  transactionId: String,
  purpose: String, // 'course_purchase', 'subscription', 'refund'
  paidAt: Date,
  refundedAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

#### 4.2.9 RefundRequests Collection
```javascript
{
  _id: ObjectId,
  studentId: ObjectId (ref: 'Users'),
  courseId: ObjectId (ref: 'Courses'),
  billId: ObjectId (ref: 'Bills'),
  reason: String,
  status: String, // 'pending', 'approved', 'rejected'
  adminNotes: String,
  requestedAt: Date,
  processedAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

#### 4.2.10 CourseRatings Collection
```javascript
{
  _id: ObjectId,
  courseId: ObjectId (ref: 'Courses'),
  studentId: ObjectId (ref: 'Users'),
  type: String, // 'upvote', 'report'
  reason: String, // for reports
  lastActionAt: Date, // for 7-day limit
  createdAt: Date,
  updatedAt: Date
}
```

---

## 5. LUỒNG NGHIỆP VỤ CHI TIẾT

### 5.1 Luồng tạo khóa học
1. Teacher đăng nhập → Chọn "Tạo khóa học"
2. Điền thông tin cơ bản (tên, mô tả, domain, level)
3. Upload thumbnail (có thể dùng AI tạo)
4. Thêm prerequisites, benefits, related links
5. Tạo sections và lessons
6. Upload nội dung (video, text, file)
7. Tạo bài tập (nếu có)
8. Submit để Admin duyệt
9. Admin review và approve/reject
10. Khóa học được publish (nếu approved)

### 5.2 Luồng mua khóa học
1. Student xem khóa học → Click "Mua khóa học"
2. Chọn phương thức thanh toán
3. Thanh toán cho tài khoản Admin
4. Tạo bill và enrollment
5. Gửi email xác nhận
6. Student có thể truy cập khóa học
7. Bắt đầu tracking tiến độ học tập

### 5.3 Luồng hoàn tiền
1. Student yêu cầu hoàn tiền (trong 7 ngày)
2. Điền form với lý do
3. Admin nhận thông báo
4. Admin xem xét và quyết định
5. Nếu approve → Tạo refund bill
6. Hoàn tiền cho Student
7. Thu hồi quyền truy cập khóa học
8. Gửi email thông báo

### 5.4 Luồng theo dõi tiến độ
1. Student xem bài giảng
2. Hệ thống tracking thời gian
3. Tự động đánh dấu hoàn thành
4. Cập nhật progress trong enrollment
5. Gửi thông báo khi hoàn thành khóa học
6. Tạo chứng chỉ tự động

---

## 6. TÍNH NĂNG AI CHI TIẾT

### 6.1 Tạo Avatar
- Sử dụng OpenAI DALL-E API
- Input: tên người dùng hoặc mô tả
- Output: ảnh avatar phù hợp
- Lưu trữ trên Cloudinary
- Chỉ có trong Pro và Advanced plan

### 6.2 Tạo Thumbnail
- Sử dụng OpenAI DALL-E API
- Input: tên khóa học và mô tả
- Output: ảnh thumbnail hấp dẫn
- Tích hợp với form tạo khóa học
- Chỉ có trong Pro và Advanced plan

### 6.3 Duyệt nội dung
- Sử dụng OpenAI GPT API
- Input: thông tin khóa học (tên, mô tả, nội dung)
- Output: đánh giá chất lượng và gợi ý
- Chỉ có trong Advanced plan
- Hỗ trợ Admin trong quyết định duyệt

---

## 7. KẾ HOẠCH TRIỂN KHAI

### 7.1 Giai đoạn 1 (Tuần 1-4): Core Features
- Authentication và Authorization
- Quản lý khóa học cơ bản
- Upload và xem nội dung
- Bài tập đơn giản

### 7.2 Giai đoạn 2 (Tuần 5-8): Advanced Features
- Hệ thống subscription
- Thanh toán và hoàn tiền
- Tracking tiến độ học tập
- Thông báo real-time

### 7.3 Giai đoạn 3 (Tuần 9-12): AI Integration
- Tích hợp OpenAI API
- Tính năng tạo avatar và thumbnail
- AI duyệt nội dung
- Testing và optimization

### 7.4 Giai đoạn 4 (Tuần 13-16): Polish
- UI/UX improvements
- Performance optimization
- Security testing
- Documentation

**Lưu ý**: Timeline này được điều chỉnh cho team 1 người trong 2-3 tháng, các giai đoạn có thể được thực hiện song song hoặc rút gọn tùy theo khả năng và ưu tiên.

---

## 8. KẾT LUẬN

Tài liệu SRS này đã được cập nhật để đáp ứng đầy đủ các yêu cầu đặc biệt của khách hàng, bao gồm:

1. **Hệ thống subscription** với 3 gói dịch vụ và giới hạn tính năng
2. **Tích hợp AI** cho tạo avatar, thumbnail và duyệt nội dung
3. **Theo dõi tiến độ học tập** tự động cho video, link và bài đọc
4. **Hệ thống hoàn tiền** với chính sách 7 ngày
5. **Luồng thanh toán** qua Admin với thanh toán hàng tháng cho Teacher
6. **Hệ thống đánh giá** với upvote/report và giới hạn thời gian
7. **Kiểm duyệt nội dung** trước khi publish
8. **Chứng chỉ tự động** khi hoàn thành khóa học

Tất cả các yêu cầu này đã được tích hợp vào kiến trúc hệ thống và database schema để đảm bảo tính khả thi và hiệu quả trong quá trình phát triển. 
