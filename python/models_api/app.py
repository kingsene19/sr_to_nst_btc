from fastapi import FastAPI, HTTPException, Request
from utils.sr.sr_utils import get_low_res, retrieve_base64, upscale_image
from utils.cl.cl_utils import cl_preprocess_img, REVERSE_DICT
from utils.steganography.steg_utils import encode_image, decode_image
import tensorflow as tf
import io
import os
import uvicorn
import numpy as np
import re
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image



app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)


sr_model = tf.keras.models.load_model("models/sr_model.h5", compile=False)
cl_model = tf.keras.models.load_model("models/br_model.h5", compile=False)
# reverse_dict = {0: "NORMAL", 1: "PNEUMONIA"}

@app.post("/getImages")
async def retrieve_low_resolution(request: Request):
    form = await request.form()
    file_content = await form.get("file").read()
    numero = form.get("numero")
    patient = form.get("patient")

    try:
        img = Image.open(io.BytesIO(file_content))
        os.makedirs(f"./data/{numero}/{patient}", exist_ok=True)
        lowres = get_low_res(img)
        lowres.save(f"./data/{numero}/{patient}/lowres.jpg")
        highres = upscale_image(get_low_res(img, upscale_factor=3))
        highres.save(f"./data/{numero}/{patient}/prediction.jpg")
        lowres_base64 = retrieve_base64(f"./data/{numero}/{patient}/lowres.jpg")
        upscaled_base64 = retrieve_base64(f"./data/{numero}/{patient}/prediction.jpg")
    except Exception as e:
        return HTTPException(status_code=500, detail={"error": repr(e)})
    else:
        return {
            "statut": "OK",
            "lowres_image": lowres_base64,
            "superres_image": upscaled_base64
        }


@app.post("/getRecommendation")
async def recommend(request: Request):

    form = await request.form()
    numero = form.get("numero")
    patient = form.get("patient")

    try:
        img = Image.open(f"./data/{numero}/{patient}/prediction.jpg")
        img = cl_preprocess_img(img)
        input = np.array([img])
        pred = cl_model.predict(input)
        index = np.argmax(pred, axis=1)[0]
        prediction = REVERSE_DICT[index]
        confidence = float(pred[0][index])
    except Exception as e:
        return HTTPException(status_code=500, detail={"error": repr(e)})
    else:
        return {
            "statut": "OK",
            "prediction": prediction,
            "confidence": confidence
        }

    
@app.post("/addInfos")
async def addInfos(request: Request):

    form = await request.form()
    nom = form.get("nom")
    diagnostic = form.get("diagnostic")
    prenom = form.get("prenom")
    medecin = form.get("medecin")
    patient = form.get("patient")

    try:
        encode_image(
            medecin,
            patient,
            f"nom: {nom}, prenom: {prenom}, diagnostic: {diagnostic}, medecin: {medecin}"
        )
        hidden_base64 = retrieve_base64(f"./data/{medecin}/{patient}/prediction_encoded.png")
    except Exception as e:
        return HTTPException(status_code=500, detail={"error": repr(e)})
    else:
        return {
            "statut": "OK",
            "hidden_base64": hidden_base64
        }


@app.get("/getInfos")
async def getInfos(medecin: str, patient: str):

    try:
        text = decode_image(f"./data/{medecin}/{patient}/prediction_encoded.png")
    except Exception as e:
        return HTTPException(status_code=500, detail={"error": repr(e)})
    else:
        split_text = text.split(",")
        res_dict = {}
        for i in range(len(split_text)):
            key, value = split_text[i].split(':')
            res_dict[key.strip().replace("'","")] = value.strip().replace("'","")
        message = res_dict["medecin"]
        match = re.search("[a-zA-Z0-9]+", message)
        if match:
            result = match.group()
            res_dict["medecin"] = result
        return {
            "statut": 'OK',
            **res_dict
        }


if __name__ == "__main__":
    uvicorn.run("app:app", host="127.0.0.1", port=5000)