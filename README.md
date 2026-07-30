# git-governance

Governança portátil de branch/merge para qualquer repositório: um subagente do
Claude Code que orienta e executa operações Git dentro de uma taxonomia e uma
matriz de permissão fixas, mais um script que configura a parte que
realmente tem dentes — proteção de branch de verdade no GitHub.

Não há motor de lint local aqui. Nomenclatura de branch e matriz de permissão
são orientação (o subagente); "não pode dar push direto/forçado/apagar
`develop`/`hom`/`main`" é configuração nativa do GitHub (o script) — ver o
porquê da separação em `agents/git-governance-advisor.md`.

## Instalar num repositório

```bash
claude plugin marketplace add licorsy/git-governance
claude plugin install git-governance@licorsy
```

Isso disponibiliza o subagente `git-governance-advisor` em qualquer sessão do
Claude Code aberta nesse repositório.

## Configurar a proteção real no GitHub

Uma vez por repositório (re-executável, idempotente):

```bash
./scripts/setup-branch-protection.sh <owner>/<repo> [branch ...]
```

Sem argumentos de branch, tenta `develop hom main` e pula silenciosamente as
que não existirem. Exige o `gh` CLI autenticado com permissão de admin no
repositório de destino.

O que o script liga:

- `delete_branch_on_merge` no repositório (limpeza remota automática).
- Um *ruleset* por branch protegida existente: bloqueia push direto (exige
  pull request, com 0 aprovações obrigatórias — pensado para mantenedor
  solo), bloqueia force-push e bloqueia deleção.

O que o script **não** faz — e não pode fazer: distinguir "o dono clicou
merge" de "um agente de IA usando as credenciais do dono clicou merge". Essa
distinção fica com o subagente (`git-governance-advisor.md`): ele pergunta
antes de tocar `hom`/`main`; até `develop`, age sozinho.

## Estrutura

- `agents/git-governance-advisor.md` — a persona: taxonomia de branch, matriz
  de permissão, ciclo de vida e formato de saída da validação.
- `scripts/setup-branch-protection.sh` — configura o enforcement real no
  GitHub.
