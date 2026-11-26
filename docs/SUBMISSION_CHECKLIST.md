# Những thành phần cần có khi nộp đề tài

Đối chiếu với tài liệu trong repo; cần đối chiếu thêm đề gốc/rubric giảng viên.

| Hạng mục | Tình trạng và việc cần làm |
|---|---|
| Mã nguồn và hướng dẫn chạy | Có mã, bổ sung setup-local.ps1, update database và FIXES_AND_RUN_VI.md |
| Phân tích yêu cầu, vai trò, quy tắc | Có PROJECT_REPORT.md và REQUIREMENTS.md; bổ sung thông tin nhóm/lớp/giảng viên thực tế |
| Thiết kế dữ liệu | Có 18 bảng, ERD theo nhóm, khóa/FK/UNIQUE/CHECK; nên xuất ERD rõ nét và từ điển dữ liệu đầy đủ khi rubric yêu cầu |
| Lập trình T-SQL | Có procedure, transaction, trigger audit và view điểm/xếp hạng; giải thích bằng ví dụ đầu vào/kết quả khi bảo vệ |
| Phân quyền | Có JWT/RBAC, ownership và film_runtime; cần kiểm tra bằng 4 tài khoản thật |
| Kiểm thử | Bổ sung regression model/controller, HTTP và 5 ca SQL; ghi Actual/Expected/Pass/Fail sau khi chạy trên SQL Server |
| Đồng thời và hiệu năng | Chưa có số liệu tải; cần thử hai lần nộp đồng thời khi còn một suất, đo thời gian query và execution plan |
| Sao lưu/phục hồi | Có mẫu SQL; cần chạy BACKUP, VERIFY và RESTORE sang database kiểm tra, ghi thời gian/RPO/RTO và bằng chứng thật |
| AI | Có adapter/classifier/CLIP; cần model, nhãn, phiên bản, dữ liệu đánh giá và precision/recall nếu đề yêu cầu AI thực |
| Cloud storage/deployment | Có adapter Azure/Docker; cần tài khoản, cấu hình HTTPS/secrets, triển khai và kiểm thử thật nếu bắt buộc |
| Mobile | Hiện tại responsive web. Chỉ bổ sung app riêng khi đề yêu cầu native/mobile app |
| Minh chứng | Chụp trang demo 4 vai trò, SQL workflow, build/tests và backup restore; không dùng ảnh mô phỏng làm kết quả chạy |

## Kịch bản bảo vệ khoảng 10 phút

1. Giới thiệu bài toán, kiến trúc MVC và 18 bảng (1 phút).
2. Admin cấp quyền; Organizer tạo/mở cuộc thi (2 phút).
3. Participant đăng ký, tạo cuộn phim, nộp JPEG/PNG (2 phút).
4. Organizer duyệt; hết hạn nhận bài, bắt đầu chấm và phân công (2 phút).
5. Judge chấm đủ tiêu chí, xác nhận; Organizer đóng vòng, trao giải, công bố (2 phút).
6. Trình bày view tính điểm, trigger audit, kết quả test và giới hạn AI (1 phút).

Chuẩn bị sẵn thời gian cuộc thi để chuyển từ nhận bài sang chấm; không đổi giờ hệ điều hành. Dữ liệu demo 05_demo.sql không có ảnh hay mật khẩu dùng chung nên chưa thay thế được kịch bản demo có người thao tác.

## Mẫu ghi một ca kiểm thử

| ID | Vai trò | Dữ liệu/Thao tác | Mong đợi | Thực tế | Kết luận | Minh chứng |
|---|---|---|---|---|---|---|
| TC-01 | Participant | Nộp cùng SHA256 vào cùng cuộc thi | Từ chối, không thêm Submission/Frame | Chưa chạy | Chờ kiểm thử | Chưa có |
| TC-02 | Judge | Gửi score=abc | Không lưu điểm 0, trả lỗi | Chưa chạy UI | Chờ kiểm thử | Chưa có |
| TC-03 | Judge | Xác nhận sau JudgingEnd | Từ chối | Chưa chạy SQL | Chờ kiểm thử | Chưa có |
| TC-04 | Participant | Hai request khi chỉ còn một suất | Chỉ một request được nhận | Chưa chạy | Chờ kiểm thử | Chưa có |
