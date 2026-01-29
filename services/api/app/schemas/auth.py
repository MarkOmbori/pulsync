from pydantic import BaseModel

from app.schemas.user import User


class LoginRequest(BaseModel):
    token: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: User


class TokenPayload(BaseModel):
    sub: str
    exp: int
