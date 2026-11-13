# Especificação da API REST (API Dôa)

Base: `http://localhost:8080`. Documentação interativa em `/swagger-ui.html` e coleção do Postman em `postman/`.

**Autenticação:** todas as rotas, exceto `login` e `register`, exigem `Authorization: Bearer <token>`.
**Erros:** sempre `{ "message": "texto em português" }`. Códigos comuns: `400` dados inválidos · `401` sem sessão · `403` sem permissão · `404` não encontrado · `409` conflito de regra de negócio.
**Perfis:** `DONOR` doador · `INSTITUTION` instituição · `ADMIN` administrador.

## Autenticação

| Verbo | Path | Perfil | Body de requisição | Body de retorno | Sucesso | Erro | Obs |
|---|---|---|---|---|---|---|---|
| POST | `/api/auth/login` | público | `{email, password}` | `{token, user}` | 200 | 401, 403 | 3 erros bloqueiam 30 min (403) |
| POST | `/api/auth/register` | público | `{email, password, role}` | `{token, user}` | 201 | 400, 403, 409 | `role`: DONOR ou INSTITUTION |
| POST | `/api/auth/logout` | autenticado | - | - | 204 | - | Invalida o token |

## Usuários

| Verbo | Path | Perfil | Body de requisição | Body de retorno | Sucesso | Erro | Obs |
|---|---|---|---|---|---|---|---|
| GET | `/api/users/me` | autenticado | - | `user` | 200 | 401 | |
| PUT | `/api/users/me/fcm-token` | autenticado | `{token}` | - | 204 | 400 | Registra o token do push |
| POST | `/api/users` | ADMIN | `{email, password, role}` | `user` | 201 | 400, 403, 409 | |
| GET | `/api/users` | ADMIN | - | `[user]` | 200 | 403 | |
| GET | `/api/users/{id}` | ADMIN | - | `user` | 200 | 403, 404 | |
| PUT | `/api/users/{id}` | ADMIN | `{email?, role?, isActive?, password?}` | `user` | 200 | 400, 403, 404, 409 | Só o que vier é alterado |
| DELETE | `/api/users/{id}` | ADMIN | - | - | 204 | 400, 403, 404, 409 | Bloqueia se tiver cadastro vinculado |

## Categorias de alimento (entidade avaliada)

| Verbo | Path | Perfil | Body de requisição | Body de retorno | Sucesso | Erro | Obs |
|---|---|---|---|---|---|---|---|
| GET | `/api/categories?includeInactive=` | autenticado | - | `[category]` | 200 | 401 | Inativas só para ADMIN |
| GET | `/api/categories/{id}` | autenticado | - | `category` | 200 | 404 | |
| POST | `/api/categories` | ADMIN | `{name, description?, active?}` | `category` | 201 | 400, 403, 409 | Nome único |
| PUT | `/api/categories/{id}` | ADMIN | `{name, description?, active?}` | `category` | 200 | 400, 403, 404, 409 | |
| DELETE | `/api/categories/{id}` | ADMIN | - | - | 204 | 403, 404, 409 | 409 se em uso: desative |

## Doadores (entidade avaliada)

| Verbo | Path | Perfil | Body de requisição | Body de retorno | Sucesso | Erro | Obs |
|---|---|---|---|---|---|---|---|
| POST | `/api/donors` | DONOR | `{personType, name, document, phone, address, city, latitude?, longitude?}` | `donor` | 201 | 400, 409 | CPF/CNPJ validado |
| GET | `/api/donors/me` | DONOR | - | `donor` | 200 | 404 | 404 = ainda sem cadastro |
| PUT | `/api/donors/me` | DONOR | `{name, phone, address, city, latitude?, longitude?}` | `donor` | 200 | 400, 404 | Documento não muda |
| DELETE | `/api/donors/me` | DONOR | - | - | 204 | 404, 409 | 409 se tem doações |
| GET | `/api/donors` | ADMIN | - | `[donor]` | 200 | 403 | |
| GET | `/api/donors/{id}` | ADMIN | - | `donor` | 200 | 403, 404 | |
| PUT | `/api/donors/{id}` | ADMIN | igual ao `PUT /me` | `donor` | 200 | 400, 403, 404 | |
| DELETE | `/api/donors/{id}` | ADMIN | - | - | 204 | 403, 404, 409 | |

## Instituições (entidade avaliada) e categorias aceitas (N:N)

| Verbo | Path | Perfil | Body de requisição | Body de retorno | Sucesso | Erro | Obs |
|---|---|---|---|---|---|---|---|
| POST | `/api/institutions` | INSTITUTION | `{name, cnpj, address, city, areaOfActivity, storageCapacityKg, categoryIds[], latitude?, longitude?}` | `institution` | 201 | 400, 409 | Nasce PENDING. Exige ao menos 1 categoria |
| GET | `/api/institutions/me` | INSTITUTION | - | `institution` | 200 | 404 | |
| PUT | `/api/institutions/me` | INSTITUTION | `{name, address, city, areaOfActivity, storageCapacityKg, latitude?, longitude?}` | `institution` | 200 | 400, 404 | REJECTED volta a PENDING |
| DELETE | `/api/institutions/me` | INSTITUTION | - | - | 204 | 404, 409 | 409 se tem doações |
| GET | `/api/institutions/me/categories` | INSTITUTION | - | `[{id, name}]` | 200 | 404 | |
| PUT | `/api/institutions/me/categories` | INSTITUTION | `{categoryIds[]}` | `institution` | 200 | 400, 404 | Substitui o conjunto |
| POST | `/api/institutions/me/categories/{categoryId}` | INSTITUTION | - | `institution` | 200 | 400, 404 | Adiciona uma |
| DELETE | `/api/institutions/me/categories/{categoryId}` | INSTITUTION | - | `institution` | 200 | 400, 404 | Não remove a última |
| GET | `/api/institutions?status=` | ADMIN | - | `[institution]` | 200 | 403 | Filtro opcional |
| GET | `/api/institutions/{id}` | ADMIN | - | `institution` | 200 | 403, 404 | |
| PUT | `/api/institutions/{id}/approve` | ADMIN | - | `institution` | 200 | 403, 404, 409 | Só PENDING |
| PUT | `/api/institutions/{id}/reject` | ADMIN | `{reason}` | `institution` | 200 | 400, 403, 404, 409 | Só PENDING |
| DELETE | `/api/institutions/{id}` | ADMIN | - | - | 204 | 403, 404, 409 | |

## Doações (entidade avaliada)

| Verbo | Path | Perfil | Body de requisição | Body de retorno | Sucesso | Erro | Obs |
|---|---|---|---|---|---|---|---|
| POST | `/api/donations` | DONOR | `{categoryId, description, quantity, unit, expiresAt, storageConditions?}` | `donation` | 201 | 400 | Validade futura; unit: kg, un ou L |
| GET | `/api/donations/mine` | DONOR | - | `[donation]` | 200 | 400 | |
| PUT | `/api/donations/{id}` | DONOR (dono) | igual ao `POST` | `donation` | 200 | 400, 403, 404, 409 | Só AVAILABLE |
| DELETE | `/api/donations/{id}` | DONOR (dono) | - | - | 204 | 403, 404, 409 | Não exclui RESERVED/DELIVERED |
| PUT | `/api/donations/{id}/cancel` | DONOR (dono) | - | `donation` | 200 | 403, 404, 409 | AVAILABLE ou RESERVED |
| GET | `/api/donations?categoryId=&radiusKm=&lat=&lng=` | INSTITUTION aprovada | - | `[donation]` | 200 | 403 | Só categorias aceitas (N:N); por proximidade; raio padrão 50 km; `lat`/`lng` = GPS do aparelho |
| GET | `/api/donations/requested` | INSTITUTION | - | `[donation]` | 200 | 403 | Reservadas e recebidas |
| POST | `/api/donations/{id}/request` | INSTITUTION aprovada | - | `donation` | 200 | 403, 404, 409 | Máx. 5 ativas; categoria aceita |
| POST | `/api/donations/{id}/confirm-delivery` | INSTITUTION que reservou | - | `donation` | 200 | 403, 404, 409 | Gera item de estoque |
| GET | `/api/donations/{id}` | autenticado | - | `donation` | 200 | 403, 404 | Doador só vê as suas |
| POST | `/api/donations/{id}/photos` | DONOR (dono) | `multipart/form-data`, campo `file` (JPEG/PNG/WebP, até 5 MB) | `{url}` | 201 | 400, 403, 404, 409, 413 | Máx. 5 por doação; só AVAILABLE; tipo checado pelo conteúdo |
| DELETE | `/api/donations/{id}/photos/{photoId}` | DONOR (dono) | - | - | 204 | 403, 404, 409 | |
| GET | `/api/photos/{photoId}` | público (UUID) | - | bytes da imagem | 200 | 404 | `Cache-Control` 7 dias; usada no `Image.network` |

O objeto `donation` traz `photoUrls: ["/api/photos/<uuid>", ...]` (a primeira é a capa).

## Chat (REST)

| Verbo | Path | Perfil | Body de requisição | Body de retorno | Sucesso | Erro | Obs |
|---|---|---|---|---|---|---|---|
| GET | `/api/donations/{id}/messages` | doador ou instituição da doação | - | `[message]` | 200 | 403, 404 | Histórico |
| POST | `/api/donations/{id}/messages` | doador ou instituição da doação | `{content}` | `message` | 201 | 400, 403, 404, 409 | Só após reserva; entrega em tempo real via WebSocket |

## Estoque

| Verbo | Path | Perfil | Body de requisição | Body de retorno | Sucesso | Erro | Obs |
|---|---|---|---|---|---|---|---|
| GET | `/api/stock` | INSTITUTION | - | `[stockItem]` | 200 | 403 | Por validade |
| POST | `/api/stock` | INSTITUTION | `{categoryId, description, quantity, unit, expiresAt}` | `stockItem` | 201 | 400 | Entrada manual |
| PUT | `/api/stock/{id}` | INSTITUTION | igual ao `POST` | `stockItem` | 200 | 400, 404 | |
| DELETE | `/api/stock/{id}` | INSTITUTION | - | - | 204 | 404 | |

## Impacto

| Verbo | Path | Perfil | Body de retorno | Sucesso | Obs |
|---|---|---|---|---|---|
| GET | `/api/impact` | autenticado | `{donationsCount, deliveredCount, wasteAvoidedKg, peopleServed, institutionsServed}` | 200 | Doador: o que doou. Instituição: o que recebeu. Admin: total |

## Objetos

```jsonc
// user
{ "id": 1, "email": "a@b.com", "role": "DONOR", "isActive": true, "createdAt": "2026-10-25T10:00:00" }
// category
{ "id": 1, "name": "Frutas", "description": "Frutas frescas", "active": true }
// donor
{ "id": 1, "userId": 2, "personType": "INDIVIDUAL", "name": "Maria", "document": "52998224725",
  "phone": "11999998888", "address": "Rua A, 1", "city": "Bragança Paulista", "latitude": -22.95, "longitude": -46.54 }
// institution
{ "id": 1, "userId": 3, "name": "Casa Esperança", "cnpj": "11222333000181", "address": "...", "city": "...",
  "areaOfActivity": "...", "storageCapacityKg": 800.0, "status": "APPROVED", "rejectionReason": null,
  "latitude": -22.94, "longitude": -46.53, "categories": [ { "id": 1, "name": "Frutas" } ] }
// donation
{ "id": 10, "donorId": 1, "donorName": "Maria", "categoryId": 1, "categoryName": "Frutas",
  "description": "Laranjas", "quantity": 10.0, "unit": "kg", "expiresAt": "2026-11-02",
  "storageConditions": "Ambiente", "status": "AVAILABLE", "reservedById": null, "reservedByName": null,
  "reservedAt": null, "createdAt": "2026-10-25T09:30:00", "city": "Bragança Paulista", "distanceKm": 3.1 }
// stockItem
{ "id": 1, "categoryId": 3, "categoryName": "Grãos e cereais", "description": "Feijão", "quantity": 25.0,
  "unit": "kg", "receivedAt": "2026-10-04T10:00:00", "expiresAt": "2026-11-28" }
// message
{ "id": 1, "donationId": 10, "senderUserId": 2, "senderName": "Maria", "content": "Olá!", "sentAt": "2026-10-25T11:00:00" }
```
`distanceKm` só vem preenchido para instituições. `donorId` e `reservedById` são ids dos **perfis** (Donor e Institution), os mesmos de `GET /donors/me` e `GET /institutions/me`.

## WebSocket

Veja `docs/MODELO.md` (seção RF-WS). Endpoint: `ws://localhost:8080/ws?token=<JWT>`.
