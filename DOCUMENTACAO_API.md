# Documentacao Completa da API - EH Angola

Base URL local: `http://127.0.0.1:8000/api`

Para rotas autenticadas enviar sempre:

```http
Authorization: Bearer {token}
Accept: application/json
```

Erros comuns:

```json
{ "message": "Unauthenticated." }
```

```json
{
  "message": "The given data was invalid.",
  "errors": { "campo": ["Mensagem de validacao."] }
}
```

## Regras de Negocio

- `display_role` e o valor que deve aparecer no frontend: `USER` -> `Membro`, `AUTHOR` -> `Escritor`, `ADMIN`/`SUPER_ADMIN` -> `Moderador`. No forum, usar sempre `display_role`; nao mostrar o role real.
- Topico privado (`visibility: "PRIVATE"`) so pode ser criado por utilizadores com role `AUTHOR`, `ADMIN` ou `SUPER_ADMIN`. `USER` recebe `403`.
- `join_code` tem 6 caracteres alfanumericos maiusculos, exemplo `A7K2P9`. E gerado automaticamente pelo sistema; o utilizador nunca o define manualmente.
- `visibility` indica se o topico e `PUBLIC` ou `PRIVATE`. `has_access` indica se o utilizador autenticado pode ver o conteudo completo de um topico privado.
- Na listagem, o `body` de topicos privados aparece como preview/resumo mesmo quando `has_access=false`. No detalhe, quando `has_access=false`, `body=null` e `comments=null`.
- `has_access=true` quando o utilizador e autor do topico ou esta em `topic_members`. Nao depende do role global.
- Fluxo privado:
  - Codigo: `POST /forum/topics/{id}/join-with-code` entra directamente se o codigo estiver correcto.
  - Link: `GET /forum/join/{code}` entra directamente se houver token; sem token retorna `requires_auth=true`.
  - Convite directo: owner/moderador local chama `POST /forum/topics/{id}/invite`; convidado aceita/rejeita com `/forum/invites/{id}/accept|reject`.
  - Pedido de acesso: utilizador chama `POST /forum/topics/{id}/request-access`; owner/moderador local aprova/rejeita.

## Autenticacao

### POST `http://127.0.0.1:8000/api/register`

Auth: nao.

Body:

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

Campos obrigatorios: `name`, `email`, `password`, `password_confirmation`, `profession` (`ESTUDANTE|PROFESSOR|OUTRO`), `accepted_terms` (`true`).

Sucesso `201`:

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

Erros: `422` se email ja existe, password nao confirma, `profession` invalida ou termos nao aceites.

Notas recentes: o registo ja nao envia codigo de verificacao por email. Envia email de boas-vindas informativo, sem codigo. Se o envio falhar, o registo nao bloqueia; o erro e registado internamente. `email_verified` fica `false` no registo normal e nao bloqueia a app.

### POST `http://127.0.0.1:8000/api/login`

Auth: nao.

Body:

```json
{ "email": "email@exemplo.com", "password": "password123" }
```

Sucesso `200`:

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

Erros: `422` credenciais invalidas; `403` conta desactivada.

### POST `http://127.0.0.1:8000/api/logout`

Auth: sim.

Body: nenhum.

Sucesso `200`:

```json
{ "message": "Sessao terminada." }
```

Erros: `401` sem token valido.

### GET `http://127.0.0.1:8000/api/me`

Auth: sim.

Body: nenhum.

Sucesso `200`:

```json
{
  "id": 12,
  "name": "Nome Completo",
  "email": "email@exemplo.com",
  "profession": "ESTUDANTE",
  "accepted_terms": true,
  "email_verified": false,
  "roles": [{ "id": 44, "user_id": 12, "role": "USER" }]
}
```

Erros: `401` sem token valido.

### GET `http://127.0.0.1:8000/api/auth/google`

Auth: nao.

Sucesso `200`:

```json
{ "url": "https://accounts.google.com/o/oauth2/v2/auth?..." }
```

Fluxo: frontend abre a `url`; Google redirecciona para `GET /api/auth/google/callback?code=...`; backend cria/actualiza utilizador, marca `email_verified=true` e retorna token.

Erros: `422` se callback vier com `error` ou sem `code`.

### GET `http://127.0.0.1:8000/api/auth/google/callback`

Auth: nao.

Sucesso `200`:

```json
{
  "user": {
    "id": 15,
    "name": "Google User",
    "email": "google@example.com",
    "avatar_url": "https://lh3.googleusercontent.com/...",
    "email_verified": true,
    "roles": [{ "role": "USER" }]
  },
  "token": "2|plain-text-token"
}
```

### POST `http://127.0.0.1:8000/api/forgot-password`

Auth: nao.

Body:

```json
{ "email": "email@exemplo.com" }
```

Sucesso `200`:

```json
{ "message": "Codigo de recuperacao enviado com sucesso." }
```

Erros: `422` email inexistente/invalido; `500` falha no envio do email. Este fluxo ainda usa codigo por email.

### POST `http://127.0.0.1:8000/api/reset-password`

Auth: nao.

Body:

```json
{
  "email": "email@exemplo.com",
  "code": "123456",
  "password": "novaPassword123",
  "password_confirmation": "novaPassword123"
}
```

Sucesso `200`:

```json
{ "message": "Password redefinida com sucesso." }
```

Erros: `422` codigo invalido/expirado, password invalida ou email inexistente.

## Forum

Modelo de topico usado nos exemplos:

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
    "profession": "ESTUDANTE",
    "display_role": "Membro",
    "roles": [{ "role": "USER" }]
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

### GET `http://127.0.0.1:8000/api/forum/topics`

Auth: opcional. Com token, inclui privados onde o utilizador tem acesso.

Query params: `category`, `category_id`, `visibility=PUBLIC|PRIVATE`, `filter=trending|recent|most_commented|relevant|for-you`, `search`, `comments_sort=recent|popular|all`, `status`, `per_page`.

Sucesso:

```json
{
  "data": [{ "id": 1, "title": "Como preservar arquivos historicos?", "body": "Texto completo ou preview do topico...", "visibility": "PUBLIC", "has_access": true }],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 1,
    "category_counts": [{ "id": 3, "name": "Historia", "topics_count": 8 }]
  }
}
```

Erros: normalmente nenhum `403`; `422` se parametros forem tratados por validacao futura.

### GET `http://127.0.0.1:8000/api/forum/topics/{id}`

Auth: opcional. Necessario para ver corpo/comentarios de privados.

Sucesso:

```json
{
  "id": 1,
  "title": "Como preservar arquivos historicos?",
  "body": "Texto completo do topico",
  "visibility": "PRIVATE",
  "has_access": true,
  "comments": [
    {
      "id": 10,
      "forum_topic_id": 1,
      "author_id": 13,
      "text": "Boa pergunta.",
      "likes_count": 2,
      "author": { "id": 13, "name": "Oldemar", "display_role": "Membro" },
      "replies": []
    }
  ],
  "related_topics": []
}
```

Sem acesso a privado:

```json
{ "id": 1, "body": null, "visibility": "PRIVATE", "has_access": false, "comments": null }
```

Erros: `404` topico inexistente.

### POST `http://127.0.0.1:8000/api/forum/topics`

Auth: sim. `USER` so pode criar `PUBLIC`; `AUTHOR`, `ADMIN`, `SUPER_ADMIN` podem criar `PRIVATE`.

Body:

```json
{
  "title": "Novo topico",
  "body": "Texto do topico",
  "category_id": 3,
  "visibility": "PUBLIC",
  "is_read_only": false,
  "cover_image_url": "https://res.cloudinary.com/demo/image/upload/forum/capa.jpg",
  "tags": ["historia", "arquivo"],
  "tag_ids": [1, 2],
  "status": "OPEN",
  "is_pinned": false
}
```

Sucesso `201`: retorna o modelo completo do topico.

Erros: `403` `USER` tentou criar `PRIVATE`; `422` campos obrigatorios/invalidos; `404` nao aplicavel.

### PUT `http://127.0.0.1:8000/api/forum/topics/{id}`

Auth: sim. Autor ou moderador global (`MODERATOR`, `ADMIN`, `SUPER_ADMIN`).

Body: mesmos campos do create, todos opcionais.

Sucesso: retorna o modelo completo actualizado.

Erros: `403` sem permissao ou `USER` tenta converter para `PRIVATE`; `404` topico inexistente; `422` dados invalidos.

### DELETE `http://127.0.0.1:8000/api/forum/topics/{id}`

Auth: sim. Autor ou moderador global.

Sucesso:

```json
{ "message": "Topico removido." }
```

Erros: `403` sem permissao; `404` topico inexistente.

### GET `http://127.0.0.1:8000/api/forum/featured`

Auth: opcional.

Sucesso:

```json
{ "data": [{ "id": 1, "title": "Topico em destaque", "is_pinned": true, "has_access": true }] }
```

Erros: normalmente nenhum.

### GET `http://127.0.0.1:8000/api/forum/my-topics`

Auth: sim.

Sucesso:

```json
{ "data": [{ "id": 1, "title": "Meu topico" }], "meta": { "current_page": 1, "last_page": 1, "per_page": 15, "total": 1 } }
```

Erros: `401` sem token.

### GET `http://127.0.0.1:8000/api/forum/bookmarks`

Auth: sim.

Sucesso:

```json
{ "data": [{ "id": 1, "title": "Guardado" }], "meta": { "current_page": 1, "last_page": 1, "per_page": 15, "total": 1 } }
```

### POST `http://127.0.0.1:8000/api/forum/topics/{id}/bookmark`

Auth: sim. Precisa ter acesso ao topico.

Sucesso:

```json
{ "bookmarked": true }
```

ou

```json
{ "bookmarked": false }
```

Erros: `403` sem acesso; `404` topico inexistente.

### POST `http://127.0.0.1:8000/api/forum/topics/{id}/like`

Auth: sim. Precisa ter acesso ao topico.

Sucesso:

```json
{ "liked": true, "likes_count": 6 }
```

Erros: `403` sem acesso; `404` topico inexistente.

### POST `http://127.0.0.1:8000/api/forum/topics/{id}/comments`

Auth: sim. Precisa ter acesso e topico nao pode estar read-only, closed ou archived.

Body:

```json
{ "text": "Comentario", "parent_id": null }
```

Sucesso `201`:

```json
{
  "id": 10,
  "author_id": 12,
  "text": "Comentario",
  "forum_topic_id": 1,
  "parent_id": null,
  "author": { "id": 12, "name": "Nome", "display_role": "Membro" }
}
```

Erros: `403` sem acesso ou read-only; `404` topico inexistente; `422` texto ausente, `parent_id` invalido ou topico fechado/arquivado.

### POST `http://127.0.0.1:8000/api/forum/comments/{id}/like`

Auth: sim. Precisa ter acesso ao topico do comentario.

Sucesso:

```json
{ "liked": true, "likes_count": 3 }
```

Erros: `403` sem acesso; `404` comentario inexistente.

### POST `http://127.0.0.1:8000/api/forum/topics/{id}/request-access`

Auth: sim. Para topicos privados onde o utilizador ainda nao tem acesso.

Body:

```json
{ "message": "Gostaria de participar." }
```

Sucesso `201`:

```json
{
  "id": 7,
  "forum_topic_id": 1,
  "user_id": 12,
  "message": "Gostaria de participar.",
  "invite_type": "REQUESTED",
  "status": "PENDING",
  "reviewed_by": null,
  "reviewed_at": null,
  "user": { "id": 12, "name": "Nome Completo" }
}
```

Erros: `422` topico publico ou message invalida; `409` ja tem acesso; `404` topico inexistente.

### POST `http://127.0.0.1:8000/api/forum/topics/{id}/join-with-code`

Auth: sim.

Body:

```json
{ "join_code": "A7K2P9" }
```

Sucesso:

```json
{ "id": 5, "forum_topic_id": 1, "user_id": 12, "role": "MEMBER", "joined_at": "2026-06-17T10:00:00.000000Z", "user": { "id": 12, "name": "Nome" } }
```

Erros: `422` codigo ausente/invalido ou topico nao privado; `404` topico inexistente.

### GET `http://127.0.0.1:8000/api/forum/topics/{id}/access-requests`

Auth: sim. Owner ou moderador local do topico.

Sucesso:

```json
{ "data": [{ "id": 7, "status": "PENDING", "invite_type": "REQUESTED", "user": { "id": 12, "name": "Nome" } }], "current_page": 1, "total": 1 }
```

Erros: `403` sem permissao; `404` topico inexistente.

### PATCH `http://127.0.0.1:8000/api/forum/topics/{id}/access-requests/{request_id}/approve`

Auth: sim. Owner ou moderador local.

Body: nenhum.

Sucesso:

```json
{ "id": 7, "forum_topic_id": 1, "user_id": 12, "status": "APPROVED", "reviewed_by": 2, "user": { "id": 12, "name": "Nome" } }
```

Erros: `403` sem permissao; `404` topico/pedido inexistente.

### PATCH `http://127.0.0.1:8000/api/forum/topics/{id}/access-requests/{request_id}/reject`

Auth: sim. Owner ou moderador local.

Sucesso:

```json
{ "id": 7, "forum_topic_id": 1, "user_id": 12, "status": "REJECTED", "reviewed_by": 2 }
```

Erros: `403` sem permissao; `404` topico/pedido inexistente.

### GET `http://127.0.0.1:8000/api/forum/topics/{id}/invite-link`

Auth: sim. Owner ou moderador local de topico privado.

Sucesso:

```json
{ "invite_link": "http://127.0.0.1:8000/api/forum/join/A7K2P9", "join_code": "A7K2P9" }
```

Erros: `403` sem permissao; `404` topico inexistente; `422` topico publico.

### POST `http://127.0.0.1:8000/api/forum/topics/{id}/invite`

Auth: sim. Owner ou moderador local.

Body:

```json
{ "user_ids": [12, 13] }
```

Sucesso `201`:

```json
{ "message": "Convites processados.", "results": [{ "user_id": 12, "status": "invited" }, { "user_id": 13, "status": "already_member" }] }
```

Erros: `403` sem permissao; `404` topico inexistente; `422` topico publico ou `user_ids` invalido.

### GET `http://127.0.0.1:8000/api/forum/join/{code}`

Auth: opcional. Com token entra no topico; sem token informa que precisa autenticar.

Sucesso sem token:

```json
{ "requires_auth": true, "join_code": "A7K2P9", "topic_title": "Topico privado" }
```

Sucesso com token:

```json
{ "message": "Entraste no topico com sucesso.", "topic_id": 1, "member": { "id": 5, "forum_topic_id": 1, "user_id": 12, "role": "MEMBER" } }
```

Erros: `404` codigo invalido/expirado.

### POST `http://127.0.0.1:8000/api/forum/invites/{id}/accept`

Auth: sim. Apenas o convidado do convite pendente.

Sucesso:

```json
{ "message": "Convite aceite. Es agora membro do topico.", "topic_id": 1 }
```

Erros: `404` convite inexistente, nao pendente ou nao pertence ao utilizador.

### POST `http://127.0.0.1:8000/api/forum/invites/{id}/reject`

Auth: sim. Apenas o convidado do convite pendente.

Sucesso:

```json
{ "message": "Convite rejeitado." }
```

Erros: `404` convite inexistente, nao pendente ou nao pertence ao utilizador.

### GET `http://127.0.0.1:8000/api/users/network?topic_id={id}`

Auth: sim.

Sucesso:

```json
{
  "data": [{ "id": 13, "name": "Oldemar", "email": "oldemar@example.com", "avatar_url": null, "is_member": false }],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 20, "total": 1 }
}
```

Erros: `401` sem token.

### GET `http://127.0.0.1:8000/api/tags?search=hist`

Auth: nao.

Sucesso:

```json
[{ "id": 1, "name": "historia", "usage_count": 8 }]
```

Erros: normalmente nenhum. Se nao encontrar, retorna `[]`.

## Notificacoes

### GET `http://127.0.0.1:8000/api/notifications`

Auth: sim.

Sucesso:

```json
{
  "data": [{ "id": 1, "recipient_id": 12, "type": "FORUM_INVITE", "message": "Foste convidado...", "is_read": false, "reference_id": 7, "reference_type": "topic_access_request" }],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 20, "total": 1, "unread_count": 1 }
}
```

Erros: `401` sem token.

### PUT `http://127.0.0.1:8000/api/notifications/{id}/read`

Auth: sim.

Sucesso:

```json
{ "message": "Notificacao marcada como lida." }
```

Erros: `404` notificacao inexistente ou de outro utilizador.

### PUT `http://127.0.0.1:8000/api/notifications/read-all`

Auth: sim.

Sucesso:

```json
{ "message": "Todas as notificacoes marcadas como lidas." }
```

### Types possiveis

- `ROLE_PROMOTED`: utilizador foi promovido para novo role.
- `QUIZ_APPROVED`: quiz do utilizador foi aprovado.
- `QUIZ_REJECTED`: quiz do utilizador foi rejeitado.
- `NEW_CONTENT`: novo conteudo publicado por alguem seguido.
- `FOLLOW_NEW`: novo seguidor/subscritor.
- `FORUM_NEW_COMMENT`: novo comentario num topico do utilizador.
- `FORUM_COMMENT_REPLY`: resposta a um comentario.
- `FORUM_TOPIC_LIKE`: like recebido num topico.
- `FORUM_COMMENT_LIKE`: like recebido num comentario.
- `FORUM_ACCESS_REQUEST`: pedido de acesso a topico privado.
- `FORUM_ACCESS_APPROVED`: pedido de acesso aprovado.
- `FORUM_ACCESS_REJECTED`: pedido de acesso rejeitado.
- `FORUM_INVITE`: convite directo para topico privado.
- `FORUM_INVITE_ACCEPTED`: convidado aceitou convite.
- `FORUM_TOPIC_CLOSED`: topico fechado.
- `FORUM_TOPIC_ARCHIVED`: topico arquivado.
- `FORUM_TOPIC_NOW_PRIVATE`: topico publico passou a privado.

## Upload

### POST `http://127.0.0.1:8000/api/upload/image`

Auth: sim.

Body: `multipart/form-data`, campo `file`.

Sucesso:

```json
{ "url": "https://res.cloudinary.com/demo/image/upload/eh-angola/images/abc.jpg", "public_id": "eh-angola/images/abc" }
```

Erros: `422` ficheiro ausente, nao e imagem ou maior que 5MB.

## Admin

Todas as rotas admin exigem token e middleware `admin`.

### GET `http://127.0.0.1:8000/api/admin/users`

Sucesso:

```json
{ "data": [{ "id": 12, "name": "Nome", "email": "email@exemplo.com", "roles": [{ "role": "USER" }] }], "current_page": 1, "total": 1 }
```

Erros: `403` sem role admin.

### POST `http://127.0.0.1:8000/api/admin/users/{id}/promote`

Body:

```json
{ "role": "AUTHOR" }
```

Sucesso:

```json
{ "message": "Utilizador promovido com sucesso." }
```

Erros: `403` ADMIN tentou atribuir `ADMIN`/`SUPER_ADMIN`; `404` utilizador inexistente; `409` utilizador ja tem role; `422` role invalido.

### PUT `http://127.0.0.1:8000/api/admin/forum/topics/{id}/toggle-pin`

Sucesso:

```json
{ "message": "Topico fixado com sucesso.", "is_pinned": true }
```

Erros: `403` sem admin; `404` topico inexistente.

### GET `http://127.0.0.1:8000/api/admin/reports`

Sucesso:

```json
{ "data": [{ "id": 1, "reported_by": 12, "reason": "spam", "status": "PENDING", "forum_topic": { "id": 1, "title": "Topico" } }], "current_page": 1, "total": 1 }
```

Erros: `403` sem admin.

### PUT `http://127.0.0.1:8000/api/admin/reports/{id}/resolve`

Sucesso:

```json
{ "message": "Denuncia resolvida." }
```

Erros: `403` sem admin; `404` denuncia inexistente.

## Categorias e Tags

### GET `http://127.0.0.1:8000/api/categories`

Auth: nao.

Sucesso:

```json
[{ "id": 1, "name": "Historia", "description": "Historia de Angola" }]
```

### GET `http://127.0.0.1:8000/api/tags`

Auth: nao.

Query opcional: `search=texto`, `trending=true`.

Sucesso:

```json
[{ "id": 1, "name": "historia", "usage_count": 8 }]
```

Erros: normalmente nenhum.
