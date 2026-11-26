## Bổ sung bản rà soát

DbTool `test` hiện chạy cả `01_workflow.sql` và `02_regressions.sql`. Năm ca bổ sung kiểm tra trùng hash, hạn mức, lịch chấm NULL một phía, điểm ngoài thang và xác nhận quá hạn. Chạy trên database phát triển riêng bằng tài khoản DBA; fixture rollback nhưng bộ đếm identity vẫn tăng. `FilmContest.Checks` hiện có 10 kiểm tra, gồm validation và controller từ chối điểm sai trước truy cập DB. Kết quả mới xem `docs/VALIDATION_REVIEW.md`.

# Kiểm thử

Chạy tại thư mục FilmContest:

```powershell
dotnet run --project tests/FilmContest.Checks -- .
```

Kiểm tra tự động: parse toàn bộ SQL bằng Microsoft ScriptDom T-SQL 160; mật khẩu băm; claims và thời hạn JWT; từ chối ảnh nhỏ; lưu/đọc/xóa JPEG; chặn path traversal. Đây không phải bằng chứng toàn bộ nghiệp vụ SQL đã chạy đúng.

Sau khi tạo database trên SQL Server, chạy `tests/01_workflow.sql` bằng SSMS với tài khoản DBA trên database thử nghiệm. Script chạy quy trình thực và rollback dữ liệu; assert điểm 8, hạng 1, kho ảnh và audit; kiểm tra từ chối đăng ký trái quyền, chấm trái phân công. SQL tests không cần tệp ảnh thật vì đang kiểm tra tầng dữ liệu.

## Kịch bản kiểm thử giao diện

| Mã | Thao tác | Mong đợi |
|---|---|---|
| UI01 | Đăng ký email mới / email trùng | Thành công / báo lỗi |
| UI02 | Sai mật khẩu, sau đó đúng | Từ chối / đăng nhập |
| UI03 | Participant mở /Admin | HTTP 403 |
| UI04 | Không đăng nhập mở /Judge | Chuyển đến đăng nhập |
| UI05 | Gửi POST thiếu antiforgery | HTTP 400 |
| UI06 | Đăng ký hai lần cùng cuộc thi | Không tạo bản ghi thứ hai |
| UI07 | Nộp JPEG trước khi đăng ký | Từ chối, xóa tệp tạm đã lưu |
| UI08 | Nộp quá hạn / vượt MaxEntries | Từ chối |
| UI09 | Nộp cùng ảnh byte-identical hai lần | Không tạo bài trùng trong cuộc thi |
| UI10 | Chọn cuộn phim của người khác bằng sửa request | Từ chối |
| UI11 | Tải ảnh bài chưa công bố bằng tài khoản khác | HTTP 403 |
| UI12 | Giám khảo sửa AssignmentId sang bài không được giao | Không được chấm |
| UI13 | Xác nhận khi thiếu tiêu chí | Từ chối |
| UI14 | Sửa điểm sau xác nhận | Từ chối |
| UI15 | Công bố khi còn vòng mở hoặc chưa trao giải | Từ chối |
| UI16 | Khóa user đang đăng nhập | Request tiếp theo mất quyền |
| UI17 | AI endpoint hỏng / chưa cấu hình | Không có kết quả giả; bài vẫn lưu |
| UI18 | Đăng nhập >10 lần/phút/IP | HTTP 429 |
| UI19 | Hai giám khảo chấm đồng thời | Lưu điểm độc lập |
| UI20 | Hai tab nộp đồng thời với MaxEntries=1 | Chỉ một bài được ghi |
| UI21 | Nhập tiêu đề bắt đầu =SUM(...) rồi xuất CSV | Được escape thành văn bản |
| UI22 | Tạo vòng 2 khi vòng 1 chưa đóng | Từ chối |
| UI23 | Chấm ngoài lịch chấm thi | Từ chối |

UI20: dùng database thử nghiệm, tạo contest MaxEntries=1, đăng ký một tài khoản; gửi đồng thời hai ảnh khác nhau. Stored procedure giữ UPDLOCK/HOLDLOCK trên contest, tuần tự hóa kiểm tra hạn mức. Xác nhận SELECT COUNT(*)=1. Chưa thay cho bài kiểm thử tải diện rộng.

Các kết quả đã thực sự chạy được ghi trong docs/VALIDATION.md. Không đánh dấu các kịch bản UI ở trên là pass nếu chưa chạy.

HTTP smoke không cần SQL Server: `dotnet build src/FilmContest.Web`, rồi `python tests/http_smoke.py`. Kiểm tra login/register, redirect các khu vực riêng và CSRF. Cần cổng 5088 trống.
