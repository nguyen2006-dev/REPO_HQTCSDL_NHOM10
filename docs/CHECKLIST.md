# Checklist triển khai và nộp bài — FilmRoom

Dùng [x] khi có bằng chứng thực tế; dùng [ ] cho việc chưa làm/chưa xác nhận. “Có mã” không tự động đồng nghĩa với “đã nghiệm thu”.

## A. Chốt yêu cầu và phạm vi

- [x] Chọn đề tài: nền tảng quản lý cuộc thi nhiếp ảnh phim tích hợp AI.
- [x] Chọn SQL Server/T-SQL làm hệ quản trị cơ sở dữ liệu cho môn học.
- [x] Xác định bốn vai trò: Admin, Organizer, Judge, Participant.
- [x] Ghi rõ phiên bản hiện tại là website responsive ASP.NET Core MVC.
- [ ] Hỏi/đối chiếu giảng viên xem Flutter native, AI model thật và cloud deployment có bắt buộc không.
- [ ] Chốt giới hạn sản phẩm và phân công cá nhân theo nhóm.

## B. Database/T-SQL — Task 1

- [x] Có schema với bảng, primary key, foreign key, UNIQUE, CHECK và index.
- [x] Có stored procedures cho contest, registration, submission, review, assignment, scoring, finalize, publish và quản trị.
- [x] Có view điểm, ranking, archive và trigger audit.
- [x] Có dữ liệu mẫu và hướng dẫn backup/restore.
- [x] Chạy scripts và workflow mẫu trên SQL Server 2025.
- [x] Workflow xác nhận weighted score, rank, archive, audit và từ chối hai thao tác trái quyền.
- [ ] Kiểm thử duplicate hash/frame, vượt MaxEntries và registration trùng.
- [ ] Kiểm thử FK/CHECK bằng các input sai có chủ đích.
- [ ] Kiểm thử 2 request nộp đồng thời để xác nhận MaxEntries không bị vượt.
- [ ] Chụp bằng chứng SSMS: ERD, schema, procedure/view và kết quả script test.

## C. Participant — Task 2

- [x] Có đăng ký/đăng nhập và quản lý profile.
- [x] Có quản lý film roll/frame metadata.
- [x] Có chức năng gửi ảnh và theo dõi trạng thái.
- [x] Smoke test trang login/register và CSRF đạt.
- [ ] Chạy UI đầy đủ bằng participant thật: register, login, profile, tạo roll, đăng ký contest, upload ảnh.
- [ ] Thử ảnh sai định dạng/kích thước, nộp trễ, thiếu đăng ký, roll của user khác và vượt hạn mức.
- [ ] Xác nhận yêu cầu mobile: responsive web đủ hay phải làm ứng dụng Flutter riêng.

## D. Organizer/Judge/Admin — Task 3

- [x] Có trang Admin quản lý role, settings, master data và audit.
- [x] Có trang Organizer tạo contest, quản lý bài, phân công, vòng chấm, giải và báo cáo.
- [x] Có trang Judge xem bài được giao và lưu điểm/nhận xét.
- [x] SQL workflow mẫu đã qua luồng review → judging → score → finalize → close → award → publish.
- [ ] Demo end-to-end bằng 4 tài khoản riêng.
- [ ] Kiểm tra truy cập trái quyền vào Admin/Judge/Organizer và ảnh chưa công bố.
- [ ] Kiểm thử thiếu điểm, sửa điểm sau finalize, tự chấm bài và công bố khi vòng chưa đóng.
- [ ] Kiểm thử từ hai vòng trở lên; xác nhận ranking dùng vòng cuối.
- [ ] Lưu ảnh chụp màn hình các bước demo và kết quả.

## E. AI — Task 4

- [x] Có cấu trúc lưu kết quả similarity, generated-image và tags.
- [x] Có AI adapter/service; lỗi provider có thể báo Unavailable.
- [x] Có hướng dẫn chọn model và cấu hình secret.
- [ ] Chọn detector có license phù hợp và ghi model ID/revision/positive label.
- [ ] Cài dependencies, khởi động service HTTPS và chạy kiểm tra request/response.
- [ ] Đánh giá trên bộ ảnh scan phim thật: false positive, false negative, precision/recall.
- [ ] Ghi rõ AI chỉ hỗ trợ gắn cờ/phân loại, không tự loại bài.
- [ ] Chụp kết quả AI thật; không dùng JSON ví dụ làm bằng chứng model đã chạy.

## F. Tích hợp, kiểm thử và triển khai — Task 5

- [x] Build toàn solution Release: 0 warning, 0 error.
- [x] Automated checks: 7 passed, 0 failed.
- [x] SQL integration workflow đạt trên SQL Server 2025.
- [x] HTTP smoke đạt: login/register, redirect khi chưa đăng nhập, CSRF.
- [x] Python AI adapter qua kiểm tra cú pháp.
- [x] Có Docker Compose, .env.example, .gitignore và hướng dẫn khởi chạy.
- [ ] Chạy docker compose config và build/run containers trên máy có Docker.
- [ ] Cấu hình/test Azure Blob private container và triển khai HTTPS nếu yêu cầu.
- [ ] Chạy ma trận UI 4 vai trò và concurrency/load test.
- [ ] Kiểm tra backup/restore trên DB thử nghiệm và phục hồi assets.
- [ ] Xác nhận .env, secrets, ảnh cá nhân và file build không bị commit.

## G. Báo cáo và bảo vệ

- [x] Có báo cáo kiến trúc, ERD, từ điển dữ liệu và quy tắc nghiệp vụ.
- [x] Có requirements matrix và validation log.
- [ ] Điền tên trường, lớp, giảng viên, thành viên và phân công thật.
- [ ] Thêm ảnh chụp do nhóm tự chạy, output kiểm thử và số liệu thực.
- [ ] Nêu giới hạn rõ: chưa có native mobile/model đã benchmark/cloud production nếu chưa hoàn thành.
- [ ] Kiểm tra README và lệnh chạy từ máy sạch; rà soát link/file được README dẫn tới.
- [ ] Chuẩn bị demo ngắn: tạo contest → nộp → duyệt → chấm → trao giải → kho lưu trữ.
- [ ] Tạo bản backup cuối và kiểm tra repo/commit trên GitHub trước khi nộp.

## Definition of Done

- [ ] Các yêu cầu bắt buộc của giảng viên đều có bằng chứng chạy được.
- [ ] Build, automated checks và SQL workflow chạy lại từ clone sạch.
- [ ] Demo hoàn tất, dữ liệu mẫu không chứa mật khẩu dùng chung.
- [ ] Báo cáo không trình bày phần chưa chạy như kết quả đã đạt.
- [ ] Nhóm biết giải thích ERD, khóa/ràng buộc, transaction, procedure, phân quyền và các giới hạn AI.
