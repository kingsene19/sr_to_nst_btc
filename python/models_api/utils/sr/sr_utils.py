# from tensorflow.keras.preprocessing.image import load_img, array_to_img, img_to_array
import numpy as np
import base64
import tensorflow as tf
from tensorflow.keras.preprocessing.image import img_to_array
import PIL


model = tf.keras.models.load_model("models/sr_model.h5")

def get_low_res(img, upscale_factor=6):
    return img.resize(
        (img.size[0]//upscale_factor, img.size[1]//upscale_factor),
        PIL.Image.BICUBIC
    )


def upscale_image(img):
    ycbcr = img.convert("YCbCr")
    y, cb, cr = ycbcr.split()
    y = img_to_array(y)
    y = y.astype("float32")/255.0
    input = np.expand_dims(y, axis=0)
    out = model.predict(input)
    out_img_y = out[0]
    out_img_y *= 255.0
    out_img_y = out_img_y.clip(0, 255)
    out_img_y = out_img_y.reshape((np.shape(out_img_y)[0], np.shape(out_img_y)[1]))
    out_img_y = PIL.Image.fromarray(np.uint8(out_img_y), mode="L")
    out_img_cb = cb.resize(out_img_y.size, PIL.Image.BICUBIC)
    out_img_cr = cr.resize(out_img_y.size, PIL.Image.BICUBIC)
    out_img = PIL.Image.merge("YCbCr", (out_img_y, out_img_cb, out_img_cr)).convert("RGB")
    return out_img

def retrieve_base64(path):
    with open(path, 'rb') as f:
        base64image = base64.b64encode(f.read())
    return base64image