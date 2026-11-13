# API Dôa

API REST + WebSocket do Dôa, plataforma que liga quem tem alimento sobrando a instituições que precisam. Atende as disciplinas de **Desenvolvimento Web Back-end** e **Dispositivos Móveis**.

Java 21 · Spring Boot 3.5 · Spring Security (JWT) · JPA/Hibernate · MySQL 8 (H2 em modo MySQL para testes) · WebSocket · Swagger.

## Rodar localmente

Precisa de JDK 21 e Maven (ou abra no IntelliJ/VS Code e rode `DoaApiApplication`).

```bash
mvn spring-boot:run
```

Sem configurar nada, usa o banco H2 em memória e cria dados de demonstração. Abra:

| O quê | Endereço |
|---|---|
| Página inicial | http://localhost:8080 |
| Swagger (todas as rotas) | http://localhost:8080/swagger-ui.html |
| Demonstração do WebSocket | http://localhost:8080/ws-demo/index.html |

### Com MySQL (Docker)

```bash
docker compose up --build
```

### Contas de teste

| E-mail | Senha | Perfil |
|---|---|---|
| admin@doa.com | admin123 | Administrador |
| doador@doa.com | doador123 | Doador (Maria) |
| mercado@doa.com | mercado123 | Doador (Supermercado) |
| ong@doa.com | ong123 | Instituição aprovada (aceita todas as categorias) |
| ong2@doa.com | ong123 | Instituição pendente de aprovação |

Em produção use `SEED_DEMO=false` e defina `ADMIN_EMAIL` e `ADMIN_PASSWORD`.

## Testar o chat sem o app

Com os dados de demonstração, já existe a doação **#8 (Pães de forma, da Maria)**, reservada pela instituição Esperança e com duas mensagens. Para testar:

1. Abra `http://localhost:8080/ws-demo/index.html` **em duas janelas** (a segunda de preferência anônima).
2. Janela 1: escolha **Doador (Maria)** e clique em *Entrar e conectar*.
3. Janela 2: escolha **Instituição (Esperança)** e clique em *Entrar e conectar*.
4. Nas duas, a doação #8 aparece na lista do chat com o histórico. Escreva numa janela e a mensagem chega na outra na hora.

Para criar uma conversa nova, reserve outra doação pelo Swagger: entre como `ong@doa.com`, use `GET /api/donations?radiusKm=100` para ver os IDs e `POST /api/donations/{id}/request` para reservar. Depois, na página de demonstração, use o doador dono daquela doação (as doações #1 a #6 são do Supermercado; #7 e #8, da Maria). As doações reservadas aparecem sozinhas na lista do chat.

O banco H2 é em memória: a cada reinício os dados voltam ao estado inicial.

## Variáveis de ambiente

| Variável | Para quê | Padrão |
|---|---|---|
| `PORT` | Porta HTTP (o Render define sozinho) | 8080 |
| `SPRING_PROFILES_ACTIVE` | `mysql` liga o MySQL (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSL`) | H2 em memória |
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://host:3306/doa?...` (alternativa ao perfil) | H2 em memória |
| `SPRING_DATASOURCE_USERNAME` / `SPRING_DATASOURCE_PASSWORD` | Acesso ao banco | `sa` / vazio |
| `JWT_SECRET` | Segredo do token (mín. 32 caracteres). **Troque em produção** | valor de desenvolvimento |
| `SEED_DEMO` | Cria usuários e doações de exemplo | `true` |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | Administrador criado se não existir | admin@doa.com / admin123 |
| `FCM_CREDENTIALS_JSON` | Conteúdo do JSON da conta de serviço do Firebase (push) | desligado |

## Push notifications (Firebase)

1. No console do Firebase, crie um projeto e adicione o app Android.
2. Em **Configurações do projeto → Contas de serviço**, gere uma chave privada (JSON).
3. Coloque o conteúdo inteiro do JSON na variável `FCM_CREDENTIALS_JSON`. Nunca versione esse arquivo.
4. O app envia o token do aparelho em `PUT /api/users/me/fcm-token`. A partir daí, cada evento (doação nova, reserva, entrega...) vira push.

Sem a variável, o push fica desligado e o restante funciona normalmente.

## Publicar de graça (Render + Neon)

1. **Banco:** crie um projeto no [Neon](https://neon.tech), copie host, banco, usuário e senha.
2. **API:** no [Render](https://render.com), crie um *Web Service* a partir do repositório, ambiente **Docker**, plano **Free**.
3. Em *Environment*, defina `SPRING_DATASOURCE_URL` (`jdbc:mysql://HOST:3306/BANCO?useSSL=true`), `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `JWT_SECRET` e, se quiser, `SEED_DEMO=true` para a apresentação.
4. O plano gratuito dorme após ~15 min sem uso e a primeira requisição demora cerca de um minuto. **Acesse a URL alguns minutos antes de apresentar.**

Confira limites e preços atuais dos planos gratuitos antes de publicar, porque eles mudam.

## Testes

```bash
mvn test
```

- `DoaFlowTest`: fluxo completo (login, bloqueio, permissões, doação até o estoque, limite de 5, N:N).
- `DocumentValidatorTest`: CPF, CNPJ e distância.
- Testes funcionais da API: importe `postman/Doa-API.postman_collection.json` no Postman (ou Thunder Client). Rode a pasta 1 primeiro, que salva os tokens, e depois as demais em ordem.

## Mapa para os critérios da disciplina de Back-end

| Critério | Onde está |
|---|---|
| CR1: documento | `docs/MODELO.md` e `docs/API.md` (exportar para PDF) |
| CR2 a CR5: CRUD de 4 entidades com ORM | Donor, Institution, Donation, FoodCategory (controllers em `web/`, entidades em `domain/`) |
| CR6: um-para-muitos | Donor → Donation |
| CR7: muitos-para-muitos | Institution ↔ FoodCategory (`institution_category`) |
| CR8: WebSocket | `ws/` e `static/ws-demo/index.html` |
| CR9: testes funcionais | `postman/` + capturas de tela da execução |

## Estrutura

```
src/main/java/br/edu/ifsp/doa/api/
├── config/      segurança, WebSocket, Swagger, dados de exemplo
├── domain/      entidades JPA e enums
├── repository/  Spring Data
├── service/     regras de negócio, notificações e push
├── web/         controllers REST, DTOs e tratamento de erros
├── security/    JWT, filtro e lista de tokens revogados
├── ws/          servidor WebSocket
└── util/        validação de CPF/CNPJ e distância
```

## Limitações conhecidas

- O logout guarda os tokens revogados em memória (vale para uma instância só).
- O esquema do banco é gerado pelo Hibernate (`ddl-auto=update`); para algo além do trabalho, use migrações (Flyway).
- A distância usa latitude e longitude enviadas pelo app (GPS); não há conversão de endereço em coordenadas.
- Não há consulta do CNPJ na Receita: só a validação dos dígitos.


## MySQL e fotos das doações

- **Subir tudo local:** `docker compose up --build` (MySQL 8.4 + API; perfil `mysql`). Sem Docker: crie o banco/usuário e rode
  `SPRING_PROFILES_ACTIVE=mysql DB_HOST=localhost DB_USER=... DB_PASSWORD=... mvn spring-boot:run`.
- **Tabelas:** o Hibernate cria/ajusta sozinho (`DDL_AUTO=update`). O script `docs/mysql/schema.sql` documenta o esquema
  completo (inclui `donation_photos`) e serve para criar o banco à mão (use `DDL_AUTO=validate`).
- **Fotos:** `POST /api/donations/{id}/photos` (multipart, campo `file`). O arquivo fica em `donation_photos.data` (LONGBLOB),
  porque hospedagens gratuitas apagam o disco. A imagem é servida em `GET /api/photos/{uuid}`.
