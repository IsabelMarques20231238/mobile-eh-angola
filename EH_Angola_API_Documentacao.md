# 📡 EH Angola — Documentação da API RESTful
**atualizacies:Sim, há algumas coisas que eu melhoraria na documentação para ficar mais profissional e facilitar a integração do front/mobile.

# O que adicionar

## 1. Endpoint Google Auth

Está funcional mas não aparece na documentação.

Adicionar algo tipo:

```md
### 1.6 Login/Register com Google
POST /auth/google
```

Body:

```json
{
  "token": "google_id_token"
}
```

Resposta:

```json
{
  "user": {...},
  "token": "sanctum_token"
}
```

---

## 2. Forgot Password

Adicionar:

```md
### 1.7 Recuperar password
POST /forgot-password
```

Body:

```json
{
  "email": "user@gmail.com"
}
```

Resposta:

```json
{
  "message": "Codigo de recuperacao enviado com sucesso."
}
```

---

## 3. Reset Password

Adicionar:

```md
### 1.8 Redefinir password
POST /reset-password
```

Body:

```json
{
  "email": "user@gmail.com",
  "code": "123456",
  "password": "novaSenha123",
  "password_confirmation": "novaSenha123"
}
```

---

## 4. Upload Cloudinary

Muito importante para front/mobile.

Adicionar:

```md
## Uploads

POST /upload/image
Authorization: Bearer {token}
```

Tipo:

```text
multipart/form-data
```

Campo:

```text
image
```

Resposta:

```json
{
  "url": "...",
  "public_id": "..."
}
```

---

## 5. Roles/Permissões

Adicionar tabela simples:

| Role      | Permissões        |
| --------- | ----------------- |
| USER      | comentar, quizzes |
| AUTHOR    | criar conteúdos   |
| MODERATOR | moderar           |
| ADMIN     | gestão total      |

---

## 6. Status dos conteúdos

Documentar:

```text
DRAFT
PENDING
PUBLISHED
ARCHIVED
```

e o significado de cada um.

---

## 7. Headers padrão

Adicionar secção:

```md
## Headers padrão
```

```http
Accept: application/json
Authorization: Bearer TOKEN
Content-Type: application/json
```

---

## 8. Explicar paginação

Porque o `/contents` devolve Laravel pagination.

Adicionar exemplo de:

* `current_page`
* `last_page`
* `per_page`
* `total`

---

# O mais importante

A documentação já está boa para ES2.
O que faltava mais criticamente era:

* Google auth;
* forgot/reset password;
* upload image.

Porque o mobile/front vai usar muito isso agora.

**Base URL (Produção):**
```
https://api-ehangola-production.up.railway.app/api
```

**Base URL (Local):**
```
http://127.0.0.1:8000/api
```

**Formato:** JSON  
**Autenticação:** Bearer Token (Laravel Sanctum)  
**Versão:** 1.0.0

---

## 🔐 Autenticação

Rotas protegidas requerem o header:
```
Authorization: Bearer {token}
```
O token é obtido no login ou register.

---

## 1. AUTH

### 1.1 Registar utilizador
```
POST /register
```
**Body:**
```json
{
    "name": "Isabel Marques",
    "email": "isabel@exemplo.com",
    "password": "password123",
    "password_confirmation": "password123"
}
```
**Resposta 201:**
```json
{
    "message": "Utilizador registado com sucesso.",
    "user": {
        "id": 1,
        "name": "Isabel Marques",
        "email": "isabel@exemplo.com"
    },
    "token": "1|abc123xyz..."
}
```

---

### 1.2 Login
```
POST /login
```
**Body:**
```json
{
    "email": "isabel@exemplo.com",
    "password": "password123"
}
```
**Resposta 200:**
```json
{
    "message": "Login efectuado com sucesso.",
    "user": {
        "id": 1,
        "name": "Isabel Marques",
        "roles": [{ "role": "USER" }]
    },
    "token": "2|xyz456abc..."
}
```

---

### 1.3 Logout 🔒
```
POST /logout
Authorization: Bearer {token}
```
**Resposta 200:**
```json
{
    "message": "Sessão terminada."
}
```

---

### 1.4 Perfil do utilizador autenticado 🔒
```
GET /me
Authorization: Bearer {token}
```
**Resposta 200:**
```json
{
    "id": 1,
    "name": "Isabel Marques",
    "email": "isabel@exemplo.com",
    "avatar_url": null,
    "bio": null,
    "is_active": true,
    "email_verified": false,
    "roles": [{ "role": "USER" }]
}
```

---

### 1.5 Actualizar perfil 🔒
```
PUT /profile
Authorization: Bearer {token}
```
**Body (campos opcionais):**
```json
{
    "name": "Isabel Marques Silva",
    "bio": "Estudante de economia angolana",
    "avatar_url": "https://exemplo.com/foto.jpg"
}
```

---

## 2. CONTEÚDOS

### 2.1 Listar conteúdos (público)
```
GET /contents
```
**Query params opcionais:**
```
?type=ARTICLE          → filtrar por tipo (ARTICLE, VIDEO, PODCAST)
?category_id=1         → filtrar por categoria
?search=kwanza         → pesquisar por título
?page=1                → paginação
```
**Resposta 200:**
```json
{
    "data": [
        {
            "id": 1,
            "type": "ARTICLE",
            "title": "A História do Kwanza",
            "status": "PUBLISHED",
            "views": 150,
            "author": { "id": 1, "name": "Isabel Marques" },
            "category": { "id": 1, "name": "Economia Colonial" },
            "tags": [{ "id": 1, "name": "Kwanza" }]
        }
    ],
    "current_page": 1,
    "total": 1
}
```

---

### 2.2 Ver conteúdo (público)
```
GET /contents/{id}
```
**Resposta 200:** Conteúdo completo com comentários.

---

### 2.3 Criar conteúdo 🔒 (AUTHOR/ADMIN/MODERATOR)
```
POST /contents
Authorization: Bearer {token}
```
**Body para ARTICLE:**
```json
{
    "type": "ARTICLE",
    "title": "A História do Kwanza",
    "body_text": "O Kwanza é a moeda oficial...",
    "category_id": 1,
    "cover_image_url": "https://exemplo.com/imagem.jpg",
    "tags": [1, 2]
}
```
**Body para VIDEO:**
```json
{
    "type": "VIDEO",
    "title": "Documentário sobre o Petróleo",
    "media_url": "https://youtube.com/watch?v=...",
    "duration": 1800,
    "category_id": 2,
    "tags": [3]
}
```
**Body para PODCAST:**
```json
{
    "type": "PODCAST",
    "title": "Episódio 1 — Diamantes de Angola",
    "media_url": "https://spotify.com/...",
    "duration": 2700,
    "episode_number": 1,
    "category_id": 1
}
```
**Resposta 201:** Conteúdo criado.

---

### 2.4 Editar conteúdo 🔒
```
PUT /contents/{id}
Authorization: Bearer {token}
```
**Body (campos opcionais):**
```json
{
    "title": "Novo título",
    "status": "PUBLISHED",
    "category_id": 2,
    "tags": [1, 3]
}
```
**Valores de status:** `DRAFT`, `PENDING`, `PUBLISHED`, `ARCHIVED`

---

### 2.5 Apagar conteúdo 🔒
```
DELETE /contents/{id}
Authorization: Bearer {token}
```
**Resposta 200:**
```json
{ "message": "Conteúdo arquivado com sucesso." }
```

---

## 3. QUIZZES

### 3.1 Listar quizzes (público)
```
GET /quizzes
```
**Query params:**
```
?difficulty=BEGINNER    → BEGINNER, INTERMEDIATE, ADVANCED
?page=1
```

---

### 3.2 Ver quiz completo (público)
```
GET /quizzes/{id}
```
**Resposta 200:** Quiz com perguntas e opções de resposta.

---

### 3.3 Criar quiz 🔒
```
POST /quizzes
Authorization: Bearer {token}
```
**Body:**
```json
{
    "title": "Quiz sobre o Petróleo Angolano",
    "description": "Testa os teus conhecimentos",
    "difficulty": "INTERMEDIATE",
    "related_content_id": 1,
    "generated_by_ai": false,
    "questions": [
        {
            "text": "Em que ano Angola começou a exportar petróleo?",
            "explanation": "Angola começou em 1956.",
            "answer_options": [
                { "text": "1956", "is_correct": true },
                { "text": "1975", "is_correct": false },
                { "text": "1961", "is_correct": false },
                { "text": "1980", "is_correct": false }
            ]
        }
    ]
}
```
**Resposta 201:** Quiz criado com status `PENDING` (aguarda aprovação admin).

---

### 3.4 Submeter respostas 🔒
```
POST /quizzes/{id}/submit
Authorization: Bearer {token}
```
**Body:**
```json
{
    "answers": [
        {
            "question_id": 1,
            "option_id": 1
        }
    ]
}
```
**Resposta 200:**
```json
{
    "message": "Quiz submetido.",
    "score": 1,
    "total": 1,
    "percentage": 100.0,
    "attempt_id": 1
}
```

---

## 4. FÓRUM

### 4.1 Listar tópicos (público)
```
GET /forum
```
**Query params:**
```
?category_id=1
?search=economia
?page=1
```
**Nota:** Tópicos pinados aparecem primeiro.

---

### 4.2 Ver tópico (público)
```
GET /forum/{id}
```
**Resposta 200:** Tópico com comentários e replies.

---

### 4.3 Criar tópico 🔒
```
POST /forum
Authorization: Bearer {token}
```
**Body:**
```json
{
    "title": "Qual o impacto do petróleo na economia angolana?",
    "body": "Gostaria de discutir...",
    "category_id": 1,
    "tags": [1, 2]
}
```

---

### 4.4 Editar tópico 🔒
```
PUT /forum/{id}
Authorization: Bearer {token}
```

---

### 4.5 Apagar tópico 🔒
```
DELETE /forum/{id}
Authorization: Bearer {token}
```

---

## 5. COMENTÁRIOS

### 5.1 Criar comentário 🔒
```
POST /comments
Authorization: Bearer {token}
```
**Body para comentário num conteúdo:**
```json
{
    "text": "Excelente artigo!",
    "content_id": 1
}
```
**Body para comentário num tópico do fórum:**
```json
{
    "text": "Concordo totalmente.",
    "forum_topic_id": 1
}
```
**Body para reply a outro comentário:**
```json
{
    "text": "Obrigada pelo comentário!",
    "content_id": 1,
    "parent_id": 3
}
```

---

### 5.2 Editar comentário 🔒
```
PUT /comments/{id}
Authorization: Bearer {token}
```
**Body:**
```json
{ "text": "Texto actualizado." }
```

---

### 5.3 Apagar comentário 🔒
```
DELETE /comments/{id}
Authorization: Bearer {token}
```

---

## 6. NOTIFICAÇÕES

### 6.1 Listar notificações 🔒
```
GET /notifications
Authorization: Bearer {token}
```
**Resposta 200:**
```json
{
    "data": [
        {
            "id": 1,
            "type": "NEW_CONTENT",
            "message": "Isabel publicou um novo artigo.",
            "is_read": false,
            "reference_id": 5,
            "reference_type": "CONTENT",
            "created_at": "2026-05-21T10:00:00"
        }
    ]
}
```

---

### 6.2 Marcar notificação como lida 🔒
```
PUT /notifications/{id}/read
Authorization: Bearer {token}
```

---

### 6.3 Marcar todas como lidas 🔒
```
PUT /notifications/read-all
Authorization: Bearer {token}
```

---

## 7. DENÚNCIAS

### 7.1 Criar denúncia 🔒
```
POST /reports
Authorization: Bearer {token}
```
**Body para denunciar conteúdo:**
```json
{
    "reason": "MISINFORMATION",
    "description": "Esta informação está incorrecta.",
    "content_id": 1
}
```
**Body para denunciar comentário:**
```json
{
    "reason": "SPAM",
    "comment_id": 3
}
```
**Body para denunciar tópico:**
```json
{
    "reason": "INAPPROPRIATE",
    "forum_topic_id": 2
}
```
**Valores de reason:** `MISINFORMATION`, `SPAM`, `INAPPROPRIATE`, `OTHER`

---

## 8. SUBSCRIÇÕES

### 8.1 Listar subscrições 🔒
```
GET /subscriptions
Authorization: Bearer {token}
```

---

### 8.2 Criar subscrição 🔒
```
POST /subscriptions
Authorization: Bearer {token}
```
**Seguir um autor:**
```json
{ "target_user_id": 2 }
```
**Seguir uma categoria:**
```json
{ "target_cat_id": 1 }
```
**Seguir um conteúdo:**
```json
{ "target_content_id": 5 }
```

---

### 8.3 Remover subscrição 🔒
```
DELETE /subscriptions/{id}
Authorization: Bearer {token}
```

---

## 9. SUGESTÕES DE TEMA

### 9.1 Listar sugestões 🔒
```
GET /suggestions
Authorization: Bearer {token}
```

---

### 9.2 Criar sugestão 🔒
```
POST /suggestions
Authorization: Bearer {token}
```
**Body:**
```json
{
    "title": "História do Banco Nacional de Angola",
    "description": "Seria interessante explorar a origem do BNA..."
}
```

---

## 10. RANKING

### 10.1 Ver ranking (público)
```
GET /ranking
```
**Query params:**
```
?period=WEEKLY      → WEEKLY, MONTHLY, ALL_TIME (default)
```
**Resposta 200:**
```json
[
    {
        "id": 1,
        "user": { "id": 1, "name": "Isabel Marques" },
        "total_score": 850,
        "quizzes_completed": 12,
        "articles_read": 45,
        "comments_posted": 8,
        "period": "ALL_TIME"
    }
]
```

---

## 11. CATEGORIAS

### 11.1 Listar categorias (público)
```
GET /categories
```

---

### 11.2 Criar categoria 🔒 (ADMIN)
```
POST /categories
Authorization: Bearer {token}
```
**Body:**
```json
{
    "name": "Economia Colonial",
    "description": "Conteúdos sobre economia no período colonial"
}
```

---

## 12. TAGS

### 12.1 Listar tags (público)
```
GET /tags
```
**Query params:**
```
?trending=true    → top 10 tags mais usadas
```

---

### 12.2 Criar tag 🔒
```
POST /tags
Authorization: Bearer {token}
```
**Body:**
```json
{ "name": "Kwanza" }
```

---

## 13. UTILIZADORES

### 13.1 Ver perfil público
```
GET /users/{id}
```

---

## 14. ADMINISTRAÇÃO 🔒 (ADMIN)

Todas as rotas admin requerem:
```
Authorization: Bearer {token_de_admin}
```

---

### 14.1 Listar utilizadores
```
GET /admin/users
```

---

### 14.2 Promover utilizador
```
POST /admin/users/{id}/promote
```
**Body:**
```json
{ "role": "MODERATOR" }
```
**Valores de role:** `AUTHOR`, `MODERATOR`, `ADMIN`

---

### 14.3 Remover role de utilizador
```
DELETE /admin/users/{id}/role
```
**Body:**
```json
{ "role": "MODERATOR" }
```

---

### 14.4 Activar/Desactivar utilizador
```
PUT /admin/users/{id}/toggle
```

---

### 14.5 Quizzes pendentes
```
GET /admin/quizzes/pending
```

---

### 14.6 Aprovar quiz
```
PUT /admin/quizzes/{id}/approve
```

---

### 14.7 Rejeitar quiz
```
PUT /admin/quizzes/{id}/reject
```

---

### 14.8 Listar denúncias pendentes
```
GET /admin/reports
```

---

### 14.9 Resolver denúncia
```
PUT /admin/reports/{id}/resolve
```

---

### 14.10 Listar sugestões pendentes
```
GET /admin/suggestions
```

---

### 14.11 Aprovar sugestão
```
PUT /admin/suggestions/{id}/approve
```

---

### 14.12 Rejeitar sugestão
```
PUT /admin/suggestions/{id}/reject
```

---

## 📋 Códigos de resposta HTTP

| Código | Significado |
|--------|-------------|
| 200 | Sucesso |
| 201 | Criado com sucesso |
| 401 | Não autenticado (token inválido ou ausente) |
| 403 | Sem permissão |
| 404 | Não encontrado |
| 409 | Conflito (ex: role já existe) |
| 422 | Dados inválidos (validation error) |
| 500 | Erro interno do servidor |

---

## 🔑 Roles e Permissões

| Role | Permissões |
|------|-----------|
| `USER` | Ler conteúdos, fazer quizzes, comentar, participar no fórum, subscrever, sugerir temas, denunciar |
| `AUTHOR` | Tudo de USER + criar e editar conteúdos |
| `MODERATOR` | Tudo de AUTHOR + moderar comentários e tópicos |
| `ADMIN` | Acesso total — gerir utilizadores, aprovar quizzes, resolver denúncias |

---

## 📱 Notas para integração Mobile/Web

1. Guarda o token após login/register no storage seguro do dispositivo
2. Inclui sempre o header `Content-Type: application/json`
3. Para rotas paginadas usa o campo `current_page` e `last_page` para navegação
4. Trata o erro `401` redirecionando para o ecrã de login
5. Trata o erro `422` mostrando os erros de validação ao utilizador

---

*Documentação gerada para o projecto Economia com História — Angola*  
*Backend: Laravel 12 + MySQL | Deploy: Railway*
