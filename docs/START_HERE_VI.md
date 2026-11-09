# Bắt đầu trên Windows

## 1. Chuẩn bị

Cài .NET 8 SDK, Visual Studio có workload ASP.NET and web development (hoặc VS Code + CLI), SQL Server 2022 Developer/Express và SQL Server Management Studio. SQL Server là dịch vụ database; SSMS chỉ là công cụ kết nối. Có SSMS chưa có nghĩa đã cài SQL Server.

Chạy `dotnet --info` trong PowerShell. Mở SSMS, kết nối instance của bạn, chạy `SELECT @@VERSION;`. Ghi lại tên server, ví dụ localhost, .\SQLEXPRESS hoặc TENMAY\SQLEXPRESS. Không giả định mọi máy có cùng tên instance.

## 2. Giải nén và mở dự án

Giải nén FilmContest.zip. Trong Visual Studio chọn Open a project, mở `src/FilmContest.Web/FilmContest.Web.csproj`. CLI có thể chạy từ thư mục gốc FilmContest. Có thể mở FilmContest.sln và chọn FilmContest.Web làm Startup Project. Không cần tạo dự án MVC mới rồi copy từng file.

## 3. Tạo cơ sở dữ liệu

Có hai lựa chọn, chỉ dùng một.

### A. Dùng công cụ kèm theo

Mở PowerShell tại thư mục FilmContest. Đặt FILM_DB_ADMIN theo kết nối tài khoản có quyền tạo database và login. Nếu dùng Windows Authentication:

```powershell
$env:FILM_DB_ADMIN='Server=localhost\SQLEXPRESS;Database=master;Integrated Security=True;Encrypt=True;TrustServerCertificate=True'
$env:FILM_APP_PASSWORD='YOUR_UNIQUE_STRONG_PASSWORD_16_OR_MORE_CHARS'
dotnet run --project scripts/FilmContest.DbTool -- init .
```

Tool tạo database, bảng, procedures, login filmapp, phân quyền và cuộc thi minh họa. `init` chỉ chạy một lần trên database sạch; không xóa dữ liệu sẵn có để chạy lại. Nếu lần đầu lỗi giữa chừng, đọc lỗi và tiếp tục các script chưa hoàn thành bằng SSMS, không xóa database thật.

### B. Dùng SSMS

1. Mở và chạy database/01_schema.sql.
2. Chạy 02_procedures.sql.
3. Chạy 03_management.sql.
4. Với quyền DBA, tạo login: `CREATE LOGIN filmapp WITH PASSWORD='YOUR_UNIQUE_STRONG_PASSWORD', CHECK_POLICY=ON;` trong master. Không dùng mật khẩu mẫu trong triển khai thật.
5. Chạy 04_security.sql.
6. Tùy chọn chạy 05_demo.sql. Không chạy 06_backup_restore.sql trước khi cấu hình đường dẫn sao lưu.

Nếu dùng SQL Authentication cho filmapp: SQL Server phải bật SQL Server and Windows Authentication mode; khởi động lại dịch vụ sau khi đổi. Kiểm tra TCP/IP và cổng nếu kết nối bằng host,port. Không mở cổng database ra Internet.

Có thể dùng Windows Authentication cho ứng dụng local: tạo database user cho đúng Windows identity và cấp film_runtime, sau đó dùng Integrated Security=True. Quyền INSERT Users, INSERT FilmRolls và UPDATE Name/TokenVersion được cấp trong 04_security; membership chỉ có hiệu lực khi user ứng dụng thuộc role này.

## 4. Cấu hình website

Vào thư mục src/FilmContest.Web và chạy các lệnh user-secrets trong README. Connection string phải trỏ đúng instance và mật khẩu login filmapp. JWT secret dùng giá trị ngẫu nhiên dài ít nhất 32 byte; ví dụ tạo bằng PowerShell:

```powershell
$bytes = New-Object byte[] 48
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$jwtSecret = [Convert]::ToBase64String($bytes)
dotnet user-secrets set 'Jwt:Key' $jwtSecret
```

Các secret Bootstrap tạo admin đầu tiên nếu database chưa có admin. Website không tạo admin mặc định từ một mật khẩu dùng chung. Sau đăng nhập thành công, xóa hai Bootstrap secrets bằng `dotnet user-secrets remove ...`.

## 5. Chạy

```powershell
dotnet dev-certs https --trust
dotnet build
dotnet run
```

Mở https://localhost:7080 nếu đang dùng launchSettings kèm theo. Đăng nhập bằng admin đã cấu hình. Dùng trình duyệt khác hoặc cửa sổ riêng tư để demo nhiều tài khoản; không chia sẻ cookie.

## 6. Tạo tài khoản và cấp vai trò

Đăng ký 3 tài khoản: người dự thi, ban tổ chức, giám khảo. Tài khoản mới luôn là Participant. Admin mở /Admin, chọn role thích hợp từng người và bấm Lưu, giữ checkbox Hoạt động. Không đổi vai trò tài khoản admin đang dùng. Người được đổi role cần đăng nhập lại.

## 7. Tạo cuộc thi thật đầu tiên

Ban tổ chức vào /Organizer/Create, nhập tên, thể lệ, ngày mở/đóng UTC và hạng mục đầu tiên. Tại trang quản lý: thêm giải, cấu hình tiêu chí (tổng trọng số = 1), điều chỉnh lịch chấm rồi mở nhận bài. Tiêu chí mặc định 30% bố cục + 40% sáng tạo/câu chuyện + 30% kỹ thuật. Có thể xóa bộ tiêu chí khi còn nháp để nhập bộ mới (hạt phim, sắc độ, màu, scan…).

Ngày chấm mặc định bắt đầu 1 phút sau khi đóng nhận bài, kết thúc sau 14 ngày. Để demo, đặt hạn nhận bài vài phút sau hiện tại; hoàn tất đăng ký/nộp trong khoảng đó. Không sửa thời gian máy tính. Thời gian Việt Nam = UTC + 7; ví dụ 19:00 Việt Nam nhập 12:00 UTC cùng ngày.

## 8. Kiểm tra

Từ thư mục gốc, chạy checks và DbTool test theo README. Sau đó thực hiện docs/DEMO.md. Ảnh tự chụp hoặc có quyền sử dụng, JPEG/PNG tối thiểu 800×600. Quản lý cuộn phim trước khi nộp.

## Lỗi thường gặp

| Hiện tượng | Kiểm tra |
|---|---|
| Configure Jwt__Key | Chưa đặt secret hoặc đặt ở sai csproj |
| Login failed for filmapp | Mật khẩu, Mixed Mode, login bị khóa, tên instance |
| Cannot open database | Chưa chạy schema hoặc trỏ sai server |
| Invalid object/procedure | Thiếu script hoặc chưa chạy 03_management |
| User permission denied | 04_security và database user membership |
| Ảnh không nộp được | Đã đăng ký? đúng hạn? cuộn phim của mình? ảnh đủ kích thước? |
| AI Unavailable | Chưa cấu hình AI endpoint/model hoặc provider thất bại |
| Không bắt đầu chấm | Hết hạn nhận bài chưa? đến lịch chấm chưa? còn bài Pending? |
| Không công bố | Các vòng đã đóng? đủ bài được chấm? đã trao giải? |
| Runtime SkiaSharp native error | Restore đúng RID; dùng Docker image Debian kèm native Linux assets |

Ứng dụng cần được build và chạy trên máy của bạn; file ZIP không phải APK hoặc file .exe độc lập.
