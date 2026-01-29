from datetime import datetime, timedelta, timezone
from uuid import UUID

import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.config import settings
from app.db import get_db
from app.models.user import User as UserModel
from app.schemas.auth import LoginRequest, LoginResponse
from app.schemas.user import User as UserSchema
from app.schemas.user import UserCreate

router = APIRouter(prefix="/auth", tags=["auth"])
security = HTTPBearer()


def create_access_token(user_id: UUID) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {"sub": str(user_id), "exp": expire}
    return jwt.encode(
        payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm
    )


def verify_token(token: str) -> UUID:
    try:
        payload = jwt.decode(
            token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm]
        )
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
            )
        return UUID(user_id)
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
        )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> UserModel:
    user_id = verify_token(credentials.credentials)
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found"
        )
    return user


def get_current_user_optional(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        HTTPBearer(auto_error=False)
    ),
    db: Session = Depends(get_db),
) -> UserModel | None:
    if not credentials:
        return None
    try:
        user_id = verify_token(credentials.credentials)
        return db.query(UserModel).filter(UserModel.id == user_id).first()
    except HTTPException:
        return None


@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Exchange SSO token for JWT. For hackathon demo, we accept any token
    and create/return a demo user based on the token value.
    """
    # For demo purposes, parse token as email or create demo user
    email = (
        request.token if "@" in request.token else f"{request.token}@demo.pulsync.io"
    )

    user = db.query(UserModel).filter(UserModel.email == email).first()
    if not user:
        # Create new user
        user = UserModel(
            email=email,
            display_name=email.split("@")[0].replace(".", " ").title(),
            role="engineering",
            department="Engineering",
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token = create_access_token(user.id)
    return LoginResponse(
        access_token=access_token, user=UserSchema.model_validate(user)
    )


@router.post("/register", response_model=LoginResponse)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new user."""
    existing = db.query(UserModel).filter(UserModel.email == user_data.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered"
        )

    user = UserModel(**user_data.model_dump())
    db.add(user)
    db.commit()
    db.refresh(user)

    access_token = create_access_token(user.id)
    return LoginResponse(
        access_token=access_token, user=UserSchema.model_validate(user)
    )


@router.get("/me", response_model=UserSchema)
async def get_me(current_user: UserModel = Depends(get_current_user)):
    """Get current authenticated user."""
    return current_user
