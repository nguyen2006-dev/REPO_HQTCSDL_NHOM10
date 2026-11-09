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


# Mô-đun AI tùy chọn

Đây là adapter chạy mô hình thật bằng Transformers, không trả kết quả ngẫu nhiên. Cần chọn mô hình phát hiện ảnh sinh bởi AI và đánh giá trên tập ảnh phim/ảnh scan thực tế trước khi sử dụng. Không cung cấp hoặc giả định độ chính xác cho mô hình chưa được đánh giá.

1. Tạo Python virtualenv và cài requirements (máy cần đủ RAM cho PyTorch và các mô hình).
2. Chọn một image-classification detector từ nguồn bạn được phép sử dụng. Xác minh giấy phép, nhãn, version/revision và kết quả đánh giá. Đặt AI_DETECTOR_MODEL bằng model ID hoặc đường dẫn cục bộ. Đặt AI_POSITIVE_LABEL đúng nhãn biểu thị ảnh AI theo config của mô hình. Không đoán LABEL_0/LABEL_1.
3. AI_TAG_MODEL mặc định `openai/clip-vit-base-patch32`. Mô hình gợi ý 3 nhãn từ danh sách chủ đề; không tự quyết định hạng mục dự thi của tác giả.
4. Đặt AI_API_KEY ngẫu nhiên, ít nhất 24 ký tự. Khởi động service qua HTTPS (reverse proxy có chứng chỉ hợp lệ hoặc uvicorn --ssl-keyfile ... --ssl-certfile ...). Máy chạy service phải tải được trọng số từ Hugging Face hoặc sử dụng model cục bộ.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:AI_API_KEY='YOUR_RANDOM_SERVICE_SECRET'
$env:AI_DETECTOR_MODEL='YOUR_EVALUATED_MODEL_ID_OR_PATH'
$env:AI_POSITIVE_LABEL='EXACT_AI_LABEL_FROM_MODEL_CONFIG'
uvicorn app:app --host 127.0.0.1 --port 8090 --ssl-keyfile key.pem --ssl-certfile cert.pem
```

Cấu hình website AI__Endpoint=https://ai.yourdomain/analyze, AI__ApiKey khớp secret, AI__ModelVersion ghi tên + revision của detector. Không đưa secret vào git. Chỉ kết nối endpoint do bạn quản lý. Upload ảnh lên dịch vụ bên ngoài phải phù hợp thể lệ và đồng ý của người dự thi.

Request: POST /analyze, header X-Api-Key, JSON `{ "imageBase64":"...", "mimeType":"image/jpeg" }`.
Response: `{ "aiProbability":0.25, "tags":["landscape","nature"] }`.
0.25 ở đây chỉ minh họa schema, không phải kết quả mô hình đã chạy. Dịch vụ không khởi động nếu thiếu detector hoặc cấu hình sai nhãn.

Website đánh dấu Flagged nếu điểm detector >=0.7. Điểm của classifier chưa được hiệu chuẩn không phải xác suất chắc chắn. Đánh giá false positive trên scan phim, hiệu chuẩn ngưỡng và lưu phiên bản trước khi triển khai thật. dHash trên website là thuật toán gần giống, không phải mô hình học máy. Báo cáo thống kê hiện dùng SQL, không tự sinh nội dung bằng LLM.
