from ultralytics import YOLO
import numpy as np
import cv2
from PIL import Image

model = YOLO("models/best.pt")

class_names = ['battery', 'glass', 'metal', 'paper', 'plastic', 'trash']

def predict_image_with_boxes(image: Image.Image):
    results = model(image)
    result_data = results[0].boxes.data.cpu().numpy()

    image_np = np.array(image)
    image_cv = cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)

    for box in result_data:
        x1, y1, x2, y2, conf, cls = box
        x1, y1, x2, y2 = map(int, [x1, y1, x2, y2])
        class_id = int(cls)
        label = f"{class_names[class_id]} {conf:.2f}"
        print(class_id)

        cv2.rectangle(image_cv, (x1, y1), (x2, y2), (0, 255, 0), 2)

        (text_width, text_height), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.8, 2)

        text_x, text_y = x1, max(y1 - 10, text_height + 5)
        cv2.rectangle(image_cv, (text_x, text_y - text_height - baseline),
                      (text_x + text_width, text_y + baseline), (0, 255, 0), -1)

        cv2.putText(image_cv, label, (text_x, text_y),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 0), 2, lineType=cv2.LINE_AA)

    image_rgb = cv2.cvtColor(image_cv, cv2.COLOR_BGR2RGB)
    result_image = Image.fromarray(image_rgb)

    return result_image