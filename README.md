# Dôa — plataforma de doação de alimentos

Conecta **doadores** (mercados, restaurantes, pessoas) a **instituições** que recebem alimentos, evitando desperdício.

Projeto acadêmico (BRADEMO — Mobile, BRADWBK — Back-end, Projeto de TIC).
Autores: Áquila Matheus de Oliveira (BP3054306) e Eduardo Schoof (BP3060357).

## Estrutura
| Pasta | Conteúdo |
|---|---|
| `backend/` | API REST em Spring Boot 3.5 / Java 21 (JWT, JPA, WebSocket, Swagger, FCM) |
| `app/` | Aplicativo Flutter/Dart (Provider, go_router, camada de rede, push, câmera/galeria, GPS) |
| `banco/` | Scripts MySQL: `criar-usuario.sql` (cria o banco e o usuário) e `schema.sql` (tabelas, versão manual) |
| `backend/postman/` | Coleção Postman (61 requisições com testes automáticos) |
| `backend/docs/` | `API.md` (especificação), `MODELO.md` (modelo de dados) e `mysql/schema.sql` |

## Funcionalidades
Cadastro/login com perfis (doador, instituição, admin) · edição do próprio cadastro · CRUD de doações com até 5 fotos · categorias · busca por categoria e raio (distância por GPS) · solicitações/reserva (expira em 24 h) · estoque · chat em tempo real (WebSocket) · notificações push (FCM) · impacto do doador · aprovação de instituições pelo admin.

## Modelo de dados
`users`, `donors`, `institutions`, `food_categories`, `donations`, `donation_photos`, `stock_items`, `messages` e a tabela de junção `institution_category`.
Relações: Doador 1:N Doação · Doação 1:N Fotos · Instituição 1:N Estoque · Instituição N:N Categoria.

## Pré-requisitos
- Java 21 e Maven (ou o Maven embutido da IDE)
- Flutter SDK e Android Studio (emulador "Google Play" para testar push)
- MySQL 8 **ou** Docker Desktop

## Como rodar
Ordem: **banco → API → app**.

### 1. Banco de dados (escolha uma opção)

**A) Docker — sobe banco e API juntos**
```
cd backend
docker compose up --build
```
MySQL em `localhost:3306` e API em http://localhost:8080. Pule para o passo 3.

**B) MySQL instalado**
Abra o MySQL (Workbench ou terminal) como root e rode o script `banco/criar-usuario.sql` (`mysql -u root -p < banco/criar-usuario.sql`), que executa:
```sql
CREATE DATABASE IF NOT EXISTS doa CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER IF NOT EXISTS 'doa'@'%' IDENTIFIED BY 'doa';
GRANT ALL PRIVILEGES ON doa.* TO 'doa'@'%';
FLUSH PRIVILEGES;
```
As tabelas são criadas pela API na primeira execução. O script `banco/schema.sql` é a versão manual (use `DDL_AUTO=validate` se criar as tabelas à mão).

**C) Sem MySQL (teste rápido)**
Não configure nada: a API usa H2 em memória, que zera a cada reinício.

### 2. API (opções B e C)
```
cd backend
mvn test                       # opcional
```
Com MySQL (PowerShell):
```
$env:SPRING_PROFILES_ACTIVE="mysql"
$env:DB_HOST="localhost"; $env:DB_USER="doa"; $env:DB_PASSWORD="doa"
$env:FCM_CREDENTIALS_PATH="C:\caminho\fora-do-repo\firebase-chave.json"   # só para push
mvn spring-boot:run
```
Sem MySQL: apenas `mvn spring-boot:run`.

- Swagger: http://localhost:8080/swagger-ui.html
- Demo do WebSocket (chat): http://localhost:8080/ws-demo/index.html

### 3. App (Flutter)
```
cd app
flutter pub get
flutter analyze                # opcional
flutter test                   # opcional
```
- **Chrome:** `flutter run -d chrome` (usa http://localhost:8080)
- **Emulador Android:** `flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:8080`
- **Celular físico (mesma rede Wi-Fi):** `flutter run --dart-define=API_URL=http://IP_DO_PC:8080` (libere a porta 8080 no firewall)

O caminho da pasta do projeto não pode ter acentos (limitação do Gradle no Windows).

**Localização (botão "Usar minha localização")**
- Emulador Android: botão **⋯** → **Location** → informe latitude/longitude → **Set Location**, e só depois toque no botão.
- Chrome: F12 → ⋮ → **More tools** → **Sensors** → **Location** → defina um ponto e permita a localização no aviso do navegador.

**Push (FCM):** só funciona no Android, com `google-services.json` em `app/android/app/` e a chave do Firebase configurada na API (`FCM_CREDENTIALS_PATH`).

## Contas de demonstração
Criadas automaticamente na primeira execução da API.

| Perfil | E-mail | Senha |
|---|---|---|
| Admin | admin@doa.com | admin123 |
| Doador | doador@doa.com | doador123 |
| Doador | mercado@doa.com | mercado123 |
| Instituição (aprovada) | ong@doa.com | ong123 |
| Instituição (pendente) | ong2@doa.com | ong123 |

## Roteiro rápido de teste
1. Entre como `doador@doa.com` → **Nova doação** (com foto da câmera/galeria).
2. Entre como `ong@doa.com` → **Buscar doações** → **Solicitar** (com o app em segundo plano, deve chegar o push).
3. Abra o chat da doação reservada nos dois perfis.
4. A instituição confirma o recebimento → o item aparece em **Estoque**.
5. Entre como `admin@doa.com` → **Instituições** (aprovar `ong2@doa.com`) e **Categorias**.

## Testes da API (Postman)
1. Importe `backend/postman/Doa-API.postman_collection.json`.
2. Com a API no ar, rode a pasta **1. Autenticação** primeiro (ela salva os tokens) e depois as demais em ordem, ou use o **Runner** na coleção inteira.
3. As requisições de foto usam `form-data`: selecione uma imagem no campo `file` antes de rodar.

## Documentação
- API: `backend/docs/API.md` e Swagger em `/swagger-ui.html`
- Modelo de dados: `backend/docs/MODELO.md`
- Protótipo Figma: https://www.figma.com/design/l6tBYDLJyGlIXEHxyTjQeZ

## Problemas comuns
- **"Não foi possível conectar ao servidor":** API fora do ar ou URL errada (o emulador usa `10.0.2.2`, não `localhost`).
- **API não conecta no MySQL:** confira `DB_USER`/`DB_PASSWORD` e se o MySQL está na porta 3306.
- **Não chega push:** use emulador com Google Play, aceite a permissão de notificação e confira `FCM_CREDENTIALS_PATH`.
- **Doador sem latitude/longitude:** a localização não foi capturada antes de salvar o cadastro.

## Segurança
O `google-services.json` e a chave de conta de serviço do Firebase **não** são versionados: cada pessoa usa o seu. Em produção, troque `JWT_SECRET` e a senha do admin (`ADMIN_PASSWORD`).
