# REPO_HQTCSDL_NHOM10
# FilmRoom — Nền tảng cuộc thi nhiếp ảnh phim

ASP.NET Core MVC / C# / ADO.NET / SQL Server / T-SQL. Giao diện tiếng Việt, responsive, 4 vai trò. JWT trong cookie HttpOnly; các POST MVC dùng antiforgery. Đây là bộ mã nguồn và tài liệu triển khai. Không có website công khai, tài khoản đám mây hoặc detector AI đã được kích hoạt sẵn.

## Đọc theo thứ tự

1. `docs/START_HERE_VI.md`: cài đặt trên Windows, tạo database và chạy website.
2. `docs/PROJECT_REPORT.md`: phân tích, thiết kế, ERD, quy tắc và mô tả dữ liệu.
3. `docs/DEMO.md`: kịch bản trình diễn đủ 4 vai trò.
4. `docs/REQUIREMENTS.md`: đối chiếu yêu cầu, phần phụ thuộc dịch vụ.
5. `docs/DEPLOYMENT.md`: Docker, Azure SQL, Blob, HTTPS, backup.
6. `docs/VALIDATION.md` và `tests/README.md`: bằng chứng kiểm thử và các giới hạn.
7. `ai-service/README.md`: kích hoạt detector và phân loại ảnh bằng mô hình thật.

## Chạy nhanh sau khi cài .NET 8 SDK và SQL Server 2022

Mở PowerShell tại thư mục FilmContest. Chỉ khởi tạo trên một database mới; không chạy lại 01_schema.sql trên database đã có bảng.

```powershell
$env:FILM_DB_ADMIN='Server=localhost;Database=master;Integrated Security=True;Encrypt=True;TrustServerCertificate=True'
$env:FILM_APP_PASSWORD='YOUR_UNIQUE_APP_SQL_PASSWORD_AT_LEAST_16_CHARS'
dotnet run --project scripts/FilmContest.DbTool -- init .
dotnet run --project scripts/FilmContest.DbTool -- test .
```

Nếu instance là SQLEXPRESS, thay `localhost` bằng `localhost\SQLEXPRESS`. Đăng nhập SQL filmapp cần SQL Server bật Mixed Mode; có thể dùng Windows Authentication cho website chạy dưới tài khoản đã được cấp quyền phù hợp (xem hướng dẫn).

```powershell
cd src/FilmContest.Web
dotnet user-secrets set 'ConnectionStrings:SqlServer' 'Server=localhost;Database=FilmContest;User ID=filmapp;Password=YOUR_APP_SQL_PASSWORD;Encrypt=True;TrustServerCertificate=True'
dotnet user-secrets set 'Jwt:Key' 'YOUR_RANDOM_SECRET_AT_LEAST_32_BYTES'
dotnet user-secrets set 'Bootstrap:AdminEmail' 'admin@example.com'
dotnet user-secrets set 'Bootstrap:AdminPassword' 'YOUR_UNIQUE_ADMIN_PASSWORD_AT_LEAST_12_CHARS'
dotnet dev-certs https --trust
dotnet run
```

Mở URL HTTPS hiển thị trong console (launch profile mặc định https://localhost:7080). Chưa cấu hình secret thì ứng dụng chủ động dừng với thông báo thay vì chạy bằng khóa mặc định. Sau khi admin đầu tiên được tạo, xóa Bootstrap secrets; đăng ký các tài khoản còn lại rồi cấp quyền trong /Admin.

## Những gì website thực hiện

- Cuộc thi nháp/mở/chấm/công bố, thể lệ, lịch nhận bài và lịch chấm UTC, hạng mục và trọng số.
- Sao chép cấu hình cuộc thi thành mẫu cho sự kiện mới.
- Đăng ký, cuộn phim, khung hình, JPEG/PNG, metadata, theo dõi bài và phản hồi.
- Duyệt bài có lý do và audit; kiểm tra hạn, số bài, quyền sở hữu và trùng byte.
- Nhiều vòng chấm, phân công từng bài/từng vòng, điểm 0–10, khóa sau xác nhận.
- Điểm có trọng số, thứ hạng theo hạng mục ở vòng cuối, giữ đồng hạng; trao giải thủ công có kiểm tra và công bố.
- Kho ảnh đoạt giải công khai sau công bố, ảnh chưa công bố được kiểm soát quyền.
- Thống kê SQL, xuất CSV chống công thức bảng tính, quản lý vai trò và danh mục phim.
- dHash tìm ảnh gần giống; adapter và service Python cho phát hiện ảnh AI/gắn nhãn. Cần chọn detector, tải trọng số và cấu hình HTTPS.
- Local storage để phát triển, Azure Blob private container khi triển khai.

## Kiểm thử và build

```powershell
dotnet build src/FilmContest.Web -c Release
dotnet run --project tests/FilmContest.Checks -- .
```

Chạy SQL integration trên SQL Server riêng: DbTool mode `test`. Không suy diễn kiểm tra cú pháp SQL thành kiểm thử nghiệp vụ. Tài khoản runtime dùng film_runtime, không dùng sa/dbo khi vận hành.

## Cấu trúc

- src/FilmContest.Web: Controllers, Models, Services, Razor Views, CSS, Dockerfile.
- database: schema, procedure, management, permission, demo, backup/restore.
- scripts/FilmContest.DbTool: tạo database và chạy integration test bằng SqlClient.
- tests: checks chạy tự động và SQL workflow thực.
- ai-service: optional FastAPI + Transformers model adapter.
- docs: hướng dẫn, thiết kế, đối chiếu, kiểm thử, triển khai.

Không chứa mật khẩu hoạt động, API key, ảnh của người dùng hay trọng số mô hình. Không đưa .env, App_Data, user-secrets hoặc connection string thật lên GitHub.
