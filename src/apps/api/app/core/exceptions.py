class NotFoundError(Exception):
    def __init__(self, entity: str, resource_id: object) -> None:
        self.entity = entity
        self.resource_id = resource_id
        super().__init__(f"{entity} não encontrado: {resource_id}")
