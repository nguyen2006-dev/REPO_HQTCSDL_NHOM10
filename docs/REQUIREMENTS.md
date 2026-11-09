# Đối chiếu yêu cầu và phạm vi nghiệm thu

“Có mã” không đồng nghĩa đã chạy end-to-end. Xem VALIDATION.md để biết bằng chứng. Không đánh dấu toàn bộ hệ thống đạt nghiệm thu trước khi kiểm thử SQL Server và cấu hình dịch vụ thực tế.

| Yêu cầu gốc | Thành phần đáp ứng | Trạng thái triển khai |
|---|---|---|
| Quản lý người dùng/quyền | Admin, JWT RBAC, TokenVersion | Có mã và build |
| Cấu hình hệ thống | PlatformSettings: Banner/RequireNegative; secrets cho hạ tầng | Có mã và build |
| Master data | FilmStocks, Admin catalog | Có mã và build |
| Giám sát | AuditLog, trigger và Admin view | Có mã và build; chưa có monitoring cloud |
| Tạo/cấu hình cuộc thi | Organizer, procedure, hạng mục/thể lệ | Có mã và build |
| Thời gian nhận bài và chấm | Opens/Closes/JudgingStart/End UTC | Có mã và build |
| Mẫu tái sử dụng | Clone contest → Draft mới, copy hạng mục/tiêu chí/giải | Có mã và build |
| Đăng ký người dự thi | Registrations | Có mã và build |
| Film roll/frame metadata | FilmRolls/Frames/Submissions | Có mã và build |
| Upload ảnh và tracking | Assets, Studio, Feedback | Kiểm thử lưu/đọc ảnh local đã đạt |
| Kiểm tra hạn, file, metadata | Form validation, Assets, usp_Submit | File checks đạt; SQL nghiệp vụ cần SQL Server |
| Duyệt bài và lịch sử | SubmissionReviews/audit | Có mã và build |
| Trùng chính xác | SHA-256 UNIQUE trong contest | Có mã; SQL constraint cần kiểm thử thực thi |
| Ảnh gần giống | dHash-64, latest 2.000 images | Có mã; chưa đánh giá recall/precision |
| Nhận diện ảnh AI | AIService + Python classifier adapter | Cần detector/model/HTTPS endpoint; chưa chạy mô hình |
| Từ khóa/phân loại | CLIP adapter, AICheckResults Tags | Cần tải mô hình; gợi ý, không thay hạng mục tác giả |
| Phân công giám khảo | Round/submission/judge | Có mã và build |
| Chấm theo tiêu chí, nhận xét | Scores + weighted criteria | Có mã; kiểm thử SQL thực thi còn chờ |
| Nhiều vòng và xác nhận | JudgingRounds + Finalized | Có mã; mọi bài Approved vào mỗi vòng |
| Tổng hợp/xếp hạng | v_RoundScores/v_Rankings | Có mã; giữ đồng điểm, dùng vòng cuối |
| Trao giải/công bố | Awards/SubmissionAwards/usp_Publish | Có mã và build |
| Kho số/triển lãm | v_Archive, private Assets gateway | Có mã và build |
| Thống kê và analytics | Report, CSV | SQL thống kê; chưa có LLM analytics |
| Hồ sơ và lịch sử | Account/Profile, Studio | Có mã và build |
| JWT + RBAC | JwtBearer, authorize, ownership, version | JWT checks và redirect thiếu đăng nhập đã đạt |
| Cloud storage | Azure Blob adapter | Chưa cấp tài khoản/container hoặc kiểm thử cloud |
| Modular/scalability | Controllers/Services/Models/Views; SQL indexes/transactions | Có cấu trúc; chưa benchmark tải |
| Nhiều cuộc thi/chấm đồng thời | Mô hình dữ liệu theo ContestId/AssignmentId | Có mã; chưa load test |
| Web portal và participant app | Website responsive chung theo hướng 2 | Có mã web; không có APK/Flutter |
| Deployment | Dockerfile/compose, Azure hướng dẫn | Có cấu hình; chưa triển khai cloud |
| Tài liệu/báo cáo | docs, ERD, test scripts, demo | Có tài liệu, cần bổ sung ảnh minh chứng và thông tin nhóm |

Những thay đổi so với gợi ý công nghệ đề gốc: SQL Server/T-SQL thay MySQL/PostgreSQL theo yêu cầu môn; MVC thay React/API tách rời theo hướng 2 đã chọn. Trình duyệt điện thoại dùng responsive web. Nếu giảng viên bắt buộc ứng dụng mobile native riêng hoặc tất cả ứng dụng AI hoạt động thực, cần bổ sung và kiểm thử trước khi chốt hoàn thành.
