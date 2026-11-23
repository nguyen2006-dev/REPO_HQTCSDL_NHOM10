# Đặc tả yêu cầu — FilmRoom

## 1. Mục đích và phạm vi

FilmRoom quản lý quy trình cuộc thi nhiếp ảnh phim: lập cuộc thi, nhận đăng ký và ảnh scan kèm thông tin phim, xác minh bài, chấm theo tiêu chí, công bố giải và lưu trữ tác phẩm. Hệ quản trị dữ liệu dùng SQL Server/T-SQL theo yêu cầu môn học.

Phiên bản hiện tại là website ASP.NET Core MVC responsive. Ứng dụng Flutter native, triển khai cloud và mô hình AI đã đánh giá chưa nằm trong phạm vi đã nghiệm thu. Nếu đề cương của giảng viên yêu cầu các phần này bắt buộc, cần hoàn thành trước khi nộp.

### Vai trò

- **Administrator:** quản lý người dùng/vai trò, cấu hình hệ thống, danh mục phim, nhật ký và cấu hình nền tảng.
- **Contest Organizer:** tạo và quản lý cuộc thi, hạng mục, tiêu chí, giải, đăng ký, duyệt bài, phân công giám khảo và công bố kết quả.
- **Judge:** xem bài được phân công, chấm tiêu chí, ghi nhận xét và xác nhận điểm.
- **Participant:** quản lý hồ sơ/cuộn phim, đăng ký cuộc thi, nộp ảnh và metadata, theo dõi trạng thái, xem kết quả và phản hồi.

Một tài khoản hiện có một vai trò tại một thời điểm.

## 2. Yêu cầu chức năng (Functional Requirements)

| ID | Yêu cầu | Tiêu chí nghiệm thu | Trạng thái hiện tại |
|---|---|---|---|
| FR-01 | Người dùng đăng ký, đăng nhập và quản lý hồ sơ. | Email duy nhất; mật khẩu được băm; đăng nhập sai bị từ chối; hồ sơ chỉ chủ tài khoản sửa được. | Có mã; một số đường xác thực đã được kiểm tra tự động. |
| FR-02 | Admin quản lý người dùng, vai trò và trạng thái hoạt động. | Chỉ Admin được cấp/thu hồi vai trò; phiên làm việc bị thu hồi khi tài khoản bị khóa hoặc đổi quyền. | Có mã; cần chạy UI với tài khoản thật. |
| FR-03 | Admin quản lý cấu hình và master data. | Cấu hình hợp lệ được lưu; danh mục film stock có thể quản lý; thay đổi quan trọng được ghi audit. | Có mã. |
| FR-04 | Organizer tạo và cấu hình cuộc thi. | Lưu chủ đề, thể lệ, hạng mục, giới hạn bài, thời gian nhận bài/chấm; kiểm tra ngày hợp lệ trước khi mở. | Có mã; SQL workflow mẫu đã chạy. |
| FR-05 | Organizer tạo cuộc thi từ mẫu đã có. | Tạo bản nháp mới, sao chép hạng mục/tiêu chí/giải mà không sao chép bài dự thi hoặc điểm. | Có mã; chưa có ca kiểm thử riêng. |
| FR-06 | Participant đăng ký cuộc thi đang mở. | Người chưa đăng nhập/sai vai trò/cuộc thi đóng không thể đăng ký; đăng ký trùng bị từ chối. | Có mã; chưa phủ hết ca biên trong test. |
| FR-07 | Participant quản lý film roll và frame. | Lưu film stock, ISO, camera, lens, format, lab, frame number, location, scan specs và negative reference. | Có mã. |
| FR-08 | Participant gửi ảnh cùng metadata phim. | Chỉ nhận JPEG/PNG hợp lệ; kiểm tra kích thước, hạn thi, đăng ký, quyền sở hữu roll, category và hạn mức bài. | Có mã; upload asset và SQL workflow mẫu đã kiểm tra riêng. |
| FR-09 | Hệ thống ngăn bài trùng. | Cùng frame hoặc cùng SHA-256 không được nộp lặp trong một contest. | Có constraint trong schema; cần test riêng duplicate frame/hash. |
| FR-10 | Organizer duyệt hoặc từ chối bài. | Lưu quyết định, lý do, thời gian và người duyệt; quyết định bị khóa khi bắt đầu chấm. | Có mã; audit được kiểm tra qua workflow SQL. |
| FR-11 | AI hỗ trợ kiểm tra bài dự thi. | Có thể lưu kết quả similarity, generated-image và tags; lỗi dịch vụ trả trạng thái Unavailable, không giả kết quả. AI chỉ gắn cờ để người tổ chức xem xét. | Có adapter/service; chưa cấu hình và đánh giá model thật. |
| FR-12 | Organizer phân công giám khảo theo vòng và bài. | Chỉ Judge đang hoạt động được phân công; giám khảo không tự chấm bài của mình; không cho chấm bài chưa duyệt. | Có mã; ca mẫu đã chạy. |
| FR-13 | Judge chấm bài theo tiêu chí. | Điểm từng tiêu chí trong khoảng 0–10, kèm nhận xét; chỉ người được giao được chấm; lưu trước khi xác nhận. | Có mã; đường chấm mẫu đã chạy. |
| FR-14 | Judge xác nhận hoàn tất đánh giá. | Không thể xác nhận nếu thiếu điểm; sau xác nhận không thể sửa điểm. | Có mã; đã bao phủ một luồng thành công, chưa đủ test ca biên. |
| FR-15 | Hệ thống tính điểm và xếp hạng. | Điểm tiêu chí nhân trọng số; trung bình điểm giám khảo ở vòng cuối; xếp hạng theo hạng mục và giữ đồng hạng. | Có mã; weighted score/ranking mẫu đã chạy. |
| FR-16 | Organizer trao giải và công bố. | Chỉ cuộc thi đã đóng mọi vòng, có giải phù hợp mới được công bố; lưu lịch sử trao giải. | Có mã; đường công bố mẫu đã chạy. |
| FR-17 | Người dùng xem kết quả và phản hồi. | Kết quả/điểm/nhận xét hiển thị theo quyền và trạng thái công bố. | Có mã; cần chạy UI end-to-end. |
| FR-18 | Hệ thống duy trì kho lưu trữ số. | Tác phẩm đoạt giải của cuộc thi đã công bố hiển thị cùng metadata và thông tin giải; asset chưa công bố không bị truy cập trái quyền. | Có mã; view archive đã được workflow SQL xác nhận, cần test quyền tải qua UI. |
| FR-19 | Organizer xem báo cáo và xuất CSV. | Thống kê theo contest/category; ô xuất CSV được escape để tránh công thức bảng tính. | Có mã; chưa kiểm tra UI/bộ dữ liệu thật. |

## 3. Yêu cầu phi chức năng (Non-functional Requirements)

| ID | Yêu cầu | Tiêu chí nghiệm thu | Trạng thái hiện tại |
|---|---|---|---|
| NFR-01 | Xác thực và phân quyền an toàn. | JWT trong cookie HttpOnly; role-based authorization; kiểm tra quyền sở hữu tài nguyên; POST có antiforgery. | Có mã; smoke test login/CSRF đạt. |
| NFR-02 | Bảo vệ mật khẩu và secret. | Mật khẩu băm; JWT/API key/connection string không hard-code trong source hoặc commit. | Có mã và .gitignore; người triển khai tự tạo secrets. |
| NFR-03 | Lưu ảnh an toàn. | Asset lưu private; truy cập qua server kiểm tra quyền; triển khai cloud dùng private Blob. | Local storage có mã; Azure Blob adapter chưa được triển khai/kiểm thử. |
| NFR-04 | Tính toàn vẹn dữ liệu. | PK/FK/UNIQUE/CHECK; thao tác nghiệp vụ dùng transaction; SQL tham số hóa. | Schema và procedure có mã; workflow SQL mẫu đạt. |
| NFR-05 | Khả năng mở rộng và bảo trì. | Tách Controllers, Services, Models, Views; database có index phù hợp. | Có cấu trúc; chưa benchmark tải. |
| NFR-06 | Hỗ trợ nhiều contest và thao tác đồng thời. | Các bản ghi được phân vùng theo contest; kiểm tra không vượt MaxEntries khi gửi đồng thời. | Có cơ chế transaction/lock; chưa có load/concurrency test. |
| NFR-07 | Hỗ trợ thiết bị di động. | Giao diện web responsive dùng được trên màn hình điện thoại. | Có mã web; chưa có ứng dụng Flutter native. |
| NFR-08 | Khả năng triển khai. | Có hướng dẫn cấu hình, container, backup/restore và secrets theo môi trường. | Có tài liệu/Compose; Docker/cloud chưa chạy kiểm chứng trên môi trường này. |
| NFR-09 | Tính minh bạch AI. | Lưu loại kiểm tra, trạng thái, điểm, model version; kết quả AI không tự động thay quyết định của ban tổ chức. | Schema/adapter có mã; chưa có model benchmark. |

## 4. Yêu cầu dữ liệu và T-SQL

Cơ sở dữ liệu phải lưu tối thiểu: Users, Contests, Categories, Registrations, FilmStocks, FilmRolls, Frames, Submissions, SubmissionReviews, Criteria, JudgingRounds, JudgeAssignments, Scores, Awards, SubmissionAwards, AICheckResults và AuditLog.

Các ràng buộc quan trọng:

- Email người dùng là duy nhất; vai trò và trạng thái được giới hạn bởi CHECK.
- Mỗi submission phải trỏ tới category và registration của cùng contest; frame/roll thuộc participant.
- Không vượt MaxEntries; không lặp frame/hash trong contest.
- Score thuộc khoảng 0–10; trọng số tiêu chí hợp lệ và tổng bằng 1 trước khi mở contest.
- Các thao tác nộp bài, duyệt, chấm, xác nhận, đóng vòng và công bố được kiểm tra bằng stored procedure/transaction.

Đối tượng T-SQL gồm schema, foreign keys, CHECK/UNIQUE, indexes, views cho điểm/xếp hạng/archive, trigger audit và stored procedures quản lý nghiệp vụ. Bộ SQL hiện được kiểm thử trên SQL Server 2025; tài liệu đặt mức yêu cầu SQL Server 2022+.

## 5. Sản phẩm bàn giao dự kiến

1. Website quản lý cho Organizer và Judge.
2. Giao diện Participant để đăng ký, quản lý cuộn phim và gửi ảnh.
3. Khu vực Admin quản lý người dùng, cài đặt và master data.
4. AI adapter/service hỗ trợ kiểm tra ảnh; model cụ thể chỉ được công bố khi đã đánh giá.
5. Kho số cho tác phẩm đoạt giải và metadata.
6. Cơ sở dữ liệu T-SQL, scripts kiểm thử, tài liệu kiến trúc, báo cáo và hướng dẫn triển khai.

## 6. Ngoài phạm vi đã nghiệm thu

- Ứng dụng Flutter/APK riêng.
- Detector ảnh AI và mô hình phân loại đã benchmark trên bộ ảnh phim.
- Triển khai production trên Azure/Cloud, Blob storage thật, monitoring và load test.
- Ma trận kiểm thử UI cho mọi vai trò và ca biên.

Nếu các mục này là yêu cầu bắt buộc của giảng viên, đánh dấu lại trong checklist và hoàn thành trước khi nộp.
