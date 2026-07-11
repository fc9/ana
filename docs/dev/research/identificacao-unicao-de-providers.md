# Identificação Única de Providers

Na Ana, o usuário não deveria cadastrar um provedor dentro de um projeto. Ele
deveria cadastrar o provedor uma única vez na instalação, e os projetos apenas
criar vínculos com esse cadastro.

Assim, vários projetos podem usar o mesmo `provider_id`, mas com modelos,
limites e preferências diferentes.

## O que identifica um provedor

Não use apenas o nome informado pelo usuário, como:

```text
OpenAI
LM Studio
Claude
Servidor local
```

Esses nomes são apenas rótulos.

A identidade deve ser composta por campos normalizados:

```text
provider_type + endpoint + account_or_tenant
```

Exemplos:

```text
openai:api.openai.com:org_abc123
anthropic:api.anthropic.com:account_xyz
lmstudio:http://192.168.0.10:1234
ollama:http://localhost:11434
openai-compatible:https://llm.empresa.com:v1:tenant_acme
```

## `identity_key`

A Ana pode gerar uma chave canônica:

```python
identity_key = sha256(
    f"{provider_type}|{normalized_base_url}|{account_identifier}"
)
```

Mas eu recomendo também manter os componentes separados no banco, porque isso
facilita busca, diagnóstico e migração.

Exemplo:

```json
{
  "provider_type": "openai-compatible",
  "normalized_base_url": "http://192.168.0.10:1234/v1",
  "account_identifier": null,
  "identity_key": "..."
}
```

No banco:

```sql
UNIQUE (
    provider_type,
    normalized_base_url,
    account_identifier
)
```

Como `NULL` pode se comportar de formas diferentes em índices únicos, pode ser
melhor armazenar uma string vazia ou usar um índice baseado em expressão:

```sql
CREATE UNIQUE INDEX providers_unique_identity ON providers (provider_type, normalized_base_url, COALESCE(account_identifier, ''));
```

## Normalização do endpoint

Antes de comparar, normalize a URL.

Estas URLs devem ser consideradas iguais:

```text
HTTP://localhost:1234/
http://localhost:1234
http://localhost:1234/v1/
```

Mas somente remova `/v1` quando isso fizer parte da regra específica daquele
tipo de provedor.

Uma normalização básica pode:

- converter protocolo e host para minúsculas;
- remover `/` final;
- remover porta padrão, como `:443` no HTTPS;
- resolver aliases locais quando possível;
- manter o path relevante;
- remover query string e fragmentos;
- converter `127.0.0.1` e `localhost` para uma representação canônica,
  dependendo do ambiente.

Exemplo:

```python
def normalize_base_url(url: str) -> str:
    parsed = urlparse(url.strip())

    scheme = parsed.scheme.lower()
    host = (parsed.hostname or "").lower()
    port = parsed.port
    path = parsed.path.rstrip("/")

    if host in {"127.0.0.1", "::1"}:
        host = "localhost"

    if (scheme == "https" and port == 443) or (
        scheme == "http" and port == 80
    ):
        port = None

    authority = host if port is None else f"{host}:{port}"

    return f"{scheme}://{authority}{path}"
```

## A API key não deve ser a identidade

Não use a API key como identificador principal porque:

- ela pode ser rotacionada;
- dois projetos podem usar chaves diferentes da mesma conta;
- uma mesma chave pode acessar vários modelos;
- armazenar hash de chave ainda associa identidade a uma credencial descartável;
- provedores locais podem não usar chave.

A credencial pertence à conexão com o provedor, mas não define necessariamente o
provedor.

## Três níveis que vale separar

Eu estruturaria assim:

### 1. Provider Definition

Define que serviço é esse.

```text
OpenAI oficial
Anthropic oficial
LM Studio da máquina principal
Servidor OpenAI-compatible da empresa
```

### 2. Provider Credential

Uma ou mais credenciais associadas ao provedor.

```text
Chave pessoal
Chave do trabalho
Chave somente leitura
Chave de produção
```

### 3. Project Provider Binding

Define como cada projeto utiliza esse provedor.

```text
modelo padrão
temperatura
limite de tokens
credencial selecionada
permissão para ferramentas
prioridade
fallback
```

Estrutura:

```text
Provider
  └── ProviderCredential
        └── ProjectProviderBinding
```

Isso evita confundir “mesmo provedor” com “mesma conta” ou “mesma chave”.

## Provedores oficiais versus compatíveis

Para provedores conhecidos, a identidade pode ser tratada de forma mais rígida.

### OpenAI oficial

```text
provider_type = openai
base_url = https://api.openai.com/v1
account_identifier = organization_id ou project_id
```

### Anthropic oficial

```text
provider_type = anthropic
base_url = https://api.anthropic.com
account_identifier = workspace/account, quando disponível
```

### OpenAI-compatible

Aqui o endpoint é parte essencial da identidade:

```text
provider_type = openai-compatible
base_url = https://servidor.exemplo.com/v1
```

### LM Studio e Ollama

Para servidores locais, o endpoint representa uma instalação acessível:

```text
lmstudio:http://localhost:1234
ollama:http://localhost:11434
```

Mas há uma ressalva: para aplicações em Docker, `localhost`,
`host.docker.internal` e o IP da máquina podem apontar para o mesmo servidor.

A Ana não conseguirá deduzir isso com segurança apenas pela URL.

## Identidade confirmada pelo próprio servidor

Quando possível, a Ana pode consultar o servidor ao cadastrar e obter dados
como:

```json
{
  "provider": "lmstudio",
  "server_id": "f1939b5c-...",
  "version": "0.3.22"
}
```

Nesse caso, uma identidade mais confiável seria:

```text
provider_type + server_instance_id
```

O endpoint passaria a ser apenas a localização atual desse servidor.

Isso é particularmente útil para servidores locais, porque o IP pode mudar.

A Ana poderia ter um protocolo interno opcional:

```http
GET /.well-known/ana-provider
```

Resposta:

```json
{
  "instance_id": "01JZ...",
  "provider_type": "lmstudio",
  "name": "Notebook principal"
}
```

E para serviços que não fornecem esse identificador, ela usa o endpoint
normalizado como fallback.

## Fluxo de cadastro

Quando o usuário tentar adicionar um provedor:

```text
1. Identificar o tipo do provedor.
2. Normalizar o endpoint.
3. Consultar o endpoint, quando possível.
4. Obter account_id, organization_id, tenant_id ou server_id.
5. Gerar a identidade canônica.
6. Procurar um Provider já existente.
7. Se existir, oferecer a vinculação ao projeto (assinatura).
8. Se não existir, criar o Provider global e a assinatura pública ou privada de acordo com o tipo de cadastro.
```

A mensagem poderia ser:

> Este provedor já está cadastrado como “LM Studio — Notebook”. Procure na lista
> de provedores.

Não deve aparecer simplesmente como um erro de duplicidade.

## Caso em que duas contas usam o mesmo endpoint

Por exemplo, duas contas distintas da OpenAI usam:

```text
https://api.openai.com/v1
```

Por isso, apenas o endpoint não basta.

Há duas opções conceituais:

### Opção A: provedor representa o serviço

Existe apenas um registro global “OpenAI”, com várias credenciais.

```text
Provider: OpenAI
Credentials:
- Conta pessoal
- Conta da empresa
```

Essa é a abordagem que considero melhor para a Ana.

### Opção B: provedor representa uma conta no serviço

Existiriam:

```text
OpenAI — Pessoal
OpenAI — Empresa
```

Nesse caso, `account_identifier` faria parte da chave única.

Mas isso mistura o serviço com a conta e tende a complicar a interface.

## Minha recomendação para a Ana

Use esta definição:

> **Provider é uma instalação ou serviço de inferência acessível por um
protocolo e endpoint específicos. Credenciais e assinaturas/contas são entidades
associadas, não a identidade principal do provedor.**

Chave única recomendada para assinaturas:

```text
provider_driver + canonical_instance_identifier
```

Onde:

```text
canonical_instance_identifier =
    server_instance_id
    ou official_service_id
    ou normalized_base_url
```

Exemplos:

```text
openai:official
anthropic:official
google-gemini:official
lmstudio:f1939b5c-...
ollama:http://host.docker.internal:11434
openai-compatible:https://models.acme.com/v1
```

Depois:

```sql
UNIQUE(provider_driver, canonical_instance_identifier)
```

## Modelo rascunho

```sql
CREATE TABLE providers (
    id UUID PRIMARY KEY,
    driver VARCHAR(64) NOT NULL,
    canonical_instance_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    base_url TEXT,
    provider_metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(driver, canonical_instance_id)
);

CREATE TABLE provider_credentials (
    id UUID PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES providers(id),
    name TEXT NOT NULL,
    credential_type TEXT NOT NULL,
    encrypted_secret TEXT NOT NULL,
    external_account_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE project_providers (
    project_id UUID NOT NULL REFERENCES projects(id),
    provider_id UUID NOT NULL REFERENCES providers(id),
    credential_id UUID REFERENCES provider_credentials(id),
    default_model TEXT,
    settings JSONB NOT NULL DEFAULT '{}',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,

    PRIMARY KEY(project_id, provider_id)
); 
```

O ponto mais importante é que a restrição contra duplicidade deve ficar em
`providers`, globalmente, e não nas assinaturas. Projetos só referenciam
um provedor existente. Isso resolve a duplicação sem impedir que cada projeto
tenha configurações independentes.
