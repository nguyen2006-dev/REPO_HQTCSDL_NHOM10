> Ghi chú bản sửa: nội dung dưới đây là kết quả có sẵn trong ZIP gốc, chưa được xác minh lại trên cùng môi trường. Xem VALIDATION_REVIEW.md và review-*.log cho kết quả thực tế của bản sửa.

# Kết quả kiểm tra thực tế

Ngày: 23/11/2026. Môi trường Windows x64, .NET SDK 9.0.320 (các ứng dụng target .NET 8), SQL Server 2025 Enterprise Evaluation. Kết quả dưới đây là những gì đã chạy trên bản repo này; không phải chứng nhận production.

## Đã chạy và đạt

- `dotnet build FilmContest.sln -c Release`: thành công, 0 warning, 0 error; build website, DbTool và checks.
- `dotnet build src/FilmContest.Web`: thành công, 0 warning, 0 error.
- `dotnet run --project tests/FilmContest.Checks -- .`: 7 passed, 0 failed. Bao gồm parser T-SQL 160, password hashing, JWT claims/expiry, xử lý ảnh và path traversal.
- `dotnet run --project scripts/FilmContest.DbTool -- test .`: workflow SQL trên SQL Server thật đạt; kiểm tra weighted score, ranking, archive, audit và hai trường hợp từ chối trái quyền. Fixture của workflow được rollback.
- `py -3.15 tests/http_smoke.py`: đạt. Login/Register trả 200, khu vực riêng chuyển hướng khi chưa đăng nhập, POST thiếu antiforgery trả 400.
- `py -3.15 -m compileall -q ai-service`: cú pháp Python đạt; chưa tải dependencies hoặc khởi chạy model.
- Các script schema/procedure/security/demo đã được chạy trên SQL Server trong quá trình kiểm tra dự án. Hỗ trợ SQL Server 2022+ được khai báo; lần chạy môi trường này dùng SQL Server 2025.

## Chưa chạy

- Chưa thử đầy đủ giao diện với bốn tài khoản/vai trò và dữ liệu ảnh thực.
- Chưa kiểm thử tải hoặc hai request đồng thời trên cùng hạn mức.
- Chưa chạy detector AI/CLIP. Adapter chỉ được kiểm tra cú pháp; chưa có số liệu accuracy, precision/recall hay false-positive.
- Chưa cấu hình Azure Blob, triển khai cloud, backup/restore thực tế.
- Docker chưa được cài trên máy kiểm tra nên chưa xác thực `docker compose config` hoặc chạy container.
- Chưa có ứng dụng Flutter/APK; sản phẩm hiện tại là website responsive.

Parser kiểm tra cú pháp T-SQL không thay thế workflow DB; workflow test chỉ bao phủ đường đi mẫu và hai ca từ chối, không thay cho kiểm tra tải hoặc ma trận toàn bộ ràng buộc.

## Trước khi nghiệm thu vận hành

1. Chạy các kịch bản UI trong `tests/README.md` với bốn tài khoản riêng.
2. Bổ sung kiểm thử concurrency và các biên nghiệp vụ như duplicate hash, hạn mức và nhiều vòng.
3. Chọn detector, ghi model revision và đo false-positive/false-negative trên ảnh phim/ảnh scan.
4. Nếu yêu cầu cloud/mobile native, cấu hình và kiểm thử Azure Blob, triển khai HTTPS hoặc bổ sung ứng dụng Flutter.
5. Chụp minh chứng thật, thêm thông tin nhóm/lớp/giảng viên vào báo cáo.
