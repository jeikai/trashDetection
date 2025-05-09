from ultralytics import YOLO
import numpy as np
import cv2
import torch
from PIL import Image

model = torch.hub.load('yolov5', 'custom', path='models/best.pt', source='local')

class_names = ['plastic', 'paper', 'battery and electronic', 'metal', 'glass']

def predict_image_with_boxes(image: Image.Image):
    results = model(image)
    print("\nRaw Detection Results:")
    print("---------------------")
    print(results)
    print("\nDetailed Detection Information:")
    print("-----------------------------")
    df = results.pandas().xyxy[0]
    print(df)
    print("-----------------------------")

    image_np = np.array(image)
    image_cv = cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)

    for _, row in df.iterrows():
        x1, y1, x2, y2 = map(int, [row['xmin'], row['ymin'], row['xmax'], row['ymax']])
        conf = row['confidence']
        class_id = int(row['class'])
        label = f"{class_names[class_id]} {conf:.2f}"

        # Draw bounding box
        cv2.rectangle(image_cv, (x1, y1), (x2, y2), (0, 255, 0), 2)

        # Get text size and position
        (text_width, text_height), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.8, 2)
        text_x = x1
        text_y = y1 - 10 if y1 - 10 > text_height else y1 + text_height + 10

        # Draw background rectangle for text
        cv2.rectangle(image_cv, 
                     (text_x, text_y - text_height - baseline),
                     (text_x + text_width, text_y + baseline),
                     (0, 255, 0), -1)

        # Draw text
        cv2.putText(image_cv, label, (text_x, text_y),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 0), 2, cv2.LINE_AA)

    # Convert back to RGB for PIL Image
    image_rgb = cv2.cvtColor(image_cv, cv2.COLOR_BGR2RGB)
    result_image = Image.fromarray(image_rgb)

    return result_image