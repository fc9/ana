# Attachment — Tipos MIME Aceitos

Status: Draft
Versão: 0.1
Última atualização: 2026-07-09
Responsável: Arquitetura

---

# 1. Objetivo

Definir a lista de tipos MIME aceitos para anexos (`attachment.type`),
substituindo a validação por extensão por validação por MIME type real
do arquivo (ver `attachment.md` > Limite e retenção).

Origem: revisão de uma lista genérica tipo mime-db (`tmp.md`, ~950
extensões catalogadas — cobre praticamente todo tipo de arquivo já
registrado, não é específica da Ana). A maior parte não se aplica ao
caso de uso de um anexo de chat; a lista abaixo é o recorte curado.

---

# 2. Escopo

## Responsabilidades

- lista de MIME types aceitos por categoria (`image`, `audio`, `video`,
  `text`, `document`, `file`);
- justificativa das categorias inteiras excluídas da lista genérica de
  origem.

## Não Responsabilidades

- mecanismo de validação em si (Route/`GuardService`, ver
  `../architecture/06b-services.md`);
- regras de limite/retenção (ver `attachment.md`).

---

# 3. Lista Aceita

## image

| MIME type       | Extensões        |
|-----------------|------------------|
| `image/jpeg`    | jpg, jpeg        |
| `image/png`     | png              |
| `image/gif`     | gif              |
| `image/webp`    | webp             |
| `image/svg+xml` | svg              |
| `image/tiff`    | tif, tiff        |
| `image/bmp`     | bmp              |
| `image/x-icon`  | ico              |

## audio

| MIME type     | Extensões |
|---------------|-----------|
| `audio/mpeg`  | mp3       |
| `audio/aac`   | aac       |
| `audio/flac`  | flac      |
| `audio/wav`   | wav       |
| `audio/ogg`   | ogg       |

> Os quatro primeiros usam o tipo MIME **atual/registrado**, não o
> legado com prefixo `x-` que aparece em `tmp.md` (`audio/x-aac`,
> `audio/x-flac`, `audio/x-wav`) — ver seção 5, item 8.

## video

| MIME type          | Extensões |
|--------------------|-----------|
| `video/x-msvideo`  | avi       |
| `video/mp4`        | mp4       |
| `video/quicktime`  | mov       |
| `video/x-ms-wmv`   | wmv       |
| `video/webm`       | webm      |
| `video/x-matroska` | mkv       |

## text

| MIME type          | Extensões    |
|--------------------|--------------|
| `text/plain`       | txt (e fallback de código-fonte sem tipo próprio confiável) |
| `text/csv`         | csv          |
| `text/javascript`  | js           |
| `application/json` | json         |
| `text/html`        | htm, html    |
| `text/css`         | css          |
| `application/xml`  | xml          |
| `text/markdown`    | md           |
| `application/x-php`| php          |
| `text/plain`       | py (Python)  |
| `text/plain`       | c, h (C)     |
| `text/plain`       | cs (C#)      |
| `text/plain`       | cpp, cc, cxx, hpp, hh (C++) |
| `text/plain`       | rs (Rust)    |
| `text/plain`       | asm, s (Assembly) |

> `text/javascript` substitui o `application/javascript` de `tmp.md`
> (obsoleto — ver seção 5, item 8). `text/markdown` não está em
> `tmp.md`, mas é relevante (documentação de projeto). `application/x-php`
> não tem registro IANA oficial, mas é convenção de mercado — mantido
> como em `tmp.md`. Python, C, C#, C++, Rust e Assembly são lidos como
> texto simples UTF-8 (`text/plain`), em vez dos tipos MIME específicos
> que `tmp.md` usa para alguns deles (`text/x-c`, `text/x-asm`) — sem
> tipo próprio dedicado para código-fonte, todos caem no mesmo
> tratamento de texto simples.

## document

| MIME type                                                                 | Extensões |
|----------------------------------------------------------------------------|-----------|
| `application/pdf`                                                          | pdf       |
| `application/msword`                                                       | doc       |
| `application/vnd.openxmlformats-officedocument.wordprocessingml.document`  | docx      |
| `application/vnd.ms-excel`                                                 | xls       |
| `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`        | xlsx      |
| `application/vnd.ms-powerpoint`                                            | ppt       |
| `application/vnd.openxmlformats-officedocument.presentationml.presentation`| pptx      |
| `application/vnd.oasis.opendocument.text`                                  | odt       |
| `application/vnd.oasis.opendocument.spreadsheet`                          | ods       |
| `application/vnd.oasis.opendocument.presentation`                         | odp       |

## file (genérico — inclui compactados)

| MIME type                     | Extensões                  |
|--------------------------------|-----------------------------|
| `application/zip`              | zip                         |
| `application/x-rar-compressed` | rar                         |
| `application/x-7z-compressed`  | 7z                          |
| `application/x-cbr`            | cbr, cbz, cb7, cba, cbt (quadrinhos/mangá) |
| `application/octet-stream`     | qualquer arquivo não reconhecido pelas categorias acima |

Arquivos compactados (`zip`, `rar`, `7z`, `cbr`/`cbz` e variantes) são
**aceitos**, mas o conteúdo interno não é processado/inspecionado no
MVP — caem no bucket "demais arquivos" (sem preview, ver
`../architecture/ui/dashboard.md` > Main > Anexos na mensagem).

> Evolução futura: um agente Python especializado em arquivos
> compactados — compacta e descompacta, extrai e adiciona arquivos
> dentro do compactado, e, como parte disso, identifica conteúdo
> malicioso e exclui o anexo imediatamente se encontrar algo suspeito —
> complementa o `GuardService` (ver `../architecture/06b-services.md`),
> que hoje só valida o tipo MIME do arquivo em si, não o que tem dentro
> de um compactado.

---

# 4. Fora de escopo (não fazem parte da lista aceita)

Categorias inteiras excluídas da lista genérica de `tmp.md`, com
exemplos representativos (a lista de origem tem ~950 entradas — a
maioria some numa dessas categorias, não vale enumerar uma por uma):

1. **Executáveis e instaladores** — risco de segurança direto, mesma
   linha do `GuardService` futuro (ver `attachment.md` > Limite e
   retenção): `exe`/`dll`/`com`/`msi` (`application/x-msdownload`),
   `bat`, `apk`, `jar` (executável Java), `jnlp`, `xap`, `sh`/`csh`
   (shell script), instaladores (`air`, `dmg`, `deb`, `pkg`).

2. **Fontes** — são recurso de sistema/frontend, não anexo de usuário:
   `ttf`/`otf`/`woff`/`eot`, `pfa`/`pfb`/`pfm`, `bdf`, `pcf`, `snf`, `gsf`.

3. **Certificados e chaves** — não fazem sentido como anexo de chat, e
   são sensíveis: `crt`, `cer`, `der`, `p7b`/`p7c`/`p7m`/`p7r`/`p7s`,
   `p8`, `p10`, `p12`, `pfx`, `pki`, `pkipath`, `ac`, `cat`.

4. **Formatos proprietários obscuros/legados** — software extinto ou de
   nicho, sem uso prático hoje: dezenas de `application/vnd.*` (Lotus,
   StarDivision, Framemaker, WordPerfect antigo, ClueTrust, Kenamea,
   Groove, Claymore, Novadigm, Fujitsu Oasys, entre outros).

5. **Modelagem 3D / CAD / científico** — fora do escopo de um assistente
   de chat: `dwg`, `dxf`, `iges`/`igs`, `x3d*`, `vrml`/`wrl`, `dae`,
   `mesh`, `model/*` genérico, `chemical/*` (`cdx`, `cif`, `cml`,
   `csml`, `cmdf`, `xyz`).

6. **E-mail e mensagens** — fora de escopo: `eml`, `mbox`
   (`message/rfc822`, `application/mbox`).

7. **Streaming/DRM legado** — uso praticamente nulo hoje: RealMedia
   (`rm`, `rmvb`, `ra`, `ram`), Windows Media legado (`asf`, `wax`,
   `wmx`), dezenas de variantes DECE/UltraViolet (`uvx`, `uvvx` etc. —
   um DRM extinto).

8. **Tipos MIME obsoletos com prefixo `x-` onde já existe um tipo
   registrado atual** — mantidos em `tmp.md` por ser uma lista antiga,
   mas substituídos na lista aceita (seção 3): `audio/x-aac` →
   `audio/aac`; `audio/x-flac` → `audio/flac`; `audio/x-wav` →
   `audio/wav`; `application/javascript` → `text/javascript`.

9. **Linguagens de programação de nicho com MIME exótico** — mantidas
   como `text/plain` genérico em vez dos tipos específicos do `tmp.md`:
   `text/x-fortran` (`f`/`f77`/`f90`), `text/x-pascal` (`pas`).
   Simplifica a lista sem perder a capacidade de aceitar o arquivo (cai
   no fallback de texto). Python, C, C#, C++, Rust e Assembly seguem o
   mesmo princípio (`text/plain`), mas estão explicitados na seção 3 >
   text por serem linguagens comuns nos projetos que a Ana atende.

---

# 5. Documentação Relacionada

## Geral

- `../00-context.md`

## Arquitetura

- `../architecture/06b-services.md` — GuardService
- `../architecture/ui/dashboard.md` — Main > Anexos na mensagem

## Contratos

- `attachment.md`
