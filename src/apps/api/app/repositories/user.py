import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


async def get_first(session: AsyncSession) -> User | None:
    result = await session.execute(select(User).limit(1))
    return result.scalars().first()


async def create(session: AsyncSession, language_id: uuid.UUID, name: str) -> User:
    user = User(id=uuid.uuid4(), language_id=language_id, name=name)
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


async def update(session: AsyncSession, user: User, **fields: object) -> User:
    for key, value in fields.items():
        setattr(user, key, value)
    await session.commit()
    await session.refresh(user)
    return user
