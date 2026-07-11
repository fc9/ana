# Language

Representa um idioma (BCP 47), usado como preferência global do usuário
— não do projeto.

### Responsabilidades:

- ser global (compartilhada entre todos os usuários e projetos)
- possuir código BCP 47, nome e endônimo
- ser selecionável como idioma do usuário (padrão: inglês), pela
  interface — vale para toda a Ana, incluindo todos os projetos do
  usuário; futuramente também usada para localizar a UI da Ana

### Não deve:

- conter lógica de negócio
- conter as strings/traduções da interface (isso é responsabilidade do
  Frontend)
- ser uma configuração por projeto (moeda e provider/modelo ativo é que
  ficam por projeto, em `config.md` — não idioma)
