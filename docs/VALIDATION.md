# Kết quả kiểm tra thực tế

Ngày: 26/10/2026. Môi trường Linux x64; .NET SDK 8.0.427. Đây là ghi nhận kiểm tra, không phải chứng nhận hoàn tất nghiệm thu.

## Đã chạy

- Restore dependency thành công. Thư viện xử lý ảnh được chuyển sang SkiaSharp 3.119.4 và NativeAssets.Linux.NoDependencies cùng phiên bản; không bàn giao ImageSharp cũ có cảnh báo bảo mật/license.
- Build ASP.NET Core MVC: thành công, 0 lỗi. Build bao gồm Razor Views.
- Build Release của website: thành công, 0 warnings, 0 errors trên bản đã kiểm tra; xem final-build.log đi kèm cho lần build cuối.
- Chạy FilmContest.Checks: 7 passed, 0 failed. Kiểm tra parser toàn bộ SQL scripts, password hashing, claims/expiry JWT, từ chối ảnh nhỏ, lưu/đọc/xóa ảnh, ảnh dọc và path traversal.
- Website khởi động local thành công. HTTP /Account/Login và /Account/Register trả 200 có antiforgery token; /Admin, /Judge, /Studio khi chưa đăng nhập chuyển về Login; POST Login thiếu antiforgery trả 400; /Home/Error trả 500 như thiết kế.
- Python AI adapter: kiểm tra cú pháp AST thành công, chưa chạy model.

## Không thể chạy trong môi trường này

SQL Server Linux native đã được tải và thử khởi động nhưng SQLPAL dừng trước trạng thái ready, cùng lỗi môi trường /proc. Vì vậy:

- Chưa thực thi DDL/procedures trên một SQL Server hoạt động.
- Chưa chạy tests/01_workflow.sql và chưa xác nhận các foreign key/quy tắc/điểm số bằng DB thực.
- Chưa chạy giao diện end-to-end với 4 vai trò và dữ liệu thật.
- Chưa kiểm thử concurrency/load, Blob Azure, cloud deployment hoặc model detector/CLIP.
- Không có URL production hoặc APK. Không có dữ liệu giả mạo kết quả kiểm thử hoặc độ chính xác AI.

Parser SQL chỉ chứng minh không có lỗi cú pháp parser phát hiện; không chứng minh bảng tồn tại đúng runtime, quyền đầy đủ, procedure chạy đúng hay đồng thời an toàn.

## Để nghiệm thu

1. Trên máy Windows/SQL Server hoặc Docker, chạy DbTool init và test theo START_HERE_VI.md.
2. Chạy ma trận UI và demo; ghi output và ảnh chụp thực tế.
3. Chọn/cấu hình AI detector, chạy bộ đánh giá ảnh phim, ghi model revision và sai số.
4. Cấu hình private Azure Blob và host HTTPS nếu yêu cầu cloud; kiểm tra quyền và backup/restore.
5. Đối chiếu REQUIREMENTS.md, không đánh dấu mục phụ thuộc chưa chạy là hoàn thành.
