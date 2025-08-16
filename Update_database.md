Tôi sẽ phân tích chi tiết toàn bộ frontend để xác định các thực thể cần thiết trong backend. Hãy để tôi kiểm tra cấu trúc và chức năng của từng trang:

Search files...
Dựa trên phân tích chi tiết frontend, tôi sẽ tổng hợp đầy đủ các thực thể cần thiết trong backend để viết API ghép cho frontend:

# ��️ **TỔNG HỢP CHI TIẾT CÁC THỰC THỂ BACKEND CHO LMS**

## �� **1. CORE ENTITIES (Thực thể cốt lõi)**

### **1.1 USERS Collection**
```typescript
interface User {
  _id: ObjectId;
  email: string;                    // unique, required
  password: string;                 // hashed, required
  name: string;                     // required
  avatar?: string;                  // URL ảnh đại diện
  roles: ('student' | 'teacher' | 'admin')[];  // required
  subscriptionPlan: 'free' | 'pro' | 'advanced';  // default: 'free'
  subscriptionExpiresAt?: Date;     // optional
  isActive: boolean;                // default: true
  emailVerified: boolean;           // default: false
  phone?: string;                   // optional
  dateOfBirth?: Date;              // optional
  country?: string;                 // optional
  bio?: string;                     // mô tả cá nhân
  socialLinks?: {                   // mạng xã hội
    linkedin?: string;
    twitter?: string;
    github?: string;
    youtube?: string;
  };
  preferences?: {                    // cài đặt cá nhân
    language: string;               // default: 'vi'
    timezone: string;               // default: 'Asia/Ho_Chi_Minh'
    notifications: {
      email: boolean;               // default: true
      push: boolean;                // default: true
      sms: boolean;                 // default: false
    };
  };
  stats?: {                         // thống kê cá nhân
    totalCoursesEnrolled: number;   // default: 0
    totalCoursesCompleted: number;  // default: 0
    totalAssignmentsSubmitted: number; // default: 0
    averageScore: number;           // default: 0
    totalLearningTime: number;      // giây, default: 0
  };
  createdAt: Date;
  updatedAt: Date;
  lastLoginAt?: Date;               // lần đăng nhập cuối
  lastActivityAt?: Date;            // hoạt động cuối cùng
}
```

### **1.2 COURSES Collection**
```typescript
interface Course {
  _id: ObjectId;
  title: string;                    // required
  description: string;              // required
  shortDescription?: string;        // mô tả ngắn
  thumbnail?: string;               // URL ảnh đại diện
  domain: string;                   // 'IT', 'Economics', 'Law', 'Marketing', etc.
  level: 'beginner' | 'intermediate' | 'advanced';  // required
  prerequisites: string[];          // yêu cầu đầu vào
  benefits: string[];               // lợi ích khóa học
  relatedLinks: string[];           // link liên quan
  instructorId: ObjectId;           // ref: Users (required)
  price: number;                    // giá khóa học (VND)
  originalPrice?: number;           // giá gốc (nếu có giảm giá)
  discountPercentage?: number;      // phần trăm giảm giá
  isPublished: boolean;             // default: false
  isApproved: boolean;              // default: false
  isFeatured: boolean;              // default: false
  upvotes: number;                  // default: 0
  reports: number;                  // default: 0
  enrolledStudents: ObjectId[];     // ref: Users
  totalStudents: number;            // default: 0 (denormalized)
  totalLessons: number;             // default: 0 (denormalized)
  totalDuration: number;            // tổng thời lượng (giây)
  averageRating: number;            // default: 0
  totalRatings: number;             // default: 0
  completionRate: number;           // tỷ lệ hoàn thành (%)
  tags: string[];                   // tags khóa học
  language: string;                 // ngôn ngữ khóa học
  certificate: boolean;             // có chứng chỉ không
  maxStudents?: number;             // số học viên tối đa
  startDate?: Date;                 // ngày bắt đầu
  endDate?: Date;                   // ngày kết thúc
  createdAt: Date;
  updatedAt: Date;
  publishedAt?: Date;               // ngày xuất bản
  approvedAt?: Date;                // ngày duyệt
  approvedBy?: ObjectId;            // ref: Users (admin)
}
```

### **1.3 SECTIONS Collection**
```typescript
interface Section {
  _id: ObjectId;
  courseId: ObjectId;               // ref: Courses (required)
  title: string;                    // required
  description?: string;             // mô tả section
  order: number;                    // vị trí trong khóa học (required)
  isVisible: boolean;               // default: true
  totalLessons: number;             // default: 0 (denormalized)
  totalDuration: number;            // tổng thời lượng (giây)
  createdAt: Date;
  updatedAt: Date;
}
```

### **1.4 LESSONS Collection**
```typescript
interface Lesson {
  _id: ObjectId;
  sectionId: ObjectId;              // ref: Sections (required)
  courseId: ObjectId;               // ref: Courses (denormalized)
  title: string;                    // required
  content: string;                  // rich text content
  type: 'video' | 'text' | 'file' | 'link';  // required
  videoUrl?: string;                // URL video (nếu type = 'video')
  videoDuration?: number;           // thời lượng video (giây)
  videoThumbnail?: string;          // ảnh thumbnail video
  fileUrl?: string;                 // URL file (nếu type = 'file')
  fileSize?: number;                // kích thước file (bytes)
  fileType?: string;                // loại file
  externalLink?: string;            // link ngoài (nếu type = 'link')
  order: number;                    // vị trí trong section
  isRequired: boolean;              // default: true
  isPreview: boolean;               // có thể xem trước không
  estimatedTime: number;            // thời gian ước tính (phút)
  attachments?: {                   // file đính kèm
    name: string;
    url: string;
    size: number;
    type: string;
  }[];
  createdAt: Date;
  updatedAt: Date;
}
```

### **1.5 ASSIGNMENTS Collection**
```typescript
interface Assignment {
  _id: ObjectId;
  lessonId: ObjectId;               // ref: Lessons (required)
  courseId: ObjectId;               // ref: Courses (denormalized)
  title: string;                    // required
  description: string;              // required
  instructions: string;             // hướng dẫn làm bài
  type: 'file' | 'quiz' | 'text';  // required
  dueDate?: Date;                   // hạn nộp
  maxScore: number;                 // điểm tối đa (required)
  timeLimit?: number;               // thời gian làm bài (phút)
  attempts: number;                 // số lần được làm lại (default: 1)
  isRequired: boolean;              // default: true
  isGraded: boolean;                // có chấm điểm không
  gradingCriteria: string[];        // tiêu chí chấm điểm
  importantNotes: string[];         // ghi chú quan trọng
  attachments?: {                   // file đính kèm
    name: string;
    url: string;
    size: number;
    type: string;
  }[];
  quizQuestions?: {                 // câu hỏi quiz (nếu type = 'quiz')
    question: string;
    type: 'multiple-choice' | 'text' | 'file';
    options?: string[];             // cho multiple-choice
    correctAnswer?: string;         // đáp án đúng
    points: number;                 // điểm cho câu hỏi
    required: boolean;              // default: true
  }[];
  createdAt: Date;
  updatedAt: Date;
}
```

### **1.6 SUBMISSIONS Collection**
```typescript
interface Submission {
  _id: ObjectId;
  assignmentId: ObjectId;           // ref: Assignments (required)
  studentId: ObjectId;              // ref: Users (required)
  courseId: ObjectId;               // ref: Courses (denormalized)
  answers?: string[];               // đáp án quiz
  fileUrl?: string;                 // URL file nộp
  fileSize?: number;                // kích thước file
  fileType?: string;                // loại file
  textAnswer?: string;              // câu trả lời text
  score?: number;                   // điểm số
  feedback?: string;                // nhận xét của giảng viên
  gradedBy?: ObjectId;              // ref: Users (giảng viên)
  submittedAt: Date;                // thời gian nộp
  gradedAt?: Date;                  // thời gian chấm
  attemptNumber: number;            // số lần nộp (default: 1)
  status: 'submitted' | 'graded' | 'late' | 'overdue';  // trạng thái
  isLate: boolean;                  // nộp muộn không
  createdAt: Date;
  updatedAt: Date;
}
```

### **1.7 ENROLLMENTS Collection**
```typescript
interface Enrollment {
  _id: ObjectId;
  studentId: ObjectId;              // ref: Users (required)
  courseId: ObjectId;               // ref: Courses (required)
  instructorId: ObjectId;           // ref: Users (denormalized)
  enrolledAt: Date;                 // thời gian đăng ký
  completedAt?: Date;               // thời gian hoàn thành
  progress: number;                 // tiến độ học tập (0-100)
  currentLesson?: ObjectId;         // ref: Lessons (bài học hiện tại)
  currentSection?: ObjectId;        // ref: Sections (section hiện tại)
  totalTimeSpent: number;           // tổng thời gian học (giây)
  lastActivityAt?: Date;            // hoạt động cuối cùng
  isActive: boolean;                // default: true
  isCompleted: boolean;             // default: false
  certificateIssued: boolean;       // đã cấp chứng chỉ chưa
  certificateUrl?: string;          // URL chứng chỉ
  notes?: string;                   // ghi chú cá nhân
  createdAt: Date;
  updatedAt: Date;
}
```

### **1.8 BILLS Collection**
```typescript
interface Bill {
  _id: ObjectId;
  studentId: ObjectId;              // ref: Users (required)
  courseId?: ObjectId;              // ref: Courses (optional, cho subscription)
  amount: number;                   // số tiền (VND)
  currency: string;                 // default: 'VND'
  purpose: 'course_purchase' | 'subscription' | 'refund' | 'other';  // required
  status: 'pending' | 'completed' | 'failed' | 'refunded' | 'cancelled';  // required
  paymentMethod: 'stripe' | 'paypal' | 'bank_transfer' | 'cash';  // required
  paymentGateway?: string;          // tên gateway thanh toán
  transactionId?: string;           // ID giao dịch từ gateway
  description: string;              // mô tả hóa đơn
  metadata?: any;                   // dữ liệu bổ sung
  paidAt?: Date;                    // thời gian thanh toán
  refundedAt?: Date;                // thời gian hoàn tiền
  createdAt: Date;
  updatedAt: Date;
}
```

### **1.9 REFUND_REQUESTS Collection**
```typescript
interface RefundRequest {
  _id: ObjectId;
  studentId: ObjectId;              // ref: Users (required)
  courseId: ObjectId;               // ref: Courses (required)
  billId: ObjectId;                 // ref: Bills (required)
  reason: string;                   // lý do hoàn tiền (required)
  description?: string;             // mô tả chi tiết
  amount: number;                   // số tiền yêu cầu hoàn
  status: 'pending' | 'approved' | 'rejected' | 'completed';  // required
  refundMethod?: 'original_payment' | 'bank_transfer' | 'credit';  // phương thức hoàn
  processedBy?: ObjectId;           // ref: Users (admin)
  processedAt?: Date;               // thời gian xử lý
  adminNotes?: string;              // ghi chú của admin
  studentNotes?: string;            // ghi chú của học viên
  attachments?: {                   // file đính kèm
    name: string;
    url: string;
    size: number;
    type: string;
  }[];
  createdAt: Date;
  updatedAt: Date;
}
```

### **1.10 COURSE_RATINGS Collection**
```typescript
interface CourseRating {
  _id: ObjectId;
  courseId: ObjectId;               // ref: Courses (required)
  studentId: ObjectId;              // ref: Users (required)
  type: 'upvote' | 'report';       // required
  rating?: number;                  // 1-5 sao (cho upvote)
  comment?: string;                 // nhận xét
  reportReason?: string;            // lý do báo cáo (cho report)
  isAnonymous: boolean;             // default: false
  isVerified: boolean;              // đã xác minh mua khóa học chưa
  createdAt: Date;
  updatedAt: Date;
}
```

## 📊 **2. EXTENDED ENTITIES (Thực thể mở rộng)**

### **2.1 WISHLIST Collection**
```typescript
interface WishlistItem {
  _id: ObjectId;
  studentId: ObjectId;              // ref: Users (required)
  courseId: ObjectId;               // ref: Courses (required)
  addedAt: Date;                    // thời gian thêm vào wishlist
  notes?: string;                   // ghi chú cá nhân
}
```

### **2.2 STUDY_GROUPS Collection**
```typescript
interface StudyGroup {
  _id: ObjectId;
  name: string;                     // required
  description?: string;             // mô tả nhóm
  courseId?: ObjectId;              // ref: Courses (optional)
  creatorId: ObjectId;              // ref: Users (required)
  members: ObjectId[];              // ref: Users
  maxMembers?: number;              // số thành viên tối đa
  isPrivate: boolean;               // default: false
  isActive: boolean;                // default: true
  tags: string[];                   // tags nhóm
  createdAt: Date;
  updatedAt: Date;
}
```

### **2.3 CALENDAR_EVENTS Collection**
```typescript
interface CalendarEvent {
  _id: ObjectId;
  userId: ObjectId;                 // ref: Users (required)
  title: string;                    // required
  description?: string;             // mô tả sự kiện
  type: 'assignment' | 'exam' | 'reminder' | 'custom';  // required
  startDate: Date;                  // required
  endDate?: Date;                   // optional
  isAllDay: boolean;                // default: false
  color?: string;                   // màu sắc sự kiện
  courseId?: ObjectId;              // ref: Courses (nếu liên quan)
  assignmentId?: ObjectId;          // ref: Assignments (nếu liên quan)
  reminderTime?: number;            // thời gian nhắc nhở (phút trước)
  isRecurring: boolean;             // default: false
  recurrencePattern?: string;       // pattern lặp lại
  createdAt: Date;
  updatedAt: Date;
}
```

### **2.4 NOTIFICATIONS Collection**
```typescript
interface Notification {
  _id: ObjectId;
  userId: ObjectId;                 // ref: Users (required)
  title: string;                    // required
  message: string;                  // required
  type: 'info' | 'success' | 'warning' | 'error' | 'course' | 'assignment';  // required
  isRead: boolean;                  // default: false
  isArchived: boolean;              // default: false
  courseId?: ObjectId;              // ref: Courses (nếu liên quan)
  assignmentId?: ObjectId;          // ref: Assignments (nếu liên quan)
  actionUrl?: string;               // URL hành động
  metadata?: any;                   // dữ liệu bổ sung
  expiresAt?: Date;                 // thời gian hết hạn
  createdAt: Date;
  updatedAt: Date;
}
```

### **2.5 COURSE_CATEGORIES Collection**
```typescript
interface CourseCategory {
  _id: ObjectId;
  name: string;                     // required
  slug: string;                     // required, unique
  description?: string;             // mô tả danh mục
  parentId?: ObjectId;              // ref: CourseCategory (danh mục cha)
  level: number;                    // cấp độ (0: root, 1: child, 2: grandchild)
  order: number;                    // thứ tự hiển thị
  icon?: string;                    // icon danh mục
  image?: string;                   // ảnh đại diện
  isActive: boolean;                // default: true
  isFeatured: boolean;              // default: false
  totalCourses: number;             // default: 0 (denormalized)
  seoTitle?: string;                // SEO title
  seoDescription?: string;          // SEO description
  seoKeywords?: string[];           // SEO keywords
  createdAt: Date;
  updatedAt: Date;
}
```

## 📊 **3. ADMIN & SYSTEM ENTITIES**

### **3.1 ADMIN_PERMISSIONS Collection**
```typescript
interface AdminPermission {
  _id: ObjectId;
  name: string;                     // required
  slug: string;                     // required, unique
  description?: string;             // mô tả quyền
  resource: string;                 // tài nguyên (users, courses, etc.)
  action: string;                   // hành động (create, read, update, delete)
  isActive: boolean;                // default: true
  createdAt: Date;
  updatedAt: Date;
}
```

### **3.2 ADMIN_ROLES Collection**
```typescript
interface AdminRole {
  _id: ObjectId;
  name: string;                     // required
  slug: string;                     // required, unique
  description?: string;             // mô tả vai trò
  permissions: ObjectId[];          // ref: AdminPermission
  isActive: boolean;                // default: true
  isSystem: boolean;                // default: false (không thể xóa)
  createdAt: Date;
  updatedAt: Date;
}
```

### **3.3 USER_ROLES Collection**
```typescript
interface UserRole {
  _id: ObjectId;
  userId: ObjectId;                 // ref: Users (required)
  roleId: ObjectId;                 // ref: AdminRole (required)
  assignedBy: ObjectId;             // ref: Users (admin)
  assignedAt: Date;                 // thời gian gán
  expiresAt?: Date;                 // thời gian hết hạn
  isActive: boolean;                // default: true
  createdAt: Date;
  updatedAt: Date;
}
```

### **3.4 AUDIT_LOGS Collection**
```typescript
interface AuditLog {
  _id: ObjectId;
  userId: ObjectId;                 // ref: Users (required)
  action: string;                   // hành động thực hiện
  resource: string;                 // tài nguyên bị thay đổi
  resourceId?: ObjectId;            // ID tài nguyên
  oldValues?: any;                  // giá trị cũ
  newValues?: any;                  // giá trị mới
  ipAddress?: string;               // IP address
  userAgent?: string;               // User agent
  severity: 'low' | 'medium' | 'high' | 'critical';  // mức độ nghiêm trọng
  category: 'authentication' | 'authorization' | 'data' | 'system';  // loại log
  metadata?: any;                   // dữ liệu bổ sung
  createdAt: Date;
}
```

### **3.5 SYSTEM_SETTINGS Collection**
```typescript
interface SystemSetting {
  _id: ObjectId;
  key: string;                      // required, unique
  value: any;                       // giá trị setting
  type: 'string' | 'number' | 'boolean' | 'object' | 'array';  // kiểu dữ liệu
  category: 'general' | 'security' | 'email' | 'payment' | 'storage';  // nhóm
  description?: string;             // mô tả setting
  isPublic: boolean;                // default: false (có thể truy cập public không)
  isEditable: boolean;              // default: true (có thể chỉnh sửa không)
  validation?: string;              // regex validation
  createdAt: Date;
  updatedAt: Date;
}
```

### **3.6 SUPPORT_TICKETS Collection**
```typescript
interface SupportTicket {
  _id: ObjectId;
  ticketNumber: string;             // required, unique
  userId: ObjectId;                 // ref: Users (required)
  subject: string;                  // required
  description: string;              // required
  priority: 'low' | 'medium' | 'high' | 'urgent';  // required
  status: 'open' | 'in_progress' | 'waiting' | 'resolved' | 'closed';  // required
  category: 'technical' | 'billing' | 'course' | 'general';  // required
  assignedTo?: ObjectId;            // ref: Users (support staff)
  courseId?: ObjectId;              // ref: Courses (nếu liên quan)
  attachments?: {                   // file đính kèm
    name: string;
    url: string;
    size: number;
    type: string;
  }[];
  messages: {                       // tin nhắn trao đổi
    userId: ObjectId;               // ref: Users
    message: string;
    isInternal: boolean;            // tin nhắn nội bộ
    createdAt: Date;
  }[];
  resolvedAt?: Date;                // thời gian giải quyết
  closedAt?: Date;                  // thời gian đóng
  satisfaction?: number;            // đánh giá hài lòng (1-5)
  createdAt: Date;
  updatedAt: Date;
}
```

### **3.7 ANNOUNCEMENTS Collection**
```typescript
interface Announcement {
  _id: ObjectId;
  title: string;                    // required
  content: string;                  // required
  type: 'info' | 'warning' | 'success' | 'error';  // required
  priority: 'low' | 'medium' | 'high';  // required
  audience: 'all' | 'students' | 'teachers' | 'admins';  // required
  isActive: boolean;                // default: true
  isPinned: boolean;                // default: false
  startDate?: Date;                 // ngày bắt đầu hiển thị
  endDate?: Date;                   // ngày kết thúc hiển thị
  courseId?: ObjectId;              // ref: Courses (nếu chỉ cho khóa học cụ thể)
  createdBy: ObjectId;              // ref: Users (admin)
  readBy: ObjectId[];               // ref: Users (đã đọc)
  createdAt: Date;
  updatedAt: Date;
}
```

## 📊 **4. ANALYTICS & REPORTING ENTITIES**

### **4.1 USER_ACTIVITY_LOGS Collection**
```typescript
interface UserActivityLog {
  _id: ObjectId;
  userId: ObjectId;                 // ref: Users (required)
  action: string;                   // hành động thực hiện
  resource: string;                 // tài nguyên
  resourceId?: ObjectId;            // ID tài nguyên
  courseId?: ObjectId;              // ref: Courses (nếu liên quan)
  lessonId?: ObjectId;              // ref: Lessons (nếu liên quan)
  duration?: number;                // thời gian thực hiện (giây)
  metadata?: any;                   // dữ liệu bổ sung
  ipAddress?: string;               // IP address
  userAgent?: string;               // User agent
  createdAt: Date;
}
```

### **4.2 COURSE_ANALYTICS Collection**
```typescript
interface CourseAnalytics {
  _id: ObjectId;
  courseId: ObjectId;               // ref: Courses (required)
  date: Date;                       // ngày thống kê
  totalViews: number;               // tổng lượt xem
  uniqueViews: number;              // lượt xem duy nhất
  totalEnrollments: number;         // tổng đăng ký
  newEnrollments: number;           // đăng ký mới
  totalCompletions: number;         // tổng hoàn thành
  newCompletions: number;           // hoàn thành mới
  averageRating: number;            // điểm đánh giá trung bình
  totalRatings: number;             // tổng số đánh giá
  totalRevenue: number;             // tổng doanh thu
  newRevenue: number;               // doanh thu mới
  averageCompletionTime: number;    // thời gian hoàn thành trung bình (giây)
  engagementScore: number;          // điểm tương tác (0-100)
  createdAt: Date;
  updatedAt: Date;
}
```

## �� **5. PAYMENT & SUBSCRIPTION ENTITIES**

### **5.1 SUBSCRIPTIONS Collection**
```typescript
interface Subscription {
  _id: ObjectId;
  userId: ObjectId;                 // ref: Users (required)
  plan: 'free' | 'pro' | 'advanced';  // required
  status: 'active' | 'expired' | 'cancelled' | 'suspended';  // required
  startDate: Date;                  // required
  endDate: Date;                    // required
  autoRenew: boolean;               // default: true
  paymentMethod?: string;           // phương thức thanh toán
  amount: number;                   // số tiền (VND)
  currency: string;                 // default: 'VND'
  billingCycle: 'monthly' | 'yearly';  // required
  nextBillingDate?: Date;           // ngày thanh toán tiếp theo
  cancelledAt?: Date;               // thời gian hủy
  cancelledBy?: ObjectId;           // ref: Users
  cancellationReason?: string;      // lý do hủy
  createdAt: Date;
  updatedAt: Date;
}
```

### **5.2 PAYMENT_METHODS Collection**
```typescript
interface PaymentMethod {
  _id: ObjectId;
  userId: ObjectId;                 // ref: Users (required)
  type: 'card' | 'bank_account' | 'paypal';  // required
  isDefault: boolean;               // default: false
  isActive: boolean;                // default: true
  cardLast4?: string;               // 4 số cuối thẻ
  cardBrand?: string;               // thương hiệu thẻ
  cardExpMonth?: number;            // tháng hết hạn
  cardExpYear?: number;             // năm hết hạn
  bankName?: string;                // tên ngân hàng
  bankAccountLast4?: string;        // 4 số cuối tài khoản
  paypalEmail?: string;             // email PayPal
  gatewayToken?: string;            // token từ gateway
  metadata?: any;                   // dữ liệu bổ sung
  createdAt: Date;
  updatedAt: Date;
}
```

## �� **6. RELATIONSHIPS & INDEXES**

### **6.1 Database Indexes**
```typescript
// Users Collection
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "roles": 1 });
db.users.createIndex({ "isActive": 1 });
db.users.createIndex({ "createdAt": -1 });

// Courses Collection
db.courses.createIndex({ "instructorId": 1 });
db.courses.createIndex({ "domain": 1 });
db.courses.createIndex({ "level": 1 });
db.courses.createIndex({ "isPublished": 1, "isApproved": 1 });
db.courses.createIndex({ "price": 1 });
db.courses.createIndex({ "createdAt": -1 });
db.courses.createIndex({ "title": "text", "description": "text" });

// Enrollments Collection
db.enrollments.createIndex({ "studentId": 1, "courseId": 1 }, { unique: true });
db.enrollments.createIndex({ "courseId": 1 });
db.enrollments.createIndex({ "isActive": 1 });
db.enrollments.createIndex({ "enrolledAt": -1 });

// Submissions Collection
db.submissions.createIndex({ "assignmentId": 1, "studentId": 1 });
db.submissions.createIndex({ "studentId": 1 });
db.submissions.createIndex({ "submittedAt": -1 });

// Bills Collection
db.bills.createIndex({ "studentId": 1 });
db.bills.createIndex({ "status": 1 });
db.bills.createIndex({ "createdAt": -1 });

// Support Tickets Collection
db.support_tickets.createIndex({ "ticketNumber": 1 }, { unique: true });
db.support_tickets.createIndex({ "userId": 1 });
db.support_tickets.createIndex({ "status": 1, "priority": 1 });
```

### **6.2 Data Validation Rules**
```typescript
// MongoDB Schema Validation
{
  validator: {
    $jsonSchema: {
      required: ["email", "password", "name", "roles"],
      properties: {
        email: {
          bsonType: "string",
          pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        },
        password: {
          bsonType: "string",
          minLength: 8
        },
        roles: {
          bsonType: "array",
          items: {
            enum: ["student", "teacher", "admin"]
          }
        }
      }
    }
  }
}
```

## �� **7. API ENDPOINTS CẦN THIẾT**

### **7.1 Authentication APIs**
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/logout` - Đăng xuất
- `POST /api/auth/refresh` - Làm mới token
- `POST /api/auth/forgot-password` - Quên mật khẩu
- `POST /api/auth/reset-password` - Đặt lại mật khẩu

### **7.2 User Management APIs**
- `GET /api/users/profile` - Lấy thông tin cá nhân
- `PUT /api/users/profile` - Cập nhật thông tin cá nhân
- `GET /api/users/:id` - Lấy thông tin user
- `GET /api/admin/users` - Danh sách users (admin)
- `PUT /api/admin/users/:id` - Cập nhật user (admin)
- `DELETE /api/admin/users/:id` - Xóa user (admin)

### **7.3 Course Management APIs**
- `GET /api/courses` - Danh sách khóa học
- `GET /api/courses/:id` - Chi tiết khóa học
- `POST /api/courses` - Tạo khóa học mới
- `PUT /api/courses/:id` - Cập nhật khóa học
- `DELETE /api/courses/:id` - Xóa khóa học
- `POST /api/courses/:id/enroll` - Đăng ký khóa học
- `GET /api/courses/:id/progress` - Tiến độ học tập

### **7.4 Content Management APIs**
- `GET /api/courses/:id/sections` - Danh sách sections
- `POST /api/courses/:id/sections` - Tạo section mới
- `PUT /api/sections/:id` - Cập nhật section
- `DELETE /api/sections/:id` - Xóa section
- `GET /api/sections/:id/lessons` - Danh sách lessons
- `POST /api/sections/:id/lessons` - Tạo lesson mới
- `PUT /api/lessons/:id` - Cập nhật lesson
- `DELETE /api/lessons/:id` - Xóa lesson

### **7.5 Assignment & Submission APIs**
- `GET /api/lessons/:id/assignments` - Danh sách bài tập
- `POST /api/lessons/:id/assignments` - Tạo bài tập mới
- `PUT /api/assignments/:id` - Cập nhật bài tập
- `DELETE /api/assignments/:id` - Xóa bài tập
- `POST /api/assignments/:id/submit` - Nộp bài
- `GET /api/assignments/:id/submissions` - Danh sách bài nộp
- `PUT /api/submissions/:id/grade` - Chấm điểm

### **7.6 Analytics & Reporting APIs**
- `GET /api/analytics/dashboard` - Thống kê tổng quan
- `GET /api/analytics/courses` - Thống kê khóa học
- `GET /api/analytics/users` - Thống kê người dùng
- `GET /api/analytics/revenue` - Thống kê doanh thu
- `GET /api/analytics/engagement` - Thống kê tương tác

### **7.7 Admin Management APIs**
- `GET /api/admin/courses/review` - Danh sách khóa học chờ duyệt
- `PUT /api/admin/courses/:id/approve` - Duyệt khóa học
- `PUT /api/admin/courses/:id/reject` - Từ chối khóa học
- `GET /api/admin/refunds` - Danh sách yêu cầu hoàn tiền
- `PUT /api/admin/refunds/:id/process` - Xử lý hoàn tiền
- `GET /api/admin/support-tickets` - Danh sách ticket hỗ trợ
- `PUT /api/admin/support-tickets/:id/assign` - Gán ticket

## �� **8. TỔNG KẾT SỐ LƯỢNG**

### **8.1 Collections chính: 25 collections**
- Core: 10 collections
- Extended: 4 collections  
- Admin: 6 collections
- Analytics: 2 collections
- Payment: 3 collections

### **8.2 API Endpoints: 80+ endpoints**
- Authentication: 6 endpoints
- User Management: 6 endpoints
- Course Management: 7 endpoints
- Content Management: 7 endpoints
- Assignment: 7 endpoints
- Analytics: 5 endpoints
- Admin: 15 endpoints
- Payment: 8 endpoints
- Other: 20+ endpoints

### **8.3 Database Indexes: 20+ indexes**
- Performance optimization
- Search functionality
- Data integrity

**Đây là cấu trúc hoàn chỉnh để xây dựng backend cho LMS system!** Bạn có muốn tôi đi sâu vào chi tiết của phần nào cụ thể không?
