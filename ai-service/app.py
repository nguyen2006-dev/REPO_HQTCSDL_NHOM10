"""Optional real model service. No random or simulated detector outputs."""
import base64
import io
import os
import secrets
import threading
from contextlib import asynccontextmanager
from typing import Annotated
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
from PIL import Image, ImageOps, UnidentifiedImageError
from transformers import pipeline

Image.MAX_IMAGE_PIXELS = 40_000_000
lock = threading.Lock()
models = {}

@asynccontextmanager
async def lifespan(app):
    if len(os.getenv("AI_API_KEY", "")) < 24:
        raise RuntimeError("Set a random AI_API_KEY of at least 24 characters")
    model = os.getenv("AI_DETECTOR_MODEL")
    label = os.getenv("AI_POSITIVE_LABEL")
    if not model or not label:
        raise RuntimeError("Set AI_DETECTOR_MODEL and AI_POSITIVE_LABEL after evaluating a detector")
    models["detector"] = pipeline("image-classification", model=model, device=-1, trust_remote_code=False)
    labels = list(models["detector"].model.config.id2label.values())
    if label not in labels:
        raise RuntimeError(f"AI_POSITIVE_LABEL must be one of model labels: {labels}")
    models["tags"] = pipeline("zero-shot-image-classification", model=os.getenv("AI_TAG_MODEL", "openai/clip-vit-base-patch32"), device=-1, trust_remote_code=False)
    yield
    models.clear()

app = FastAPI(title="FilmRoom model adapter", lifespan=lifespan)

class Request(BaseModel):
    imageBase64: str = Field(max_length=30_000_000)
    mimeType: str

@app.post("/analyze")
def analyze(body: Request, x_api_key: Annotated[str | None, Header()] = None):
    if not secrets.compare_digest(x_api_key or "", os.environ["AI_API_KEY"]):
        raise HTTPException(401, "Invalid service key")
    try:
        raw = base64.b64decode(body.imageBase64, validate=True)
        if len(raw) > 20_000_000:
            raise ValueError("Too large")
        with Image.open(io.BytesIO(raw)) as src:
            if src.width * src.height > 40_000_000:
                raise ValueError("Too many pixels")
            image = ImageOps.exif_transpose(src).convert("RGB")
    except (ValueError, UnidentifiedImageError, Image.DecompressionBombError) as exc:
        raise HTTPException(400, "Invalid image") from exc
    # CPU service serializes model execution; scale workers only after measuring RAM.
    with lock:
        detection = models["detector"](image, top_k=None)
        matching = [float(r["score"]) for r in detection if r["label"] == os.environ["AI_POSITIVE_LABEL"]]
        if len(matching) != 1:
            raise HTTPException(502, "Model label mismatch")
        labels = ["street photography", "portrait", "landscape", "architecture", "nature", "still life", "documentary", "black and white photography"]
        tags = models["tags"](image, candidate_labels=labels)
    return {"aiProbability": matching[0], "tags": [r["label"] for r in tags[:3]]}

@app.get("/health")
def health():
    return {"status": "ready", "model": os.getenv("AI_DETECTOR_MODEL"), "tagsModel": os.getenv("AI_TAG_MODEL", "openai/clip-vit-base-patch32")}
