# Currency

Representa uma moeda (ISO 4217), usada como configuração de moeda de um
projeto — armazenada em `config.md`, não diretamente em `project.md`.

### Responsabilidades:

- ser global (compartilhada entre todos os projetos)
- possuir código ISO 4217, nome, símbolo e taxa de conversão para USD
- ser selecionável como moeda de um projeto (padrão: USD), via
  `config.md`

### Não deve:

- conter lógica de negócio
- ser a moeda de armazenamento de custos — custos são sempre calculados
  e persistidos em USD (ver `token-usage.md`); a moeda do projeto só é
  usada para converter o valor ao servir pela API
