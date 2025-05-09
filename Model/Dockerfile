FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y libgl1-mesa-glx libglib2.0-0 git && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN git clone https://github.com/ultralytics/yolov5.git && \
    pip install -r yolov5/requirements.txt

COPY app/ app/
COPY models/ models/

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]