import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from minio import Minio
from minio.error import S3Error

from app.config import settings
from app.models.user import User as UserModel
from app.routers.auth import get_current_user
from app.schemas.media import UploadUrlRequest, UploadUrlResponse

router = APIRouter(prefix="/media", tags=["media"])


def get_minio_client() -> Minio:
    return Minio(
        settings.minio_endpoint,
        access_key=settings.minio_access_key,
        secret_key=settings.minio_secret_key,
        secure=settings.minio_use_ssl,
    )


def ensure_bucket_exists(client: Minio, bucket_name: str):
    try:
        if not client.bucket_exists(bucket_name):
            client.make_bucket(bucket_name)
    except S3Error as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"MinIO error: {e}",
        )


@router.post("/upload", response_model=UploadUrlResponse)
async def get_upload_url(
    request: UploadUrlRequest,
    current_user: UserModel = Depends(get_current_user),
):
    """Get a presigned URL for uploading media to MinIO."""
    client = get_minio_client()
    ensure_bucket_exists(client, settings.minio_bucket)

    # Generate unique filename
    ext = request.filename.split(".")[-1] if "." in request.filename else ""
    unique_filename = (
        f"{current_user.id}/{uuid.uuid4()}.{ext}"
        if ext
        else f"{current_user.id}/{uuid.uuid4()}"
    )

    try:
        # Generate presigned PUT URL (valid for 1 hour)
        upload_url = client.presigned_put_object(
            settings.minio_bucket,
            unique_filename,
            expires=3600,
        )

        # Construct the final media URL
        protocol = "https" if settings.minio_use_ssl else "http"
        media_url = f"{protocol}://{settings.minio_endpoint}/{settings.minio_bucket}/{unique_filename}"

        return UploadUrlResponse(upload_url=upload_url, media_url=media_url)
    except S3Error as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate upload URL: {e}",
        )
