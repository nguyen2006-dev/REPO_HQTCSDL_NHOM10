# Rà soát, sửa lỗi và hướng dẫn chạy

Ngày 23/11/2026. Phạm vi đối chiếu là mã nguồn, docs/REQUIREMENTS.md và docs/PROJECT_REPORT.md trong ZIP. Không có bản đề bài độc lập nên không khẳng định đáp ứng mọi yêu cầu giảng viên.

## 1. Project này làm gì?

FilmRoom quản lý cuộc thi nhiếp ảnh phim: tạo cuộc thi → đăng ký → quản lý cuộn phim → nộp ảnh scan → duyệt bài → phân công giám khảo → chấm theo trọng số → trao giải → công bố/triển lãm. Có 4 vai trò Admin, Organizer, Judge, Participant. Dùng C#/ASP.NET Core MVC .NET 8, Razor, ADO.NET và SQL Server; dịch vụ Python AI là tùy chọn. Không cần Node/Bun/Vite để chạy website.

## 2. Các điểm đã sửa

| Vị trí | Vấn đề | Cách sửa |
|---|---|---|
| Account/Register | Truy cập Password.Length trước khi kiểm tra binding; POST thiếu password có thể gây NullReferenceException | Chuyển quy tắc mật khẩu vào validation model; giới hạn email và mật khẩu |
| Judge/Score | Không kiểm tra ModelState; điểm không chuyển đổi được có thể thành giá trị mặc định 0 | Điểm nullable, kiểm tra lỗi binding, trường bắt buộc và khoảng 0–10 trước khi gọi SQL |
| Organizer/Schedule | Ngày thiếu/sai định dạng chưa được chặn ở controller | Kiểm tra ngày nullable, ModelState và thứ tự start/end |
| Forms | Một số độ dài/ID không khớp SQL; string tùy chọn bị MVC xem như bắt buộc | Thêm Range/StringLength; nullable và chuẩn hóa chuỗi tùy chọn về rỗng trước SQL |
| Studio/AddRoll | StockId không tồn tại có thể INSERT 0 dòng nhưng vẫn báo thành công | Kiểm tra số dòng và thông báo lỗi |
| usp_FinalizeScore | Chỉ kiểm tra trạng thái vòng, chưa kiểm tra hạn chấm | Bắt buộc còn trong JudgingStart/JudgingEnd |
| usp_Score | Điểm ngoài khoảng chỉ bị CHECK constraint xử lý | Trả lỗi nghiệp vụ 51000 trước khi ghi |
| CK_JudgingDates | CHECK có thể cho qua UNKNOWN khi chỉ một ngày là NULL | Bắt buộc cả hai NULL hoặc cả hai có giá trị và đúng thứ tự |
| DbTool | Không có đường cập nhật; init chạy vào database có sẵn có thể lỗi giữa chừng | Thêm update; init từ chối database có sẵn trước khi tạo bảng; giữ nguyên mật khẩu login đã tồn tại |
| Docker compose | Biến bắt buộc của web có thể làm lệnh chỉ chạy SQL bị lỗi nội suy | Cho phép cấu hình riêng SQL; web vẫn kiểm tra JWT khi khởi động |
| AI Python | Một số ảnh hỏng ném OSError thành HTTP 500 | Trả HTTP 400 cho lỗi giải mã ảnh |

## 3. Chạy lần đầu trên Windows

Cài .NET 8 SDK và SQL Server 2022 Developer/Express; SSMS để quản trị. Kiểm tra `dotnet --info`. Trong SSMS kết nối được đúng server và chạy `SELECT @@VERSION;` trước. Nếu dùng login filmapp, bật SQL Server and Windows Authentication mode rồi restart dịch vụ SQL Server. SSMS không phải dịch vụ database.

Giải nén, mở PowerShell tại thư mục có FilmContest.sln. Chạy:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-local.ps1 -Server 'localhost\SQLEXPRESS'
dotnet dev-certs https --trust
.\scripts\run.ps1
```

Thay server bằng tên hiển thị trong SSMS, ví dụ `localhost` hoặc `TENMAY\SQLEXPRESS`. Script hỏi mật khẩu SQL filmapp mới (16–128 ký tự), tạo database, thiết lập user-secrets, tạo khóa JWT ngẫu nhiên, hỏi email/mật khẩu admin (ít nhất 12 ký tự), build và chạy checks. Mật khẩu SQL phải đáp ứng chính sách SQL Server. Nếu login filmapp đã tồn tại, mật khẩu của login không bị đổi; đặt lại connection string website theo mật khẩu thực tế.

Mở https://localhost:7080. Đăng nhập admin bằng thông tin vừa nhập, đăng ký các tài khoản khác và cấp quyền ở /Admin. Sau khi admin đã được tạo, chạy:

```powershell
dotnet user-secrets remove --project src/FilmContest.Web 'Bootstrap:AdminEmail'
dotnet user-secrets remove --project src/FilmContest.Web 'Bootstrap:AdminPassword'
```

Script setup dành cho SQL Server cài local, dùng Windows Authentication của tài khoản đang chạy để khởi tạo. Với Docker/SQL Authentication hoặc muốn cấu hình thủ công, dùng README và START_HERE_VI.md; không dùng script này với Azure SQL.

## 4. Nếu đã có FilmContest trên máy

Sao lưu database trước. Không chạy lại 01_schema.sql và không DROP database để áp bản sửa.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-local.ps1 -Server 'localhost\SQLEXPRESS' -Update
.\scripts\run.ps1
```

`-Update` giữ user-secrets hiện có, cập nhật procedures và CK_JudgingDates, sau đó build/checks. Nếu dữ liệu lịch chấm cũ không hợp lệ, constraint update dừng; sửa dữ liệu đó rồi chạy lại. Các bước cập nhật procedure/constraint không tạo thành một migration nguyên khối; lỗi sau bước nào phải đọc log và chạy lại sau khi xử lý.

Trong SSMS có thể chạy lần lượt 02_procedures.sql, 03_management.sql và 07_integrity_update.sql. Không chạy 06_backup_restore.sql khi chưa thay đường dẫn/đích phục hồi phù hợp.

## 5. Kiểm tra và demo

```powershell
dotnet build FilmContest.sln -c Release
dotnet run --project tests/FilmContest.Checks -- .
$env:FILM_DB_ADMIN='Server=localhost\SQLEXPRESS;Database=master;Integrated Security=True;Encrypt=True;TrustServerCertificate=True'
dotnet run --project scripts/FilmContest.DbTool -- test .
python tests/http_smoke.py
```

HTTP smoke yêu cầu build Debug mặc định: chạy `dotnet build src/FilmContest.Web` trước. Khi dùng Release, đặt `$env:BUILD_CONFIGURATION='Release'` trước lệnh Python. SQL test phải chạy trong database phát triển/kiểm thử; dữ liệu fixture rollback nhưng identity counters vẫn tăng. Không chạy trên database đang vận hành.

- `/health/live`: 200 nếu tiến trình web sống.
- `/health/ready`: 200 khi truy vấn được bảng cấu hình; 503 khi database chưa sẵn sàng. Đây không phải kiểm tra đầy đủ tất cả procedures/storage.
- Demo 4 vai trò theo docs/DEMO.md. Nhập giờ UTC; giờ Việt Nam trừ 7 giờ để nhập form.
- AI chưa cấu hình sẽ hiển thị Unavailable; nộp ảnh vẫn hoạt động. Không coi đó là kết quả xác nhận ảnh thật.

## 6. Lỗi thường gặp

| Lỗi | Cách xử lý |
|---|---|
| dotnet không nhận lệnh | Cài SDK, mở lại terminal |
| SQL Server không kết nối | Đúng instance trong SSMS, dịch vụ đang chạy, TCP/IP/cổng đúng nếu dùng host,port |
| Login failed filmapp | Kiểm tra Mixed Mode, password và connection string user-secrets |
| Configure Jwt__Key | Đặt user-secrets cho đúng src/FilmContest.Web; script setup tạo khóa tự động |
| FilmContest already exists | Dùng -Update; không dùng init |
| CK_JudgingDates update lỗi | Đảm bảo cả hai ngày chấm có giá trị, start sau close và end sau start |
| Không bắt đầu chấm | Hết hạn nhận bài, đến giờ chấm và không còn Pending |
| Không công bố | Đã đóng mọi vòng và trao ít nhất một giải |
