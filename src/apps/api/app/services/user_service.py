import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.models.user import User
from app.repositories import language as language_repository
from app.repositories import user as user_repository

DEFAULT_LANGUAGE_CODE = "en"
DEFAULT_USER_NAME = "Usuário"


async def get_current_user(session: AsyncSession) -> User:
    user = await user_repository.get_first(session)
    if user is not None:
        return user

    language = await language_repository.get_by_code(session, DEFAULT_LANGUAGE_CODE)
    assert language is not None, f"seed de idioma '{DEFAULT_LANGUAGE_CODE}' ausente"
    return await user_repository.create(session, language_id=language.id, name=DEFAULT_USER_NAME)


async def update_user(
    session: AsyncSession,
    user: User,
    name: str | None = None,
    language_id: uuid.UUID | None = None,
) -> User:
    fields: dict[str, object] = {}

    if name is not None:
        fields["name"] = name

    if language_id is not None:
        language = await language_repository.get_by_id(session, language_id)
        if language is None:
            raise NotFoundError("Language", language_id)
        fields["language_id"] = language.id

    if not fields:
        return user

    return await user_repository.update(session, user, **fields)
