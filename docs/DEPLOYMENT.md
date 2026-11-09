# Triển khai và vận hành

## Local với Docker Desktop

Cần Docker Desktop chạy Linux containers. Copy .env.example thành .env, thay TẤT CẢ placeholder. Không commit .env.

1. `docker compose up -d sql`.
2. Dùng SSMS kết nối localhost,1433 bằng sa và SQL_SA_PASSWORD đã đặt. Chạy script 01/02/03, tạo LOGIN filmapp với mật khẩu tương ứng APP_SQL_CONNECTION, rồi chạy 04/05. Hoặc dùng DbTool init từ máy host, FILM_DB_ADMIN trỏ localhost,1433 và FILM_APP_PASSWORD trùng app login.
3. `docker compose --profile app up -d --build web`.
4. Mở http://localhost:5080. Compose mặc định Development và bind localhost để demo; không dùng trực tiếp cấu hình này làm site Internet.
5. `docker compose logs web` hoặc `docker compose logs sql` để kiểm tra. Không đưa log chứa secret ra nơi công khai. `docker compose down` dừng nhưng giữ volume. KHÔNG dùng down -v nếu cần giữ dữ liệu.

Compose yêu cầu khai báo .env đầy đủ ngay cả khi mới khởi động sql vì nội suy tất cả service. SQL Server Developer dành phát triển/kiểm thử; chọn edition/licensing phù hợp nếu triển khai vận hành thật.

## Azure hoặc host Windows/Linux

Cần người dùng tự có subscription/host và quyền tạo dịch vụ. Bộ mã không có tài khoản cloud; không có deployment công khai đã chạy.

1. Tạo SQL Server trên VM hoặc Azure SQL. Với Azure SQL, tạo database qua portal/CLI trước; bỏ USE master/CREATE DATABASE/USE FilmContest trong script khi kết nối trực tiếp database vì khác SQL Server instance. Dùng contained database user thay CREATE LOGIN nếu phương án Azure SQL yêu cầu. Thiết lập firewall chỉ cho backend. Không dùng sa cho app.
2. Chạy schema/procedures và kiểm thử trên staging. Cấp runtime quyền tương ứng 04_security; bootstrap admin procedure cần được cấp execute. Dùng secret store hoặc managed identity theo môi trường; adapter hiện hỗ trợ connection string.
3. Tạo Azure Storage account và private Blob container `film-assets`. Tắt public access, đặt retention/soft delete phù hợp. App cần quyền đọc/ghi/xóa blob, không cần quyền quản trị toàn subscription.
4. Đặt Storage__Provider=Azure; Storage__AzureConnectionString và Storage__Container qua environment/secret manager. Adapter dùng connection string; chưa triển khai credential rotation tự động.
5. Publish: `dotnet publish src/FilmContest.Web -c Release -o publish`. Chạy app qua host ASP.NET hoặc Dockerfile. Đặt ASPNETCORE_ENVIRONMENT=Production, AllowedHosts theo tên miền thật, Jwt__Key đủ mạnh, ConnectionStrings__SqlServer dùng Encrypt=True và chứng chỉ hợp lệ (không TrustServerCertificate=True khi vận hành thật).
6. Bật HTTPS với chứng chỉ hợp lệ. Nếu reverse proxy kết thúc TLS, cấu hình Hosting__KnownProxy bằng đúng địa chỉ IP proxy để xử lý X-Forwarded-Proto; không tin mọi proxy tùy ý. Với hạ tầng proxy động, cấu hình trust theo môi trường trước khi triển khai. Xác nhận không có vòng lặp HTTPS và cookie có Secure/HttpOnly.
7. Cấu hình AI service HTTPS và model version theo ai-service/README.md. Khóa service khác khóa JWT. API key chỉ lưu backend.
8. Lưu Data Protection keys ra nơi bền vững và bảo vệ bằng cơ chế của host; nếu chạy nhiều instance, chia sẻ key ring để antiforgery hoạt động giữa các instance. File App_Data local chỉ dùng phát triển hoặc volume bền vững; môi trường nhiều instance nên Azure Blob.
9. Xóa Bootstrap admin secrets sau tạo lần đầu. Đăng nhập thử mọi vai trò, thử quyền tải ảnh, CSRF, SQL hạn mức, AI lỗi, restore và kiểm thử tải trước khi mở cho người thật.

## Sao lưu

06_backup_restore.sql là mẫu dành SQL Server instance. Đường dẫn ở máy chủ SQL phải tồn tại và service SQL có quyền ghi. Không chạy restore đè database thật. Sao lưu và kiểm tra cả database, assets/blob và cấu hình vận hành theo chính sách. Không lưu API key cùng gói báo cáo công khai. Azure SQL dùng cơ chế backup/restore phù hợp dịch vụ thay lệnh backup-to-disk của SQL Server.

## Những việc cần làm trước nghiệm thu vận hành

- Chạy SQL workflow và kiểm thử nhiều request cùng lúc trên SQL Server thật.
- Chạy model, ghi model revision, tập dữ liệu và false-positive/false-negative trên ảnh phim.
- Đo kích thước upload, thời gian phản hồi, RAM của model và SQL; AI synchronous có thể kéo dài request, nên chuyển sang background queue nếu tải cao.
- Có quy trình khôi phục, dọn file orphan và giám sát lỗi.
- Chọn cấp phép hạ tầng và thư viện phù hợp; SkiaSharp là thư viện xử lý ảnh thay cho ImageSharp cũ có cảnh báo/license build.

Đây là cấu hình và hướng dẫn triển khai, không phải xác nhận production đã được vận hành hoặc kiểm thử.
