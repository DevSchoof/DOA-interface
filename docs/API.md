# Contrato da API

Rotas por sprint. Alterações neste arquivo passam por Pull Request e precisam da aprovação das duas pessoas (front e back).

## Convenções

- Base: `/api`, JSON, UTF-8.
- Campos em **camelCase**.
- Enums em **MAIÚSCULAS**.
- Datas em **ISO-8601** (`2026-10-13T08:00:00`).
- `id` pode ser `Long` ou `UUID`. O app trata ids como texto.
- Rotas protegidas usam o cabeçalho `Authorization: Bearer <token JWT>`.
- **Habilitar CORS**: o app roda no navegador (Flutter Web) durante o desenvolvimento.
- **Paginação:** parâmetros `page` (começa em 0) e `size`. A resposta segue o formato padrão do Spring `Page`; o app usa apenas estes campos:

```json
{
  "content": [ ],
  "number": 0,
  "size": 20,
  "totalElements": 42,
  "totalPages": 3
}
```

## Enums

| Enum | Valores |
|---|---|
| `UserRole` | `DONOR`, `INSTITUTION`, `ADMIN` |
| `PersonType` | `INDIVIDUAL`, `COMPANY` |
| `InstitutionStatus` | `PENDING`, `APPROVED`, `REJECTED`, `SUSPENDED` |

## Erros

Qualquer erro retorna status HTTP adequado e corpo:

```json
{ "message": "Texto em português para exibir ao usuário." }
```

| Status | Quando |
|---|---|
| 400 | dados inválidos |
| 401 | não autenticado, token inválido ou credenciais erradas |
| 403 | sem permissão para o perfil, ou conta suspensa |
| 404 | registro não encontrado |
| 409 | conflito (e-mail, documento ou CNPJ já cadastrado) |

---

# Sprint 1

### PB-001: Login
`POST /api/auth/login` (pública)

Requisição:
```json
{ "email": "doador@doa.com", "password": "doador123" }
```
Resposta `200`:
```json
{
  "token": "eyJhbGciOi...",
  "user": {
    "id": 2,
    "email": "doador@doa.com",
    "role": "DONOR",
    "isActive": true,
    "createdAt": "2026-09-01T10:00:00"
  }
}
```
Regras:
- Senha com hash BCrypt.
- Usuário com `isActive = false` recebe `403`.
- Credenciais erradas recebem `401` com a mensagem "E-mail ou senha inválidos."
- Atenção: em Java, um campo `boolean isActive` é serializado pelo Jackson como `active`. O JSON deve conter exatamente `isActive` (use `@JsonProperty("isActive")`).

### PB-002: Logout
`POST /api/auth/logout` (autenticada). Resposta `204` sem corpo. Invalida o token no servidor.

### PB-003: Cadastro de usuário
`POST /api/users` (somente `ADMIN`)

Requisição:
```json
{ "email": "novo@doa.com", "password": "senha123", "role": "INSTITUTION" }
```
Resposta `201`: objeto `user` (mesmo formato do login).
Regras: senha com no mínimo 6 caracteres. E-mail repetido retorna `409`.

### PB-004: Cadastro de doador
`POST /api/donors` (autenticada, perfil `DONOR`). O doador é o usuário do token, então o app **não** envia `userId`.

Requisição:
```json
{
  "personType": "INDIVIDUAL",
  "name": "Maria Silva",
  "document": "12345678901",
  "phone": "11999998888",
  "address": "Rua das Flores, 100",
  "city": "São Paulo"
}
```
Resposta `201`: objeto `donor`:
```json
{
  "id": 1,
  "userId": 2,
  "personType": "INDIVIDUAL",
  "name": "Maria Silva",
  "document": "12345678901",
  "phone": "11999998888",
  "address": "Rua das Flores, 100",
  "city": "São Paulo",
  "latitude": null,
  "longitude": null
}
```
Regras:
- `document` é CPF (11 dígitos) para `INDIVIDUAL` e CNPJ (14) para `COMPANY`, só dígitos.
- Documento repetido retorna `409`.
- O mesmo usuário cadastrar um segundo perfil de doador retorna `409`.

### Complemento: consulta do próprio doador
`GET /api/donors/me` (perfil `DONOR`). Resposta `200`: objeto `donor`. Se o doador ainda não completou o cadastro, `404`. O app usa essa rota para decidir se mostra o botão de cadastro e para preencher a tela de edição (PB-005).

---

# Sprint 2

Objeto `institution`, usado nas respostas:

```json
{
  "id": 5,
  "userId": 3,
  "name": "ONG Esperança",
  "cnpj": "11222333000181",
  "phone": "11999998888",
  "address": "Rua A, 10",
  "city": "São Paulo",
  "latitude": null,
  "longitude": null,
  "storageCapacity": 500.0,
  "status": "PENDING"
}
```

`storageCapacity` é a capacidade volumétrica, em número decimal maior que zero.

### PB-005: Editar dados do doador
`PUT /api/donors/me` (perfil `DONOR`)

Requisição (campos editáveis; `personType` não pode ser alterado):
```json
{
  "name": "Maria Souza",
  "document": "12345678901",
  "phone": "11988887777",
  "address": "Rua Nova, 200",
  "city": "Campinas"
}
```
Resposta `200`: objeto `donor` atualizado.
Regras:
- Os dados são validados novamente (CPF/CNPJ conforme o `personType`).
- Documento já usado por outro doador retorna `409`.
- Cada alteração é registrada em um histórico (quem, quando, valores antes e depois). O app não exibe esse histórico nesta sprint.

### PB-006: Cadastro de instituição
`POST /api/institutions` (perfil `INSTITUTION`). A instituição pertence ao usuário do token, então o app **não** envia `userId`.

Requisição (`latitude` e `longitude` são opcionais):
```json
{
  "name": "ONG Esperança",
  "cnpj": "11222333000181",
  "phone": "11999998888",
  "address": "Rua A, 10",
  "city": "São Paulo",
  "storageCapacity": 500.0,
  "latitude": null,
  "longitude": null
}
```
Resposta `201`: objeto `institution` com `status` igual a `PENDING`.
Regras:
- `cnpj` com 14 dígitos, só dígitos, validado pelos dígitos verificadores.
- CNPJ repetido retorna `409`.
- O mesmo usuário cadastrar uma segunda instituição retorna `409`.
- `storageCapacity` menor ou igual a zero retorna `400`.

### Complemento: consulta da própria instituição
`GET /api/institutions/me` (perfil `INSTITUTION`). Resposta `200`: objeto `institution`, em qualquer status. Se ainda não cadastrou, `404`.

### PB-007: Homologação pelo administrador

**Listar pendentes:** `GET /api/institutions?status=PENDING&page=0&size=20` (somente `ADMIN`). Resposta `200`: página de `institution` (ver Convenções).

**Aprovar ou rejeitar:** `PATCH /api/institutions/{id}/status` (somente `ADMIN`)

Requisição:
```json
{ "status": "APPROVED" }
```
Resposta `200`: objeto `institution` atualizado.
Regras:
- Valores aceitos neste PBI: `APPROVED` e `REJECTED`, e só a partir de `PENDING` (outra origem retorna `409`).
- Instituição inexistente retorna `404`.
- A notificação ao aprovar está em aberto (ver Pontos em aberto).

### PB-008: Listar instituições homologadas
`GET /api/institutions?name=esper&city=São Paulo&page=0&size=20` (qualquer usuário autenticado)

| Parâmetro | Descrição |
|---|---|
| `name` | filtro por nome, contém, sem diferenciar maiúsculas |
| `city` | filtro por cidade, contém, sem diferenciar maiúsculas |
| `page`, `size` | paginação (padrão: `0` e `20`) |
| `status` | só é considerado para `ADMIN` (PB-007) |

Resposta `200`: página de `institution`.
Regra: para quem **não** é `ADMIN`, a rota retorna **somente** instituições `APPROVED`, ignorando o parâmetro `status`.

### PB-009: Editar dados da instituição
`PUT /api/institutions/me` (perfil `INSTITUTION`)

Requisição: mesmos campos do cadastro (PB-006).
Resposta `200`: objeto `institution` atualizado.
Regras:
- Valida o CNPJ novamente. CNPJ de outra instituição retorna `409`.
- Só a própria instituição pode editar os seus dados.
- `status` não é alterado por esta rota.

---

## Pontos em aberto

1. **Fluxo do doador (PB-003 e PB-004):** o doador cria a própria conta ou o admin cria a conta e o doador completa o perfil depois? (este contrato assume a segunda opção, e o mesmo vale para a instituição)
2. **Tipo do `id`:** `Long` ou `UUID`?
3. **Localização da sede (PB-006):** o usuário informa latitude e longitude, o servidor converte o endereço em coordenadas, ou fica para a Sprint 5 (mapa)? Por ora são opcionais.
4. **Notificação ao aprovar (PB-007):** por qual canal (e-mail, notificação no app)? Quem dispara?
5. **Mudança de CNPJ (PB-009):** alterar o CNPJ de uma instituição já homologada exige nova homologação (volta para `PENDING`)?
6. **Campos editáveis do doador (PB-005):** `document` pode ser alterado? Este contrato permite, com revalidação.