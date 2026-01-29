from pydantic import BaseModel


class UploadUrlRequest(BaseModel):
    filename: str
    content_type: str


class UploadUrlResponse(BaseModel):
    upload_url: str
    media_url: str
