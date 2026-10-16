# Contrato da API: Sprint 1

## Convenções

- Base: `/api`, JSON, UTF-8.
- Campos em **camelCase**.
- Enums em **MAIÚSCULAS**.
- Datas em **ISO-8601** (`2026-10-13T08:00:00`).
- `id` pode ser `Long` ou `UUID`. O app trata ids como texto.
- Rotas protegidas usam o cabeçalho `Authorization: Bearer <token JWT>`.
- **Habilitar CORS**: o app roda no navegador (Flutter Web) durante o desenvolvimento.

## Enums

| Enum | Valores |
|---|---|
| `UserRole` | `DONOR`, `INSTITUTION`, `ADMIN` |
| `PersonType` | `INDIVIDUAL`, `COMPANY` |

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
| 409 | conflito (e-mail ou documento já cadastrado) |

## Rotas

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
Resposta `201`:
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
Regras: `document` é CPF (11 dígitos) para `INDIVIDUAL` e CNPJ (14) para `COMPANY`, só dígitos. Documento repetido retorna `409`.

## Pontos em aberto

1. **Fluxo do doador (PB-003 e PB-004):** o doador cria a própria conta ou o admin cria a conta e o doador completa o perfil depois? (este contrato assume a segunda opção)
2. **Tipo do `id`:** `Long` ou `UUID`?