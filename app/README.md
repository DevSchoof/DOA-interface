# Dôa

**Plataforma Digital de Combate à Fome e ao Desperdício de Alimentos**

Projeto da disciplina *Projeto de Tecnologia da Informação e Comunicação*, do curso de Tecnologia em Análise e Desenvolvimento de Sistemas.

## Sobre o projeto

O Brasil convive com insegurança alimentar e, ao mesmo tempo, com grande desperdício de alimentos. O Dôa é uma plataforma de intermediação que conecta **doadores** (pessoas físicas e empresas) a **instituições receptoras** (ONGs e grupos comunitários), com controle de ofertas, geolocalização, notificações e medição de impacto social.

Este repositório contém o **aplicativo (front-end) em Flutter**. O **back-end (API em Java)** fica em outro repositório: [doa-api](URL_DO_REPOSITORIO_DO_BACK). O contrato entre os dois está em [`docs/API.md`](docs/API.md).

> Decisão posterior à declaração de escopo: o front-end passou de PWA em React para Flutter, e o back-end será desenvolvido em Java.

## Módulos

1. **Autenticação e Segurança:** login, logout, cadastro de usuários e controle de acesso por perfil (Doador, Instituição e Administrador).
2. **Gestão de Doadores:** cadastro de pessoa física ou jurídica.
3. **Gestão de Instituições:** cadastro, homologação pelo administrador e listagem.
4. **Ofertas e Reservas:** publicação, reserva, confirmação de coleta e cancelamento.
5. **Logística e Mapa:** ofertas geolocalizadas, filtro por raio e rota sugerida.
6. **Notificações e Comunicação:** alertas, notificações push e chat.
7. **Relatórios e Impacto Social:** dashboard de impacto, relatórios e painel administrativo.

## Planejamento

O projeto segue Scrum, com 8 sprints de 2 semanas (16 semanas), 26 user stories e 140 story points.

| Fase | Sprints | Entrega |
|---|---|---|
| 1. Fundação | 1 e 2 | Autenticação, doadores e instituições |
| 2. MVP | 3 e 4 | Ciclo completo de doação |
| 3. Logística | 5 e 6 | Mapa, filtro por raio e notificações (Beta) |
| 4. Entrega | 7 e 8 | Chat, dashboard, relatórios (Release 1.0) |

A documentação (escopo, backlog, planejamento das sprints e contrato da API) está na pasta [`docs/`](docs/).

## Status

App integrado à API: login e cadastro público, perfil de doador e de instituição (com as categorias aceitas e a localização por GPS), doações (criar, editar, excluir, cancelar), busca por categoria, raio e proximidade, solicitação e confirmação de recebimento, estoque com alertas, impacto social, aprovação de instituições e gestão de categorias pelo administrador. O chat e as notificações chegam em tempo real pelo WebSocket.

**Recursos nativos usados:** geolocalização (GPS). **Falta:** push notifications (Firebase), mapa e rota (RF09/RF10), relatórios (RF15/RF18), login social (RF04) e foto da doação.

## Como falar com a API

A camada de rede está em `lib/core/api_client.dart` e as implementações HTTP em `lib/services/http/`. As telas só conhecem as interfaces (`lib/services/*.dart`).

| Onde o app roda | Endereço da API (padrão) |
|---|---|
| Chrome / desktop | `http://localhost:8080` |
| Emulador Android | `http://10.0.2.2:8080` |
| Celular físico | informe o IP do computador na mesma rede Wi-Fi |
| API publicada | informe a URL (ex.: `https://doa-api.onrender.com`) |

Para trocar o endereço:

```bash
flutter run --dart-define=API_URL=http://192.168.0.10:8080
```

Suba a API antes (veja o repositório do back-end). Com os dados de demonstração, entre com `admin@doa.com` / `admin123`, `doador@doa.com` / `doador123` ou `ong@doa.com` / `ong123`.

## Tecnologias

**Front-end (este repositório)**
- [Flutter](https://flutter.dev) e Dart
- `provider` (estado)
- `go_router` (navegação)
- `http` (comunicação com a API)
- `web_socket_channel` (chat e notificações em tempo real)
- `geolocator` (GPS)
- `flutter_secure_storage` (armazenamento da sessão)

**Back-end** (repositório separado)
- Java 21 com Spring Boot (API REST e WebSocket)
- PostgreSQL

## Estrutura

```
lib/
├── core/        # responsividade, formatação, validação (CPF/CNPJ), loaders
├── models/      # modelos de dados e enums
│   └── enums/
├── providers/   # estado (sessão, perfil e conexão em tempo real)
├── services/    # interfaces dos serviços
│   └── http/    # implementações que falam com a API
├── screens/     # telas
└── widgets/     # shell de navegação responsivo e componentes
docs/            # documentação e contrato da API
```

## Como executar

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.

```bash
git clone https://github.com/DevSchoof/DOA-interface
cd doa_interface
flutter pub get
flutter run -d chrome
```

Contas de teste (criadas pela API com `SEED_DEMO=true`):

| E-mail | Senha | Perfil |
|---|---|---|
| admin@doa.com | admin123 | Administrador |
| doador@doa.com | doador123 | Doador (Maria) |
| mercado@doa.com | mercado123 | Doador (Supermercado) |
| ong@doa.com | ong123 | Instituição aprovada (aceita todas as categorias) |
| ong2@doa.com | ong123 | Instituição pendente de aprovação |

Para ver o cadastro do zero, use **Cadastre-se** na tela de login. Doador: CPF de teste `111.444.777-35`. Instituição: CNPJ de teste `12.345.678/0001-95` e escolha as categorias aceitas; depois entre como admin e aprove. A doação #8 (Pães de forma) já está reservada e com conversa, então o chat pode ser testado entre `doador@doa.com` e `ong@doa.com`.

## Testes

```bash
flutter analyze
flutter test
```

## Equipe

- Áquila Matheus de Oliveira
- Eduardo Schoof