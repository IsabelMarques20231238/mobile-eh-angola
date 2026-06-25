# AUTENTICACAO - Alteracoes Recentes

Base URL local: `http://127.0.0.1:8000/api`

Esta seccao existe para alinhar frontend web (Norberto) e mobile (Oldemar) antes da integracao do forum.

# DADOS DE TESTE DISPONIVEIS

Foi preparado o seeder `Database\Seeders\ForumTopicSeeder` para popular o forum com 20 topicos realistas de teste:

- 14 topicos `PUBLIC`.
- 6 topicos `PRIVATE`.
- 10 topicos com `cover_image_url`.
- 10 topicos com `cover_image_url=null`.
- Comentarios de teste em pelo menos metade dos topicos.
- Likes aleatorios em topicos e comentarios.
- Autores distribuidos entre utilizadores comuns (`MEMBER`) e moderadores (`ADMIN`/`SUPER_ADMIN`), usando apenas utilizadores ja existentes na BD.

Como identificar os dados de teste:

- Todos os titulos comecam com o prefixo `[TESTE FRONTEND]`.
- Ao executar o seeder, o terminal imprime a lista de IDs criados, alem do resumo por visibilidade e por tipo de autor.

Uso recomendado para frontend web e mobile:

- A equipa pode usar estes topicos para testar listagem, detalhe, comentarios, likes, imagens de capa, topicos sem imagem, privados bloqueados, `has_access`, `join_code`, convites e pedidos de acesso.
- Nao e necessario criar topicos manualmente para validar a primeira integracao.
- O seeder esta registado no `DatabaseSeeder`, mas so corre quando a variavel `SEED_FORUM_TEST_DATA=true` estiver activa. Nao foi executado durante a criacao desta documentacao.

## POST `/api/register`

Campos obrigatorios actuais:

```json
{
  "name": "Nome Completo",
  "email": "email@exemplo.com",
  "password": "password123",
  "password_confirmation": "password123",
  "profession": "ESTUDANTE",
  "accepted_terms": true
}
```

- `profession` e obrigatorio e valida `in:ESTUDANTE,PROFESSOR,OUTRO`.
- `accepted_terms` e obrigatorio e deve ser `true` (`required|accepted`).
- Ja nao envia codigo de verificacao por email no registo.
- Em vez disso, envia email de boas-vindas informativo, sem codigo.
- `email_verified` fica sempre `false` depois de registo normal. E informativo e nao bloqueia a utilizacao da app.
- Login com Google continua a marcar `email_verified=true` automaticamente.
- Resposta de sucesso retorna `{ message, user, token }`; a app pode usar imediatamente.
- Se o email de boas-vindas falhar, o registo nao falha; o erro fica apenas nos logs internos.

Resposta `201`:

```json
{
  "message": "Utilizador registado com sucesso.",
  "user": {
    "id": 12,
    "name": "Nome Completo",
    "email": "email@exemplo.com",
    "profession": "ESTUDANTE",
    "accepted_terms": true,
    "email_verified": false,
    "is_active": true,
    "created_at": "2026-06-17T10:00:00.000000Z"
  },
  "token": "1|plain-text-token"
}
```

## POST `/api/login`

Sem alteracoes relevantes.

Body:

```json
{ "email": "email@exemplo.com", "password": "password123" }
```

Resposta:

```json
{
  "message": "Login efectuado com sucesso.",
  "user": {
    "id": 12,
    "name": "Nome Completo",
    "email": "email@exemplo.com",
    "profession": "ESTUDANTE",
    "accepted_terms": true,
    "roles": [{ "id": 44, "user_id": 12, "role": "USER" }]
  },
  "token": "1|plain-text-token"
}
```

## POST `/api/forgot-password`

Continua a usar codigo de verificacao por email. Este fluxo ainda usa codigo, diferente do registo.

Body:

```json
{ "email": "email@exemplo.com" }
```

Resposta:

```json
{ "message": "Codigo de recuperacao enviado com sucesso." }
```

## POST `/api/reset-password`

Body:

```json
{
  "email": "email@exemplo.com",
  "code": "123456",
  "password": "novaPassword123",
  "password_confirmation": "novaPassword123"
}
```

Resposta:

```json
{ "message": "Password redefinida com sucesso." }
```

## GET `/api/me`

Retorna dados do utilizador autenticado, incluindo `profession`, `accepted_terms`, `roles` e, nos payloads do forum, `display_role` quando aplicavel.

```json
{
  "id": 12,
  "name": "Nome Completo",
  "email": "email@exemplo.com",
  "profession": "ESTUDANTE",
  "accepted_terms": true,
  "roles": [{ "role": "USER" }]
}
```

# Documentacao Detalhada do Forum

Base URL local: `http://127.0.0.1:8000/api`

Rotas autenticadas exigem:

```http
Authorization: Bearer {token}
Accept: application/json
```

## Regras de Negocio do Forum

### 1. `display_role`

O frontend deve usar sempre `author.display_role` em topicos e comentarios. Nunca mostrar o role real (`USER`, `AUTHOR`, `ADMIN`, `SUPER_ADMIN`) ao utilizador final.

Mapeamento:

| Role real | Display |
|---|---|
| `USER` | `Membro` |
| `AUTHOR` | `Escritor` |
| `ADMIN` | `Moderador` |
| `SUPER_ADMIN` | `Moderador` |

Se o utilizador tiver varios roles, `ADMIN`/`SUPER_ADMIN` tem prioridade sobre `AUTHOR`, e `AUTHOR` tem prioridade sobre `USER`.

### 2. Quem pode criar topico `PRIVATE`

So `AUTHOR`, `ADMIN` e `SUPER_ADMIN` podem criar topico privado. `USER` so cria `PUBLIC`. Se `USER` enviar `visibility: "PRIVATE"`, a API retorna `403`.

```json
{ "message": "Apenas Escritores e Moderadores podem criar grupos privados no forum. Continua a participar nos topicos publicos!" }
```

### 3. Formato do `join_code`

`join_code` tem exactamente 6 caracteres alfanumericos maiusculos, exemplo `A7K2P9`. E gerado automaticamente quando o topico privado e criado ou quando e necessario criar link. O utilizador nunca envia nem define manualmente este codigo no create/update.

### 4. `has_access` vs `visibility`

- `visibility` mostra o tipo do topico: `PUBLIC` ou `PRIVATE`.
- `has_access` mostra se o utilizador autenticado pode ver o conteudo completo.
- Na listagem, `body` mostra sempre preview/resumo, mesmo quando `has_access=false`.
- No detalhe, se `has_access=false`, `body=null` e `comments=null`.
- `has_access=true` se o utilizador e autor do topico ou existe em `topic_members`.
- `has_access` nao depende de role global. Um `ADMIN` nao entra automaticamente em `topic_members`; para detalhe privado, o acesso completo segue as regras acima.

### 5. `participants_display`

- Topico `PUBLIC`: retorna `"Qualquer um"`.
- Topico `PRIVATE`: retorna o numero de membros (`participants_count`).

### 6. As 4 formas de aceder a topico privado

| Forma | Endpoint | Comportamento |
|---|---|---|
| Codigo | `POST /api/forum/topics/{id}/join-with-code` | Entra directamente sem aprovacao se o codigo estiver correcto. |
| Link de convite | `GET /api/forum/join/{code}` | Com token entra directamente; sem token retorna `requires_auth=true` para pedir login primeiro. |
| Convite directo | `POST /api/forum/topics/{id}/invite` | Cria convite e notificacao. O convidado precisa aceitar ou rejeitar. |
| Solicitar acesso | `POST /api/forum/topics/{id}/request-access` | Cria pedido pendente; precisa aprovacao de owner/moderador local do topico. |

### 7. Quem modera o que

- `ADMIN`/`SUPER_ADMIN`: podem fixar (`toggle-pin`), fechar e eliminar qualquer topico, mesmo nao sendo membros.
- Editar/apagar topico: autor ou moderador global (`MODERATOR`, `ADMIN`, `SUPER_ADMIN`).
- Aprovar/rejeitar pedidos de acesso: so owner do topico ou membro com role local `MODERATOR`. Nao e qualquer admin aleatorio, conforme regra de negocio do forum privado.
- Gerar link e convidar utilizadores: owner ou moderador local do topico.

### 8. Tags/Hashtags

- Autocomplete `GET /api/tags?search=` so sugere tags ja existentes na base de dados.
- Se a pesquisa nao encontrar nada, retorna `[]`.
- Ao criar/editar topico, se enviar tag nova em `tags[]`, a API cria automaticamente.
- Tambem e possivel enviar `tag_ids[]` com IDs existentes.

## Modelo de Resposta de Topico

```json
{
  "id": 1,
  "title": "Como preservar arquivos historicos?",
  "body": "Texto completo ou preview do topico...",
  "cover_image_url": "https://res.cloudinary.com/demo/image/upload/forum/capa.jpg",
  "author": {
    "id": 12,
    "name": "Nome Completo",
    "email": "email@exemplo.com",
    "avatar_url": null,
    "bio": null,
    "profession": "ESTUDANTE",
    "institution": null,
    "accepted_terms": true,
    "email_verified": false,
    "is_active": true,
    "roles": [{ "id": 44, "user_id": 12, "role": "USER" }],
    "display_role": "Membro"
  },
  "category": { "id": 3, "name": "Historia", "description": "Historia de Angola" },
  "tags": [{ "id": 1, "name": "arquivo", "usage_count": 4 }],
  "is_pinned": false,
  "is_read_only": false,
  "status": "OPEN",
  "visibility": "PUBLIC",
  "join_code": null,
  "views": 20,
  "likes_count": 5,
  "comments_count": 2,
  "participants_count": 1,
  "participants_display": "Qualquer um",
  "is_liked": false,
  "is_saved": false,
  "has_access": true,
  "comments": null,
  "created_at": "2026-06-17T10:00:00.000000Z",
  "updated_at": "2026-06-17T10:00:00.000000Z"
}
```

# Listagem e Descoberta

## GET `http://127.0.0.1:8000/api/forum/topics`

Auth: opcional. Sem token lista publicos. Com token tambem lista privados em que o utilizador e autor ou membro.

Quem pode usar: qualquer visitante; token melhora personalizacao e acesso.

Query params:

| Parametro | Valores | Descricao |
|---|---|---|
| `category` | texto | Filtra por nome de categoria com `like`. |
| `category_id` | numero | Filtra por categoria exacta. |
| `visibility` | `PUBLIC`, `PRIVATE` | Filtra visibilidade. `PRIVATE` sem auth retorna vazio. |
| `filter` | `trending` | Ordena por fixado, likes e comentarios. |
| `filter` | `recent` | Usa ordenacao recente padrao. |
| `filter` | `most_commented` | Ordena por comentarios. |
| `filter` | `relevant` | Score: likes * 2 + comentarios * 3. |
| `filter` | `for-you` | Prioriza categorias onde o utilizador interagiu. |
| `search` | texto | Pesquisa no titulo. |
| `comments_sort` | `recent`, `popular`, `all` | Usado no detalhe; pode ser enviado junto para manter estado de UI. |
| `status` | `OPEN`, `CLOSED`, `ARCHIVED` | Se ausente, lista `OPEN` e `CLOSED`. |
| `per_page` | numero | Default `15`. |

Body: nao se aplica.

Sucesso `200`:

```json
{
  "data": [
    {
      "id": 1,
      "title": "Como preservar arquivos historicos?",
      "body": "Texto completo ou preview do topico...",
      "cover_image_url": "https://res.cloudinary.com/demo/image/upload/forum/capa.jpg",
      "author": { "id": 12, "name": "Nome Completo", "display_role": "Membro", "roles": [{ "role": "USER" }] },
      "category": { "id": 3, "name": "Historia", "description": "Historia de Angola" },
      "tags": [{ "id": 1, "name": "arquivo", "usage_count": 4 }],
      "is_pinned": false,
      "is_read_only": false,
      "status": "OPEN",
      "visibility": "PUBLIC",
      "join_code": null,
      "views": 20,
      "likes_count": 5,
      "comments_count": 2,
      "participants_count": 1,
      "participants_display": "Qualquer um",
      "is_liked": false,
      "is_saved": false,
      "has_access": true,
      "comments": null,
      "created_at": "2026-06-17T10:00:00.000000Z",
      "updated_at": "2026-06-17T10:00:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 1,
    "category_counts": [{ "id": 3, "name": "Historia", "topics_count": 8 }]
  }
}
```

Erros:

| Status | Quando ocorre |
|---|---|
| `403` | Nao esperado nesta rota. Privados sem acesso ficam ocultos ou bloqueados no detalhe. |
| `404` | Nao esperado. |
| `422` | Nao ha validacao formal hoje; pode ocorrer se validacoes forem adicionadas no futuro. |

## GET `http://127.0.0.1:8000/api/forum/topics/{id}`

Auth: opcional. Necessario para ver corpo/comentarios de privados.

Quem pode usar: qualquer visitante para publicos; autor/membro para privado completo.

Body: nao se aplica.

Sucesso `200` com acesso:

```json
{
  "id": 1,
  "title": "Como preservar arquivos historicos?",
  "body": "Texto completo do topico privado.",
  "cover_image_url": "https://res.cloudinary.com/demo/image/upload/forum/capa.jpg",
  "author": { "id": 12, "name": "Norberto", "display_role": "Escritor", "roles": [{ "role": "AUTHOR" }] },
  "category": { "id": 3, "name": "Historia", "description": "Historia de Angola" },
  "tags": [{ "id": 1, "name": "arquivo", "usage_count": 4 }],
  "is_pinned": false,
  "is_read_only": false,
  "status": "OPEN",
  "visibility": "PRIVATE",
  "join_code": "A7K2P9",
  "views": 21,
  "likes_count": 5,
  "comments_count": 2,
  "participants_count": 3,
  "participants_display": 3,
  "is_liked": false,
  "is_saved": true,
  "has_access": true,
  "comments": [
    {
      "id": 10,
      "author_id": 13,
      "forum_topic_id": 1,
      "parent_id": null,
      "text": "Boa pergunta.",
      "likes_count": 2,
      "author": { "id": 13, "name": "Oldemar", "display_role": "Membro" },
      "replies": []
    }
  ],
  "created_at": "2026-06-17T10:00:00.000000Z",
  "updated_at": "2026-06-17T10:00:00.000000Z",
  "related_topics": []
}
```

Sucesso `200` sem acesso a privado:

```json
{
  "id": 1,
  "title": "Como preservar arquivos historicos?",
  "body": null,
  "visibility": "PRIVATE",
  "join_code": null,
  "has_access": false,
  "comments": null,
  "related_topics": []
}
```

Erros:

| Status | Quando ocorre |
|---|---|
| `403` | Nao retorna para detalhe bloqueado; usa `has_access=false`. |
| `404` | Topico inexistente ou apagado. |
| `422` | Nao esperado. |

## GET `http://127.0.0.1:8000/api/forum/featured`

Auth: opcional.

Quem pode usar: qualquer visitante; com token inclui privados acessiveis.

Body: nao se aplica.

Sucesso `200`:

```json
{
  "data": [
    {
      "id": 2,
      "title": "Debate em destaque",
      "body": "Preview do topico...",
      "is_pinned": true,
      "visibility": "PUBLIC",
      "has_access": true,
      "likes_count": 12,
      "comments_count": 8
    }
  ]
}
```

Erros: `403`, `404`, `422` nao esperados.

## GET `http://127.0.0.1:8000/api/forum/my-topics`

Auth: sim.

Quem pode usar: qualquer utilizador autenticado.

Body: nao se aplica.

Sucesso `200`:

```json
{
  "data": [{ "id": 1, "title": "Meu topico", "body": "Preview...", "visibility": "PUBLIC", "has_access": true }],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 15, "total": 1 }
}
```

Erros:

| Status | Quando ocorre |
|---|---|
| `403` | Nao esperado para utilizador autenticado. |
| `404` | Nao esperado. |
| `422` | Nao esperado. |

## GET `http://127.0.0.1:8000/api/forum/bookmarks`

Auth: sim.

Quem pode usar: qualquer utilizador autenticado.

Body: nao se aplica.

Sucesso `200`:

```json
{
  "data": [{ "id": 1, "title": "Guardado", "is_saved": true, "visibility": "PUBLIC", "has_access": true }],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 15, "total": 1 }
}
```

Erros: `403`, `404`, `422` nao esperados.

# Criar e Gerir Topico

## POST `http://127.0.0.1:8000/api/forum/topics`

Auth: sim.

Quem pode usar: `USER`, `AUTHOR`, `ADMIN`, `SUPER_ADMIN`. `USER` apenas `PUBLIC`; `AUTHOR`/`ADMIN`/`SUPER_ADMIN` podem `PUBLIC` e `PRIVATE`.

Body com todos os campos possiveis:

```json
{
  "title": "Novo topico",
  "body": "Texto completo do topico",
  "category_id": 3,
  "visibility": "PRIVATE",
  "is_read_only": false,
  "cover_image_url": "https://res.cloudinary.com/demo/image/upload/forum/capa.jpg",
  "tags": ["historia", "arquivo"],
  "tag_ids": [1, 2],
  "status": "OPEN",
  "is_pinned": false
}
```

Observacoes: `is_pinned` so e respeitado para moderadores globais. `join_code` e criado automaticamente se `visibility=PRIVATE`.

Sucesso `201`:

```json
{
  "id": 1,
  "title": "Novo topico",
  "body": "Texto completo do topico",
  "cover_image_url": "https://res.cloudinary.com/demo/image/upload/forum/capa.jpg",
  "author": { "id": 12, "name": "Norberto", "display_role": "Escritor", "roles": [{ "role": "AUTHOR" }] },
  "category": { "id": 3, "name": "Historia", "description": "Historia de Angola" },
  "tags": [{ "id": 1, "name": "historia", "usage_count": 9 }],
  "is_pinned": false,
  "is_read_only": false,
  "status": "OPEN",
  "visibility": "PRIVATE",
  "join_code": "A7K2P9",
  "views": 0,
  "likes_count": 0,
  "comments_count": 0,
  "participants_count": 1,
  "participants_display": 1,
  "is_liked": false,
  "is_saved": false,
  "has_access": true,
  "comments": null,
  "created_at": "2026-06-17T10:00:00.000000Z",
  "updated_at": "2026-06-17T10:00:00.000000Z"
}
```

Erros:

| Status | Quando ocorre |
|---|---|
| `403` | `USER` tenta criar `PRIVATE`. |
| `404` | Nao esperado; categoria invalida gera `422`. |
| `422` | `title`, `body` ou `category_id` ausentes; categoria/tag inexistente; `visibility`/`status` invalido. |

## PUT `http://127.0.0.1:8000/api/forum/topics/{id}`

Auth: sim.

Quem pode usar: owner/autor do topico ou moderador global (`MODERATOR`, `ADMIN`, `SUPER_ADMIN`). `USER` autor nao pode converter para `PRIVATE`.

Body com todos os campos possiveis:

```json
{
  "title": "Titulo actualizado",
  "body": "Texto actualizado",
  "category_id": 4,
  "visibility": "PUBLIC",
  "is_read_only": true,
  "cover_image_url": null,
  "tags": ["economia", "petroleo"],
  "tag_ids": [5],
  "status": "CLOSED",
  "is_pinned": true
}
```

Sucesso `200`: retorna o topico completo actualizado.

Erros:

| Status | Quando ocorre |
|---|---|
| `403` | Utilizador nao e autor nem moderador global; ou `USER` tenta tornar topico privado. |
| `404` | Topico inexistente. |
| `422` | Campos invalidos, categoria/tag inexistente, `status`/`visibility` fora dos valores permitidos. |

## DELETE `http://127.0.0.1:8000/api/forum/topics/{id}`

Auth: sim.

Quem pode usar: owner/autor ou moderador global.

Body: nenhum.

Sucesso `200`:

```json
{ "message": "Topico removido." }
```

Erros:

| Status | Quando ocorre |
|---|---|
| `403` | Sem permissao para apagar. |
| `404` | Topico inexistente. |
| `422` | Nao esperado. |

## POST `http://127.0.0.1:8000/api/forum/topics/{id}/bookmark`

Auth: sim.

Quem pode usar: utilizador autenticado com acesso ao topico.

Body: nenhum.

Sucesso `200`:

```json
{ "bookmarked": true }
```

Ao chamar novamente:

```json
{ "bookmarked": false }
```

Erros:

| Status | Quando ocorre |
|---|---|
| `403` | Sem acesso ao topico privado. |
| `404` | Topico inexistente. |
| `422` | Nao esperado. |

# Interacao

## POST `http://127.0.0.1:8000/api/forum/topics/{id}/like`

Auth: sim.

Quem pode usar: utilizador autenticado com acesso ao topico.

Body: nenhum.

Sucesso `200`:

```json
{ "liked": true, "likes_count": 6 }
```

Ao chamar novamente:

```json
{ "liked": false, "likes_count": 5 }
```

Erros: `403` sem acesso; `404` topico inexistente; `422` nao esperado.

## POST `http://127.0.0.1:8000/api/forum/topics/{id}/comments`

Auth: sim.

Quem pode usar: utilizador autenticado com acesso ao topico. Topico nao pode estar `is_read_only=true`, `CLOSED` ou `ARCHIVED`.

Body com todos os campos possiveis:

```json
{
  "text": "Comentario ou resposta",
  "parent_id": null
}
```

Para resposta, enviar `parent_id` de comentario do mesmo topico.

Sucesso `201`:

```json
{
  "id": 10,
  "author_id": 12,
  "text": "Comentario ou resposta",
  "forum_topic_id": 1,
  "parent_id": null,
  "created_at": "2026-06-17T10:00:00.000000Z",
  "updated_at": "2026-06-17T10:00:00.000000Z",
  "author": {
    "id": 12,
    "name": "Nome Completo",
    "email": "email@exemplo.com",
    "display_role": "Membro",
    "roles": [{ "role": "USER" }]
  }
}
```

Erros:

| Status | Quando ocorre |
|---|---|
| `403` | Sem acesso; topico em modo apenas leitura. |
| `404` | Topico inexistente. |
| `422` | `text` ausente; `parent_id` nao pertence ao topico; topico `CLOSED`/`ARCHIVED`. |

## POST `http://127.0.0.1:8000/api/forum/comments/{id}/like`

Auth: sim.

Quem pode usar: utilizador autenticado com acesso ao topico do comentario.

Body: nenhum.

Sucesso `200`:

```json
{ "liked": true, "likes_count": 3 }
```

Erros: `403` sem acesso ao topico; `404` comentario inexistente; `422` nao esperado.

# Acesso a Topicos Privados

## POST `http://127.0.0.1:8000/api/forum/topics/{id}/request-access`

Auth: sim.

Quem pode usar: utilizador autenticado sem acesso a topico privado.

Body com todos os campos possiveis:

```json
{ "message": "Gostaria de participar neste grupo." }
```

Sucesso `201`:

```json
{
  "id": 7,
  "forum_topic_id": 1,
  "user_id": 12,
  "message": "Gostaria de participar neste grupo.",
  "invite_type": "REQUESTED",
  "status": "PENDING",
  "reviewed_by": null,
  "reviewed_at": null,
  "created_at": "2026-06-17T10:00:00.000000Z",
  "updated_at": "2026-06-17T10:00:00.000000Z",
  "user": { "id": 12, "name": "Nome Completo", "email": "email@exemplo.com" }
}
```

Erros: `409` ja tem acesso; `422` topico publico ou message maior que 1000; `404` topico inexistente.

## POST `http://127.0.0.1:8000/api/forum/topics/{id}/join-with-code`

Auth: sim.

Quem pode usar: qualquer utilizador autenticado com codigo valido.

Body:

```json
{ "join_code": "A7K2P9" }
```

Sucesso `200`:

```json
{
  "id": 5,
  "forum_topic_id": 1,
  "user_id": 12,
  "role": "MEMBER",
  "joined_at": "2026-06-17T10:00:00.000000Z",
  "created_at": "2026-06-17T10:00:00.000000Z",
  "updated_at": "2026-06-17T10:00:00.000000Z",
  "user": { "id": 12, "name": "Nome Completo", "email": "email@exemplo.com" }
}
```

Erros: `422` codigo ausente/invalido ou topico nao privado; `404` topico inexistente.

## GET `http://127.0.0.1:8000/api/forum/topics/{id}/access-requests`

Auth: sim.

Quem pode usar: owner ou moderador local do topico (`topic_members.role=OWNER|MODERATOR`).

Body: nenhum.

Sucesso `200`:

```json
{
  "data": [
    {
      "id": 7,
      "forum_topic_id": 1,
      "user_id": 12,
      "message": "Gostaria de participar neste grupo.",
      "invite_type": "REQUESTED",
      "status": "PENDING",
      "reviewed_by": null,
      "reviewed_at": null,
      "user": { "id": 12, "name": "Nome Completo", "roles": [{ "role": "USER" }] }
    }
  ],
  "current_page": 1,
  "per_page": 20,
  "total": 1
}
```

Erros: `403` sem permissao para gerir pedidos; `404` topico inexistente; `422` nao esperado.

## PATCH `http://127.0.0.1:8000/api/forum/topics/{id}/access-requests/{request_id}/approve`

Auth: sim.

Quem pode usar: owner ou moderador local.

Body: nenhum.

Sucesso `200`:

```json
{
  "id": 7,
  "forum_topic_id": 1,
  "user_id": 12,
  "message": "Gostaria de participar neste grupo.",
  "invite_type": "REQUESTED",
  "status": "APPROVED",
  "reviewed_by": 2,
  "reviewed_at": "2026-06-17T10:05:00.000000Z",
  "user": { "id": 12, "name": "Nome Completo" },
  "reviewer": { "id": 2, "name": "Norberto" }
}
```

Erros: `403` sem permissao; `404` topico ou pedido inexistente; `422` nao esperado.

## PATCH `http://127.0.0.1:8000/api/forum/topics/{id}/access-requests/{request_id}/reject`

Auth: sim.

Quem pode usar: owner ou moderador local.

Body: nenhum.

Sucesso `200`:

```json
{
  "id": 7,
  "forum_topic_id": 1,
  "user_id": 12,
  "status": "REJECTED",
  "reviewed_by": 2,
  "reviewed_at": "2026-06-17T10:05:00.000000Z",
  "user": { "id": 12, "name": "Nome Completo" },
  "reviewer": { "id": 2, "name": "Norberto" }
}
```

Erros: `403` sem permissao; `404` topico ou pedido inexistente; `422` nao esperado.

## GET `http://127.0.0.1:8000/api/forum/topics/{id}/invite-link`

Auth: sim.

Quem pode usar: owner ou moderador local de topico privado.

Body: nenhum.

Sucesso `200`:

```json
{
  "invite_link": "http://127.0.0.1:8000/api/forum/join/A7K2P9",
  "join_code": "A7K2P9"
}
```

Erros: `403` sem permissao; `404` topico inexistente; `422` topico e publico.

## POST `http://127.0.0.1:8000/api/forum/topics/{id}/invite`

Auth: sim.

Quem pode usar: owner ou moderador local de topico privado.

Body:

```json
{ "user_ids": [12, 13, 14] }
```

Sucesso `201`:

```json
{
  "message": "Convites processados.",
  "results": [
    { "user_id": 12, "status": "invited" },
    { "user_id": 13, "status": "already_member" },
    { "user_id": 14, "status": "already_invited" }
  ]
}
```

Erros: `403` sem permissao; `404` topico inexistente; `422` topico publico, `user_ids` ausente/vazio ou ID inexistente.

## GET `http://127.0.0.1:8000/api/forum/join/{code}`

Auth: opcional.

Quem pode usar: qualquer pessoa com link/codigo.

Body: nenhum.

Sucesso `200` sem token:

```json
{
  "requires_auth": true,
  "join_code": "A7K2P9",
  "topic_title": "Topico privado"
}
```

Sucesso `200` com token:

```json
{
  "message": "Entraste no topico com sucesso.",
  "topic_id": 1,
  "member": {
    "id": 5,
    "forum_topic_id": 1,
    "user_id": 12,
    "role": "MEMBER",
    "joined_at": "2026-06-17T10:00:00.000000Z",
    "user": { "id": 12, "name": "Nome Completo" }
  }
}
```

Se ja tiver acesso:

```json
{ "message": "Ja tens acesso a este topico.", "topic_id": 1 }
```

Erros: `404` codigo invalido ou expirado; `403` nao esperado; `422` nao esperado.

## POST `http://127.0.0.1:8000/api/forum/invites/{id}/accept`

Auth: sim.

Quem pode usar: apenas o utilizador convidado, quando o convite esta `PENDING` e `invite_type=INVITED`.

Body: nenhum.

Sucesso `200`:

```json
{
  "message": "Convite aceite. Es agora membro do topico.",
  "topic_id": 1
}
```

Erros: `404` convite inexistente, ja revisto, nao pertence ao utilizador ou nao e convite directo; `403` nao esperado; `422` nao esperado.

## POST `http://127.0.0.1:8000/api/forum/invites/{id}/reject`

Auth: sim.

Quem pode usar: apenas o utilizador convidado, quando o convite esta `PENDING` e `invite_type=INVITED`.

Body: nenhum.

Sucesso `200`:

```json
{ "message": "Convite rejeitado." }
```

Erros: `404` convite inexistente, ja revisto, nao pertence ao utilizador ou nao e convite directo; `403` nao esperado; `422` nao esperado.

# Auxiliares

## GET `http://127.0.0.1:8000/api/users/network?topic_id={id}`

Auth: sim.

Quem pode usar: qualquer utilizador autenticado. Usado para escolher pessoas para convite.

Body: nenhum.

Sucesso `200`:

```json
{
  "data": [
    {
      "id": 13,
      "name": "Oldemar",
      "email": "oldemar@example.com",
      "avatar_url": null,
      "is_member": false
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 20,
    "total": 1
  }
}
```

Erros: `403` nao esperado; `404` nao esperado; `422` nao esperado.

## GET `http://127.0.0.1:8000/api/tags?search=`

Auth: nao.

Quem pode usar: qualquer cliente. Usado para autocomplete de hashtags.

Body: nenhum.

Sucesso `200`:

```json
[
  { "id": 1, "name": "historia", "usage_count": 8 },
  { "id": 2, "name": "historia-oral", "usage_count": 3 }
]
```

Sem resultados:

```json
[]
```

Erros: `403`, `404`, `422` nao esperados.

# Admin Forum

## PUT `http://127.0.0.1:8000/api/admin/forum/topics/{id}/toggle-pin`

Auth: sim.

Quem pode usar: `ADMIN`/`SUPER_ADMIN` via middleware admin.

Body: nenhum.

Sucesso `200`:

```json
{
  "message": "Topico fixado com sucesso.",
  "is_pinned": true
}
```

Ao chamar novamente:

```json
{
  "message": "Topico desafixado com sucesso.",
  "is_pinned": false
}
```

Erros:

| Status | Quando ocorre |
|---|---|
| `403` | Utilizador nao e admin. |
| `404` | Topico inexistente. |
| `422` | Nao esperado. |
