# Kịch bản demo trọn quy trình

Chuẩn bị: database đã tạo, website chạy, 4 tài khoản riêng có đúng vai trò. Dùng cửa sổ trình duyệt riêng từng người. Người dự thi chuẩn bị JPEG/PNG hợp lệ và thông tin cuộn phim. Dữ liệu AI cần endpoint thật nếu muốn demo kết quả detector; nếu không, trình bày Unavailable đúng thực trạng.

1. Admin: đăng nhập, mở /Admin, cho thấy danh sách vai trò, danh mục Kodak/Ilford/Fujifilm, settings và audit. Đăng ký trước các user còn lại rồi cấp Organizer/Judge. Đổi Banner và xem trang chủ.
2. Organizer: tạo cuộc thi “Ánh sáng trên phim”, hạng mục Đời sống, giới hạn 2 ảnh/người; nhận bài từ 5 phút trước đến vài phút sau hiện tại (UTC). Thêm Giải Nhất khi còn Draft; thể lệ ghi giải thưởng và quyền sử dụng ảnh.
3. Cho thấy tiêu chí mặc định 0.3/0.4/0.3. Nếu muốn tiêu chí riêng, xóa bộ và nhập lại có tổng bằng 1. Cấu hình lịch chấm sau hạn nhận bài. Mở cuộc thi.
4. Participant: mở chi tiết, đăng ký. Quản lý cuộn phim: tên “Cuộn 01”, chọn film stock, ISO, máy, lens, khổ, lab. Nộp ảnh với số khung 1, tiêu đề, địa điểm, scan và mã âm bản tùy chọn. Kiểm tra trạng thái Pending.
5. Thử gửi cùng ảnh để minh họa UNIQUE hash, hoặc vượt số lượng. Không cần cố gây lỗi mọi tình huống trong một demo.
6. Organizer: mở Kiểm tra, xem ảnh và metadata, AI checks, duyệt kèm lý do. Nếu provider chưa cấu hình, nói rõ không có kết quả detector, không gọi Unavailable là ảnh thật.
7. Sau hạn và tới lịch chấm: bấm Bắt đầu chấm. Nếu chưa đủ điều kiện, giải thích lỗi; không chỉnh đồng hồ hệ thống. Phân công bài Approved cho Judge ở vòng 1.
8. Judge: mở Bàn chấm thi; xem ảnh và thông số (không lộ tên tác giả trong màn chấm); nhập điểm từng tiêu chí, lưu, sau cùng xác nhận hoàn tất. Ví dụ 8 / 9 / 7 → 8×0.3+9×0.4+7×0.3=8.1.
9. Organizer: kiểm tra phân công đã Finalized; đóng vòng. Nếu cần demo nhiều vòng, tạo vòng tiếp theo, phân công lại, chấm và đóng; điểm cuối lấy vòng có số lớn nhất, không cộng mọi vòng.
10. Chọn giải và bài được trao, kiểm tra rồi công bố. Trang kết quả hiển thị hạng; triển lãm hiển thị ảnh đoạt giải và metadata.
11. Participant: mở Phản hồi, xem lý do duyệt và điểm/nhận xét sau công bố.
12. Organizer: xem báo cáo theo hạng mục và tải CSV. Admin: xem audit tạo cuộc thi/duyệt/công bố.
13. Với SSMS: trình bày FK, CHECK, UNIQUE, procedure usp_Submit/usp_Score, transaction và views; chạy tests/01_workflow.sql trên database thử nghiệm, giữ output thật để đưa vào báo cáo.

Ảnh chụp minh chứng nên gồm: ERD, bảng dữ liệu, thủ tục và kết quả kiểm thử, các màn tạo/nộp/duyệt/chấm/kết quả/triển lãm. Không chụp connection string, API key hoặc mật khẩu vào báo cáo.
