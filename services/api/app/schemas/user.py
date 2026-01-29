from uuid import UUID

from pydantic import BaseModel, EmailStr

from app.models.user import UserRole


class UserBase(BaseModel):
    email: EmailStr
    display_name: str
    avatar_url: str | None = None
    role: UserRole = UserRole.ENGINEERING
    department: str = ""
    is_comms_team: bool = False


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    display_name: str | None = None
    avatar_url: str | None = None
    role: UserRole | None = None
    department: str | None = None


class User(UserBase):
    id: UUID

    class Config:
        from_attributes = True


class UserPublic(BaseModel):
    id: UUID
    display_name: str
    avatar_url: str | None = None
    role: UserRole
    department: str

    class Config:
        from_attributes = True
