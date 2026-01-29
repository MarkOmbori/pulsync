from uuid import UUID

from pydantic import BaseModel


class TagBase(BaseModel):
    name: str
    slug: str
    category: str | None = None


class TagCreate(TagBase):
    pass


class TagUpdate(BaseModel):
    name: str | None = None
    slug: str | None = None
    category: str | None = None


class Tag(TagBase):
    id: UUID

    class Config:
        from_attributes = True
