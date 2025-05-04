*Cách chạy project

Setup: Cài môi trường node và docker

Mở 3 terminal:

_Terminal 1: (Chạy api link với model)

Trường hợp lần đầu chạy:
+ cd Model
+ docker build -t yolo-fastapi . 
+ docker run -p 8000:8000 yolo-fastapi   

Trường hợp đã build image và chạy container:
+ docker container ls -a
+ Copy CONTAINER ID tương ứng với IMAGE NAMES là yolo-fastapi
+ docker container start [containerId]

_Terminal 2: (Chạy backend nodejs):

Trường hợp lần đầu chạy cần pull image ffmpeg từ Docker: (ffmpeg là tool sử dụng để tách frame từ video)
+ docker pull jrottenberg/ffmpeg

Chạy backend:
+ cd Server
+ npm run dev

_Terminal 3: (Chạy Flutter)