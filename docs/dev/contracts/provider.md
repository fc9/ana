# Provider

Representa a configuração de acesso a um provedor de modelos de linguagem
(ex: OpenAI, Anthropic).

### Responsabilidades:

- armazenar a configuração de acesso a um provedor
- expor os modelos disponíveis daquele provedor
- ser selecionável pelas configurações da Ana

### Não deve:

- conter lógica de negócio da Ana
- ser referenciado diretamente por módulos (o acesso deve passar pela
  camada de abstração de Provider)
