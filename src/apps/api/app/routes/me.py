from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_session
from app.schemas.user import UserRead, UserUpdate
from app.services import user_service

router = APIRouter()


@router.get("/me", response_model=UserRead)
async def get_me(session: AsyncSession = Depends(get_session)) -> UserRead:
    user = await user_service.get_current_user(session)
    return UserRead.model_validate(user)


@router.patch("/me", response_model=UserRead)
async def update_me(
    payload: UserUpdate, session: AsyncSession = Depends(get_session)
) -> UserRead:
    user = await user_service.get_current_user(session)
    updated = await user_service.update_user(session, user, **payload.model_dump(exclude_unset=True))
    return UserRead.model_validate(updated)
