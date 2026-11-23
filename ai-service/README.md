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
