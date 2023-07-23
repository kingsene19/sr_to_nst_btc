import cv2
import numpy as np

def cl_preprocess_img(image, IMG_SIZE=(128, 128)):
    img = np.array(image)
    img = cv2.resize(img, IMG_SIZE, interpolation=cv2.INTER_AREA)
    img = np.array(img).astype("float32")
    img /= 255
    return img

REVERSE_DICT = {0: 'glioma_tumor', 1: 'meningioma_tumor', 2: 'no_tumor', 3: 'pituitary_tumor'}
