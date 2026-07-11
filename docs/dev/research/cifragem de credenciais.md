Para as credenciais dos providers da Ana, eu usaria **AES-256-GCM**.

Ele oferece **criptografia autenticada**: além de esconder a API key, detecta se o valor criptografado foi alterado no banco. GCM é padronizado pelo NIST e recomendado pela OWASP para dados que precisam ser recuperados posteriormente. ([OWASP Cheat Sheet Series][1])

## Decisão recomendada

```text
Algoritmo: AES-256-GCM
Chave: 256 bits / 32 bytes
Nonce: 96 bits / 12 bytes, aleatório e único por criptografia
Tag: 128 bits / 16 bytes
```

A API key precisa ser recuperada para chamar OpenAI, Anthropic etc.; portanto, **não pode ser armazenada somente como hash**, como seria feito com uma senha.

## Estrutura criptografada

Não salve apenas uma string opaca. Salve um envelope versionado:

```json
{
  "version": 1,
  "algorithm": "AES-256-GCM",
  "key_id": "master-2026-01",
  "nonce": "base64...",
  "ciphertext": "base64..."
}
```

No AES-GCM, dependendo da biblioteca, a tag de autenticação pode vir concatenada ao `ciphertext`.

No banco:

```sql
CREATE TABLE provider_credentials (
    id UUID PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES providers(id),

    name TEXT NOT NULL,
    credential_type TEXT NOT NULL,

    encrypted_secret BYTEA NOT NULL,
    encryption_nonce BYTEA NOT NULL,
    encryption_key_id TEXT NOT NULL,
    encryption_version SMALLINT NOT NULL DEFAULT 1,

    external_account_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Também pode armazenar tudo em um `JSONB`, mas colunas explícitas facilitam migração e rotação.

## Use AAD

O AES-GCM permite passar dados adicionais autenticados, chamados **AAD**. Eles não são criptografados, mas ficam protegidos contra alteração.

Na Ana, eu usaria:

```text
credential_id | provider_id | credential_type | encryption_version
```

Exemplo:

```python
aad = (
    f"{credential_id}|"
    f"{provider_id}|"
    f"{credential_type}|"
    f"{encryption_version}"
).encode("utf-8")
```

Isso impede que alguém copie o conteúdo criptografado de uma credencial para outro provider ou outro registro sem que a descriptografia falhe.

## Implementação em Python

Com a biblioteca `cryptography`:

```python
from __future__ import annotations

import base64
import os
from dataclasses import dataclass

from cryptography.hazmat.primitives.ciphers.aead import AESGCM


@dataclass(frozen=True)
class EncryptedCredential:
    version: int
    algorithm: str
    key_id: str
    nonce_b64: str
    ciphertext_b64: str


class CredentialCipher:
    ALGORITHM = "AES-256-GCM"
    VERSION = 1

    def __init__(self, master_key: bytes, key_id: str) -> None:
        if len(master_key) != 32:
            raise ValueError(
                "A chave mestra do AES-256-GCM deve possuir 32 bytes."
            )

        self._cipher = AESGCM(master_key)
        self._key_id = key_id

    def encrypt(
        self,
        secret: str,
        *,
        credential_id: str,
        provider_id: str,
        credential_type: str,
    ) -> EncryptedCredential:
        nonce = os.urandom(12)

        aad = self._build_aad(
            credential_id=credential_id,
            provider_id=provider_id,
            credential_type=credential_type,
            version=self.VERSION,
        )

        ciphertext = self._cipher.encrypt(
            nonce,
            secret.encode("utf-8"),
            aad,
        )

        return EncryptedCredential(
            version=self.VERSION,
            algorithm=self.ALGORITHM,
            key_id=self._key_id,
            nonce_b64=base64.b64encode(nonce).decode("ascii"),
            ciphertext_b64=base64.b64encode(ciphertext).decode("ascii"),
        )

    def decrypt(
        self,
        encrypted: EncryptedCredential,
        *,
        credential_id: str,
        provider_id: str,
        credential_type: str,
    ) -> str:
        if encrypted.algorithm != self.ALGORITHM:
            raise ValueError(
                f"Algoritmo não suportado: {encrypted.algorithm}"
            )

        nonce = base64.b64decode(encrypted.nonce_b64)
        ciphertext = base64.b64decode(encrypted.ciphertext_b64)

        aad = self._build_aad(
            credential_id=credential_id,
            provider_id=provider_id,
            credential_type=credential_type,
            version=encrypted.version,
        )

        plaintext = self._cipher.decrypt(
            nonce,
            ciphertext,
            aad,
        )

        return plaintext.decode("utf-8")

    @staticmethod
    def _build_aad(
        *,
        credential_id: str,
        provider_id: str,
        credential_type: str,
        version: int,
    ) -> bytes:
        return (
            f"ana:provider-credential:"
            f"{credential_id}:"
            f"{provider_id}:"
            f"{credential_type}:"
            f"v{version}"
        ).encode("utf-8")
```

O nonce não precisa ser secreto. Ele precisa ser **único para cada operação realizada com a mesma chave**. A reutilização de nonce com AES-GCM pode comprometer seriamente a segurança; por isso ele deve ser gerado novamente em toda criptografia, inclusive ao atualizar uma credencial. ([NIST Segurança em Computação][2])

## Onde guardar a chave mestra

A parte mais importante não é somente o algoritmo, mas onde fica a chave AES.

Nunca salve a chave mestra:

```text
no PostgreSQL;
na mesma tabela das credenciais;
no repositório Git;
em um arquivo versionado;
dentro da imagem Docker;
no frontend;
em localStorage;
em logs.
```

Se alguém obtiver o banco **e** a chave mestra, a criptografia deixa de oferecer proteção.

### Para o MVP local da Ana

Uma solução aceitável é:

```text
Windows Credential Manager
        ↓
processo inicializador da Ana
        ↓
backend recebe a chave em memória
        ↓
AES-256-GCM descriptografa credenciais sob demanda
```

Como a aplicação usa Docker, outra possibilidade inicial é um arquivo secreto montado como volume somente para leitura:

```yaml
services:
  api:
    secrets:
      - ana_master_key

secrets:
  ana_master_key:
    file: ./secrets/ana-master-key
```

Mas a pasta `secrets/` precisa estar no `.gitignore`, com permissões restritas, e não deve ser copiada para a imagem.

```gitignore
secrets/
*.key
.env
.env.*
```

Uma variável de ambiente também funciona no primeiro MVP:

```env
ANA_CREDENTIALS_MASTER_KEY=...
```

Porém é inferior ao gerenciador de credenciais ou Docker Secrets, pois variáveis podem aparecer em dumps, diagnósticos, configurações de containers e ferramentas de inspeção.

A OWASP recomenda separar e controlar cuidadosamente o armazenamento, acesso e rotação das chaves criptográficas e demais segredos. ([OWASP Cheat Sheet Series][3])

## Geração da chave

A chave deve ser aleatória, e não uma frase escolhida pelo usuário:

```python
import base64
import secrets

master_key = secrets.token_bytes(32)

print(base64.urlsafe_b64encode(master_key).decode("ascii"))
```

Não faça:

```python
master_key = b"minha-senha-super-secreta"
```

Também não faça simplesmente:

```python
master_key = sha256(password).digest()
```

Caso a Ana futuramente permita que uma senha do usuário desbloqueie o cofre, derive uma chave usando **Argon2id**, com salt e parâmetros adequados. Essa chave derivada deve desbloquear a chave mestra, não necessariamente criptografar diretamente todas as credenciais.

## Envelope encryption

Para a evolução da Ana, recomendo **envelope encryption**:

```text
Master Key / KEK
    │
    └── criptografa uma Data Encryption Key
                          │
                          └── criptografa as credenciais
```

Terminologia:

* **KEK — Key Encryption Key:** chave mestra usada para proteger outras chaves.
* **DEK — Data Encryption Key:** chave usada para criptografar os dados.
* Cada credencial, usuário ou instalação pode ter uma DEK própria.

Estrutura:

```text
Ana Master Key
    └── Provider Credentials DEK
            ├── OpenAI credential
            ├── Anthropic credential
            └── LM Studio token
```

Isso facilita rotação. Ao trocar a chave mestra, você pode recriptografar somente a DEK, sem descriptografar e criptografar novamente todas as credenciais.

Para o MVP, entretanto, uma única chave AES-256-GCM pode ser suficiente, desde que o formato já tenha:

```text
algorithm
version
key_id
nonce
ciphertext
```

## Rotação

O campo `key_id` permite manter temporariamente mais de uma chave:

```text
master-2026-01
master-2027-01
```

Ao ler uma credencial antiga:

```text
1. Consulta o key_id.
2. Descriptografa com a chave antiga.
3. Criptografa novamente com a chave atual.
4. Atualiza key_id, nonce e ciphertext.
```

Isso pode acontecer gradualmente, durante o uso:

```python
if encrypted.key_id != current_key_id:
    secret = decrypt_with_key(encrypted.key_id)
    updated = encrypt_with_current_key(secret)
    save(updated)
```

## Outros

Também não precisa criptografar campos como:

```text
nome da credencial;
tipo do provider;
base URL;
modelo padrão;
external_account_id, caso não seja sensível.
```

Mas nunca exponha a credencial depois de salva. A interface deve mostrar somente algo como:

```text
sk-proj-••••••••••••aB31
```

Esse sufixo deve ser armazenado separadamente no momento do cadastro:

```sql
secret_hint VARCHAR(16)
```

Assim, a Ana não precisa descriptografar a chave apenas para exibir sua identificação.

## Arquitetura final sugerida

```text
src/modules/providers/
├── domain/
│   ├── provider.py
│   └── credential.py
├── application/
│   ├── create_credential.py
│   ├── replace_credential.py
│   └── resolve_credential.py
├── infrastructure/
│   ├── credential_cipher.py
│   ├── master_key_store.py
│   └── credential_repository.py
└── contracts/
    └── secret_store.py
```

O restante da Ana não deve receber a credencial sem necessidade. O fluxo ideal é:

```text
Provider client solicita uma credencial
        ↓
Credential service verifica autorização
        ↓
descriptografa em memória
        ↓
executa a chamada ao provider
        ↓
descarta a referência ao segredo
```

Portanto, a decisão que eu registraria na documentação da Ana seria:

> As credenciais de providers serão criptografadas em repouso com AES-256-GCM,
> usando nonce aleatório exclusivo por operação e AAD vinculando a credencial ao
> provider. A chave mestra será mantida fora do banco de dados e identificada
> por `key_id` no .env, permitindo rotação futura. O formato criptografado será
> versionado para possibilitar migração de algoritmo sem alterar o domínio de
> providers.

[1]: https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html?utm_source=chatgpt.com "Cryptographic Storage - OWASP Cheat Sheet Series"
[2]: https://csrc.nist.gov/csrc/media/projects/crypto-publication-review-project/documents/initial-comments/sp800-38d-initial-public-comments-2021.pdf?utm_source=chatgpt.com "Public Comments on SP 800-38D 1"
[3]: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html?utm_source=chatgpt.com "Secrets Management - OWASP Cheat Sheet Series"
[4]: https://doc.libsodium.org/secret-key_cryptography/aead?utm_source=chatgpt.com "AEAD constructions - Libsodium documentation - GitBook"
