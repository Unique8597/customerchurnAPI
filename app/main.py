import os
import mlflow
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

# Load the .joblib model baked into the image at build time
MODEL_BASE = os.path.join(os.path.dirname(__file__), "model")
model_folder = next(os.scandir(MODEL_BASE)).name
MODEL_PATH   = os.path.join(MODEL_BASE, model_folder)
model = mlflow.pyfunc.load_model(MODEL_PATH)


class PredictRequest(BaseModel):
    data: list


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict")
def predict(request: PredictRequest):
    import pandas as pd
    df          = pd.DataFrame(request.data)
    predictions = model.predict(df)
    return {"predictions": predictions.tolist()}
