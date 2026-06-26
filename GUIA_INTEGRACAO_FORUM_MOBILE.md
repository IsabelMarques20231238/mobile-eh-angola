# Guia de Integração — Módulo Fórum (Mobile)
> Backend: Laravel 12 · Base URL: `https://<domínio>/api`  
> Versão: 2026-06-25 · Cobre **tudo** o que foi implementado e corrigido.

---

## Índice
1. [Autenticação](#1-autenticação)
2. [Tópicos do Fórum](#2-tópicos-do-fórum)
3. [Tópicos Privados — Acesso, Código, Convites](#3-tópicos-privados)
4. [Comentários e Replies (Flat Threading)](#4-comentários-e-replies)
5. [Likes](#5-likes)
6. [Bookmarks](#6-bookmarks)
7. [Notificações — Todos os Tipos e Navegação](#7-notificações)
8. [Pesquisa de Utilizadores para Convite](#8-pesquisa-de-utilizadores)
9. [Resumo de Bugs Corrigidos e o Que Mudou](#9-bugs-corrigidos)

---

## 1. Autenticação

Todas as rotas autenticadas exigem o header:
```
Authorization: Bearer {token}
```

---

## 2. Tópicos do Fórum

### 2.1 Listar tópicos
```
GET /forum/topics
GET /forum/topics?filter=publicos
GET /forum/topics?filter=privados
GET /forum/topics?filter=meus
GET /forum/topics?category_id=3
GET /forum/topics?q=angola
GET /forum/topics?tag=política
```

**Resposta:**
```json
{
  "data": [
    {
      "id": 5,
      "title": "Angola em Foco",
      "body": "Texto do tópico...",
      "visibility": "PUBLIC",
      "status": "OPEN",
      "is_pinned": false,
      "is_read_only": false,
      "likes_count": 12,
      "comments_count": 8,
      "participants_count": 3,
      "has_access": true,
      "is_liked": false,
      "is_bookmarked": false,
      "author": {
        "id": 1,
        "name": "Isabel",
        "display_role": "Autora"
      },
      "category": { "id": 2, "name": "Política" },
      "tags": [{ "id": 1, "name": "angola" }]
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 15,
    "total": 42,
    "category_counts": [
      { "category_id": 2, "name": "Política", "topics_count": 12 }
    ]
  }
}
```

> **Regra `has_access` vs `body`:**
> - Tópico público → `has_access: true`, `body` sempre visível
> - Tópico privado sem acesso → `has_access: false`, `body` visível na listagem (preview), `comments: null`
> - Tópico privado com acesso → `has_access: true`, tudo visível

---

### 2.2 Ver tópico individual
```
GET /forum/topics/{id}
```
Resposta igual ao item da listagem mas com `comments` incluídos (array).

---

### 2.3 Criar tópico
```
POST /forum/topics
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "Título do tópico",
  "body": "Corpo do tópico",
  "category_id": 2,
  "visibility": "PUBLIC",      // "PUBLIC" | "PRIVATE"
  "tag_ids": [1, 3],           // opcional
  "join_code": "CODIGO123"     // opcional, só para PRIVATE
}
```

**Resposta 201:** payload completo do tópico (mesmo formato do `GET /forum/topics/{id}`)

---

### 2.4 Editar tópico
```
PUT /forum/topics/{id}
Authorization: Bearer {token}

{
  "title": "Novo título",
  "body": "Novo corpo",
  "is_read_only": true
}
```

**Permissões por campo:**

| Campo | Dono | Moderador/Admin |
|---|---|---|
| `title`, `body`, `tag_ids` | ✅ | ✅ |
| `is_read_only` | ✅ | ✅ |
| `status` (OPEN/CLOSED/ARCHIVED) | ❌ | ✅ |
| `is_pinned` | ❌ | ✅ |

> **Dono pode agora ligar/desligar `is_read_only`.** Antes estava bloqueado — foi corrigido.

---

### 2.5 Apagar tópico
```
DELETE /forum/topics/{id}
Authorization: Bearer {token}
```

---

### 2.6 Tópicos em destaque
```
GET /forum/featured
```

---

### 2.7 Meus tópicos
```
GET /forum/my-topics
Authorization: Bearer {token}
```

---

## 3. Tópicos Privados

### 3.1 Pedir acesso
```
POST /forum/topics/{id}/request-access
Authorization: Bearer {token}

{
  "message": "Quero participar"    // opcional
}
```
**Resposta 201.** Notifica o dono com `FORUM_ACCESS_REQUEST`.

---

### 3.2 Entrar por código (POST autenticado)
```
POST /forum/topics/{id}/join-with-code
Authorization: Bearer {token}

{
  "join_code": "CODIGO123"
}
```
**Resposta 200:** `{ "role": "MEMBER", "joined_at": "...", "user": {...} }`

> Notifica o dono com `FORUM_JOIN_BY_CODE` (novo).

---

### 3.3 Entrar por link (GET público)
```
GET /forum/join/{code}
```

**Caso 1 — utilizador não autenticado:**
```json
{
  "requires_auth": true,
  "join_code": "CODIGO123",
  "topic_title": "Angola em Foco"
}
```
→ Redireciona para login, depois volta ao mesmo URL.

**Caso 2 — utilizador autenticado, acesso concedido:**
```json
{
  "message": "Acesso concedido.",
  "topic_id": 5,
  "topic": { /* payload completo */ }
}
```
→ Navega directamente para o tópico.

**Caso 3 — já tem acesso:**
```json
{
  "message": "Já tens acesso a este tópico.",
  "topic_id": 5
}
```

> Também notifica o dono com `FORUM_JOIN_BY_CODE` (apenas na primeira entrada).

---

### 3.4 Obter link de convite
```
GET /forum/topics/{id}/invite-link
Authorization: Bearer {token}

Resposta:
{
  "invite_link": "https://ehangola.com/forum/join/CODIGO123",
  "join_code": "CODIGO123"
}
```

---

### 3.5 Regenerar código
```
POST /forum/topics/{id}/regenerate-code
Authorization: Bearer {token}
```

---

### 3.6 Convidar utilizadores por ID
```
POST /forum/topics/{id}/invite
Authorization: Bearer {token}

{
  "user_ids": [10, 11, 12]
}
```

**Resposta 201:**
```json
{
  "message": "Convites processados.",
  "results": [
    { "user_id": 10, "status": "invited" },
    { "user_id": 11, "status": "already_member" },
    { "user_id": 12, "status": "already_invited" }
  ]
}
```

Cada utilizador convidado recebe:
- Notificação in-app `FORUM_INVITE`
- Email de convite com link directo

---

### 3.7 Aceitar convite — ⚠️ BUG MAIS PROVÁVEL DO ERRO NO MOBILE

```
POST /forum/invites/{access_request_id}/accept
Authorization: Bearer {token}
```

**Resposta 200:**
```json
{
  "message": "Convite aceite. És agora membro do tópico.",
  "topic_id": 5,
  "topic": { /* payload completo */ }
}
```

### 3.8 Rejeitar convite
```
POST /forum/invites/{access_request_id}/reject
Authorization: Bearer {token}
```

**Resposta 200:** `{ "message": "Convite rejeitado." }`

---

### ⚠️ COMO USAR O `reference_id` DO CONVITE

A notificação `FORUM_INVITE` é **diferente** de todas as outras notificações do fórum:

```
FORUM_INVITE → reference_type = "topic_access_request"
               reference_id   = ID do access_request (NÃO é o topic_id)
```

```
TODAS AS OUTRAS → reference_type = "forum_topic"
                  reference_id   = topic_id
```

**Código correcto no handler:**
```typescript
if (notification.type === 'FORUM_INVITE') {
  // reference_id aqui é o ACCESS REQUEST ID
  const accessRequestId = notification.reference_id;

  // Aceitar:
  await api.post(`/forum/invites/${accessRequestId}/accept`);

  // Rejeitar:
  await api.post(`/forum/invites/${accessRequestId}/reject`);

  // Depois de aceitar, ir para o tópico:
  router.push(`/forum/topics/${response.data.topic_id}`);
}
```

**Erro mais provável:** o frontend está a usar `reference_id` como `topic_id` e a chamar um endpoint errado (ex: `POST /forum/topics/{reference_id}/accept`), ou a chamar `/forum/invites/{topic_id}/accept` em vez de `/forum/invites/{access_request_id}/accept`.

---

### 3.9 Gerir pedidos de acesso (dono/admin)

```
GET  /forum/topics/{id}/access-requests     // listar pedidos
PATCH /forum/topics/{id}/access-requests/{requestId}/approve
PATCH /forum/topics/{id}/access-requests/{requestId}/reject
```

### 3.10 Listar membros
```
GET /forum/topics/{id}/members
Authorization: Bearer {token}
```

---

## 4. Comentários e Replies

### 4.1 Listar comentários
```
GET /forum/topics/{id}/comments
Authorization: Bearer {token}
```

**Estrutura de resposta (flat threading):**
```json
[
  {
    "id": 10,
    "text": "Bom ponto!",
    "parent_id": null,
    "mention_user": null,
    "likes_count": 3,
    "is_liked": false,
    "author": {
      "id": 1,
      "name": "Isabel",
      "display_role": "Autora"
    },
    "replies": [
      {
        "id": 11,
        "text": "@João concordo plenamente",
        "parent_id": 10,
        "mention_user": {
          "id": 2,
          "name": "João",
          "display_role": "Membro"
        },
        "likes_count": 1,
        "is_liked": true,
        "author": { ... }
      },
      {
        "id": 12,
        "text": "@Isabel tens razão",
        "parent_id": 10,          // ← parent_id é SEMPRE o comentário raiz
        "mention_user": {          // ← quem foi directamente respondido
          "id": 1,
          "name": "Isabel",
          "display_role": "Autora"
        },
        "likes_count": 0,
        "is_liked": false,
        "author": { ... }
      }
    ]
  }
]
```

---

### 4.2 Criar comentário ou reply

```
POST /forum/topics/{id}/comments
Authorization: Bearer {token}

{
  "text": "O meu comentário",
  "parent_id": 10    // omitir se for comentário raiz
}
```

**Regra de flat threading (IMPORTANTE):**

```
Comentário raiz (X):   parent_id = null
Reply ao X (A):        parent_id = X
Reply ao A (B):        parent_id = X  ← backend normaliza automaticamente
Reply ao B (C):        parent_id = X  ← backend normaliza automaticamente
```

O frontend pode sempre enviar o `id` do comentário a que está a responder — o backend resolve o pai raiz automaticamente.

**`mention_user` na resposta:**
```json
{
  "id": 12,
  "text": "texto",
  "parent_id": 10,
  "mention_user": {
    "id": 11,           // quem foi directamente respondido
    "name": "João",
    "display_role": "Membro"
  },
  "author": { ... }
}
```

> `mention_user` representa **quem foi respondido directamente** (ex: o utilizador clicou "Responder" no comentário de João → `mention_user = João`).  
> Usar para mostrar "@João" na UI antes do texto.

**Resposta 201:** payload completo do comentário criado (inclui `mention_user`, `author.display_role`).

---

### 4.3 Ver comentário por ID (para notificações)
```
GET /forum/comments/{id}
Authorization: Bearer {token}

Resposta:
{
  "id": 11,
  "forum_topic_id": 5,
  "parent_id": 10
}
```
→ Usar quando chega notificação `FORUM_NEW_COMMENT` para saber o `topic_id` antes de navegar.

---

### 4.4 Editar comentário
```
PUT /forum/comments/{id}
Authorization: Bearer {token}

{ "text": "texto editado" }
```

### 4.5 Apagar comentário
```
DELETE /forum/comments/{id}
Authorization: Bearer {token}
```

---

## 5. Likes

### 5.1 Like em tópico
```
POST /forum/topics/{id}/like
Authorization: Bearer {token}

Resposta:
{ "liked": true, "likes_count": 13 }
ou
{ "liked": false, "likes_count": 12 }
```

### 5.2 Like em comentário/reply
```
POST /forum/comments/{id}/like
Authorization: Bearer {token}

Resposta:
{ "liked": true, "likes_count": 4 }
```

---

### ⚠️ OPTIMISTIC UPDATE — Regra Obrigatória

O backend retorna sempre o estado **real** após a operação. O frontend **não deve** calcular o novo `likes_count` manualmente.

```typescript
// ✅ CORRECTO
const res = await api.post(`/forum/topics/${id}/like`);
setLiked(res.data.liked);
setLikesCount(res.data.likes_count);   // usar o valor do backend

// ❌ ERRADO — causa flicker
setLiked(!liked);
setLikesCount(liked ? likesCount - 1 : likesCount + 1);
// ... depois corrigir com o backend
```

**Porquê:** O backend usa WebSocket (`ShouldBroadcastNow`) para notificar outros utilizadores. Quando o servidor Reverb não está disponível, o backend retorna 200 na mesma (erros de broadcast são capturados internamente). O frontend nunca deve receber 500 por causa de likes.

---

## 6. Bookmarks

```
POST /forum/topics/{id}/bookmark
Authorization: Bearer {token}

Resposta:
{ "bookmarked": true }
ou
{ "bookmarked": false }
```

```
GET /forum/bookmarks
Authorization: Bearer {token}
```

---

## 7. Notificações

### 7.1 Endpoints
```
GET  /notifications                    // lista paginada
PUT  /notifications/{id}/read          // marcar uma como lida
PUT  /notifications/read-all           // marcar todas como lidas
```

**Estrutura de uma notificação:**
```json
{
  "id": 55,
  "type": "FORUM_NEW_COMMENT",
  "message": "João comentou no teu tópico 'Angola em Foco'.",
  "reference_id": 11,
  "reference_type": "comment",
  "actor_id": 2,
  "is_read": false,
  "created_at": "2026-06-25T10:30:00Z"
}
```

---

### 7.2 Tabela completa — todos os tipos

| Tipo | `reference_type` | `reference_id` | Acção ao clicar |
|---|---|---|---|
| `FORUM_TOPIC_LIKE` | `forum_topic` | topic_id | Navegar para o tópico |
| `FORUM_NEW_COMMENT` | `comment` | comment_id | Ver comentário → navegar para tópico |
| `FORUM_COMMENT_REPLY` | `comment` | comment_id | Ver comentário → navegar para tópico |
| `FORUM_COMMENT_LIKE` | `comment` | comment_id | Ver comentário → navegar para tópico |
| `FORUM_ACCESS_REQUEST` | `forum_topic` | topic_id | Navegar para gestão de pedidos do tópico |
| `FORUM_ACCESS_APPROVED` | `forum_topic` | topic_id | Navegar para o tópico (já tem acesso) |
| `FORUM_ACCESS_REJECTED` | `forum_topic` | topic_id | Navegar para o tópico (mostrar mensagem) |
| `FORUM_INVITE` | `topic_access_request` | **access_request_id** | Mostrar modal Aceitar/Rejeitar |
| `FORUM_INVITE_ACCEPTED` | `forum_topic` | topic_id | Navegar para o tópico |
| `FORUM_JOIN_BY_CODE` | `forum_topic` | topic_id | Navegar para o tópico (ver quem entrou) |

> `FORUM_INVITE` é o **único tipo** onde `reference_id` não é um `topic_id`.

---

### 7.3 Handler de notificações — código completo

```typescript
async function handleNotificationPress(notification) {
  const { type, reference_id: refId } = notification;

  // Marcar como lida
  await api.put(`/notifications/${notification.id}/read`);

  // ── Convite (ÚNICO caso em que refId é access_request_id) ──
  if (type === 'FORUM_INVITE') {
    showInviteModal({
      accessRequestId: refId,
      message: notification.message,
      onAccept: async () => {
        const res = await api.post(`/forum/invites/${refId}/accept`);
        // res.data.topic_id contém o topic_id para navegar
        router.push(`/forum/topics/${res.data.topic_id}`);
      },
      onReject: async () => {
        await api.post(`/forum/invites/${refId}/reject`);
        dismissModal();
      },
    });
    return;
  }

  // ── Notificações que apontam para um comentário ──
  if (
    type === 'FORUM_NEW_COMMENT' ||
    type === 'FORUM_COMMENT_REPLY' ||
    type === 'FORUM_COMMENT_LIKE'
  ) {
    // refId = comment_id → resolver o topic_id
    const res = await api.get(`/forum/comments/${refId}`);
    const topicId = res.data.forum_topic_id;
    router.push(`/forum/topics/${topicId}`, { highlightCommentId: refId });
    return;
  }

  // ── Todas as restantes apontam directamente para o tópico ──
  if (
    type === 'FORUM_TOPIC_LIKE' ||
    type === 'FORUM_ACCESS_REQUEST' ||
    type === 'FORUM_ACCESS_APPROVED' ||
    type === 'FORUM_ACCESS_REJECTED' ||
    type === 'FORUM_INVITE_ACCEPTED' ||
    type === 'FORUM_JOIN_BY_CODE'
  ) {
    router.push(`/forum/topics/${refId}`);
    return;
  }
}
```

---

### 7.4 Modal de convite — comportamento correcto

Quando chega `FORUM_INVITE`, o frontend deve mostrar um modal com:
- Texto: `notification.message` (ex: "Isabel convidou-te para o tópico privado 'Angola em Foco'.")
- Botão **Aceitar** → `POST /forum/invites/{reference_id}/accept`
- Botão **Rejeitar** → `POST /forum/invites/{reference_id}/reject`

**Após aceitar:**
```typescript
const res = await api.post(`/forum/invites/${accessRequestId}/accept`);
// Resposta:
// { message: "Convite aceite...", topic_id: 5, topic: { ... } }

// Navegar directamente com os dados já disponíveis:
router.push(`/forum/topics/${res.data.topic_id}`);
```

---

## 8. Pesquisa de Utilizadores

### 8.1 Pesquisa por nome/email
```
GET /users/search?q=isabel&topic_id=5
Authorization: Bearer {token}
```

- `q` (obrigatório, mínimo 2 caracteres): termo de pesquisa
- `topic_id` (opcional): quando fornecido, **exclui utilizadores que já são membros** do tópico

**Resposta:**
```json
{
  "data": [
    { "id": 2, "name": "Isabel Marques", "email": "...", "avatar_url": "..." }
  ]
}
```

> **Sempre passar `topic_id` no fluxo de convite** para evitar mostrar membros já existentes.

---

### 8.2 Lista de rede (para ecrã de convidar sem pesquisa)
```
GET /users/network?topic_id=5
Authorization: Bearer {token}
```

Retorna utilizadores ordenados por proximidade (seguidores primeiro), excluindo automaticamente os que já são membros quando `topic_id` é fornecido. Paginado (20 por página).

**Resposta:**
```json
{
  "data": [
    { "id": 2, "name": "João", "email": "...", "avatar_url": "..." }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 2,
    "per_page": 20,
    "total": 35
  }
}
```

---

## 9. Bugs Corrigidos

### 9.1 Like com flicker (número volta ao anterior)
**Causa:** `ShouldBroadcastNow` lançava excepção quando Reverb estava offline → 500 → frontend revertia o estado.  
**Correcção:** Todos os `broadcast()` estão agora em `try-catch`. O backend retorna 200 mesmo sem WebSocket.  
**Frontend:** Não fazer optimistic update manual — usar sempre os valores retornados pelo backend.

---

### 9.2 `is_liked` ausente em comentários e replies
**Causa:** `transformComments()` não calculava `is_liked`.  
**Correcção:** `is_liked` agora presente em todos os comentários e replies no `GET /forum/topics/{id}` e `GET /forum/topics/{id}/comments`.

---

### 9.3 `likes_count: null` nas replies
**Causa:** `withCount('likes')` só aplicava ao comentário raiz, não às replies.  
**Correcção:** `likes_count` agora sempre presente (>= 0) em replies.

---

### 9.4 Notificação de novo comentário não navega para o comentário
**Causa:** `FORUM_NEW_COMMENT` armazenava `reference_id = topic_id`.  
**Correcção:** `reference_id = comment_id`, `reference_type = 'comment'`.  
**Frontend:** Chamar `GET /forum/comments/{comment_id}` para resolver o `topic_id` antes de navegar.

---

### 9.5 `is_read_only` não funcionava para o dono
**Causa:** Só moderadores podiam alterar `is_read_only`.  
**Correcção:** Dono do tópico pode agora ligar/desligar `is_read_only` via `PUT /forum/topics/{id}`.

---

### 9.6 Replies de 3+ níveis desapareciam
**Causa:** Reply a uma reply ficava com `parent_id` da reply intermédia, tornando-se invisível na estrutura plana.  
**Correcção:** Flat threading — o backend normaliza sempre `parent_id` para o comentário raiz. O frontend envia o id de qualquer comentário, o backend resolve.

---

### 9.7 `mention_user` desaparecia após reload
**Causa:** `mention_user` só estava na resposta do POST, não era persistido.  
**Correcção:** Nova coluna `mention_user_id` na tabela `comments`. O `mention_user` agora persiste e vem em todas as respostas de comentários.  
**Migração pendente:** `php artisan migrate` deve ser corrido no servidor de produção.

---

### 9.8 Membros existentes apareciam na lista de convite
**Causa:** `GET /users/search` não filtrava por membros do tópico.  
**Correcção:** Parâmetro `topic_id` adicionado ao `/users/search` e `/users/network` — exclui membros automaticamente.

---

### 9.9 Erro ao aceitar convite via notificação ← NOVO
**Causa provável:** Frontend usa `reference_id` do `FORUM_INVITE` como `topic_id` mas é um `access_request_id`.  
**Correcção (frontend):** Ver secção 7.3 e 7.4 acima.

---

## Referência Rápida — Todos os Endpoints do Fórum

```
# Públicos (sem token)
GET    /forum/topics
GET    /forum/topics/{id}
GET    /forum/featured
GET    /forum/join/{code}

# Autenticados
POST   /forum/topics
PUT    /forum/topics/{id}
DELETE /forum/topics/{id}
GET    /forum/my-topics

POST   /forum/topics/{id}/like
POST   /forum/topics/{id}/bookmark
GET    /forum/bookmarks

GET    /forum/topics/{id}/comments
POST   /forum/topics/{id}/comments
GET    /forum/comments/{id}            ← NOVO (resolver topic_id a partir de comment_id)
PUT    /forum/comments/{id}
DELETE /forum/comments/{id}
POST   /forum/comments/{id}/like

POST   /forum/topics/{id}/request-access
POST   /forum/topics/{id}/join-with-code
GET    /forum/topics/{id}/invite-link
POST   /forum/topics/{id}/invite
POST   /forum/topics/{id}/regenerate-code
GET    /forum/topics/{id}/members
GET    /forum/topics/{id}/access-requests
PATCH  /forum/topics/{id}/access-requests/{requestId}/approve
PATCH  /forum/topics/{id}/access-requests/{requestId}/reject

POST   /forum/invites/{accessRequestId}/accept    ← accessRequestId, NÃO topic_id
POST   /forum/invites/{accessRequestId}/reject    ← accessRequestId, NÃO topic_id

GET    /users/search?q=...&topic_id=...
GET    /users/network?topic_id=...

GET    /notifications
PUT    /notifications/{id}/read
PUT    /notifications/read-all
```
