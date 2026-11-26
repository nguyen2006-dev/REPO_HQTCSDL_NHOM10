# Kết quả xác minh bản sửa — 23/11/2026

Môi trường lần này: Linux x64, .NET SDK 8.0.428. Không có SQL Server, Docker hoặc PowerShell trong môi trường kiểm tra. Tài liệu VALIDATION.md là ghi nhận từ ZIP đầu vào, không phải bằng chứng chạy SQL của lần này.

| Kiểm tra thực hiện | Kết quả | Bằng chứng |
|---|---|---|
| Build cả solution Release, MSBuild một worker | Đạt, 0 warning / 0 error | review-build.log |
| FilmContest.Checks Release | 10 passed / 0 failed | review-checks.log |
| HTTP smoke, khởi động web thực | Đạt 8 mục | review-http.log |
| Python compileall AI service và HTTP test | Đạt cú pháp | Lệnh trả mã 0 |

10 checks gồm: parser toàn bộ T-SQL SQL Server 2022; hash mật khẩu; validation mật khẩu thiếu/ngắn; ngày cuộc thi và metadata quá dài; controller từ chối điểm thiếu/sai định dạng/ngoài thang trước truy cập DB; JWT; ảnh quá nhỏ; lưu và đọc ảnh; ảnh dọc; chống path traversal.

8 mục HTTP gồm liveness, login, register, ba khu vực riêng chuyển hướng, POST thiếu CSRF trả 400 và POST đăng ký thiếu mật khẩu với CSRF hợp lệ hiển thị lỗi validation thay vì 500. Thực thi HTTP này không dùng SQL Server.

## Đã thêm nhưng chưa thực thi ở lần này

- tests/02_regressions.sql: 5 ca từ chối (SHA256 trùng, vượt hạn mức, một ngày chấm NULL, điểm 11 của giám khảo được giao, xác nhận sau hạn). Đã qua parser T-SQL; phải chạy DbTool test trên SQL Server để xác nhận nghiệp vụ.
- Update database 07_integrity_update.sql và DbTool init/update: đã build/parse, chưa chạy SQL thật.
- setup-local.ps1: đã rà soát mã, chưa thực thi trên Windows/PowerShell.
- Docker compose: đã sửa cấu hình nhưng chưa chạy docker compose config/up.
- AI service: mới kiểm tra cú pháp Python; chưa cài/tải/chạy mô hình.
- Chưa kiểm thử UI đầy đủ với bốn vai trò, concurrency, tải, Azure hoặc backup/restore.

Không sử dụng 10 checks hoặc parser như bằng chứng hoàn tất end-to-end. Trước nộp, chạy hướng dẫn FIXES_AND_RUN_VI.md và điền kết quả thực tế vào checklist.
