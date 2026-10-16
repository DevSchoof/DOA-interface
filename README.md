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

Em desenvolvimento: **Sprint 1** (autenticação e cadastro de doadores).

Enquanto a API em Java não está integrada, o app usa serviços simulados (mock) em `lib/services/`, que serão trocados pela API real sem alterar as telas.

## Tecnologias

**Front-end (este repositório)**
- [Flutter](https://flutter.dev) e Dart
- `provider` (estado)
- `go_router` (navegação)
- `http` (comunicação com a API)
- `flutter_secure_storage` (armazenamento da sessão)

**Back-end** (repositório separado)
- Java (API REST)
- PostgreSQL com PostGIS

## Estrutura

```
lib/
├── models/      # modelos de dados e enums
│   └── enums/
└── services/    # interfaces dos serviços e implementações mock
docs/            # documentação e contrato da API
```

## Como executar

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.

```bash
git clone <URL_DO_REPOSITORIO>
cd doa_interface
flutter pub get
flutter run -d chrome
```

Contas de teste (dados simulados):

| E-mail | Senha | Perfil |
|---|---|---|
| admin@doa.com | admin123 | Administrador |
| doador@doa.com | doador123 | Doador |
| ong@doa.com | ong123 | Instituição |

## Testes

```bash
flutter analyze
flutter test
```

## Equipe

- Áquila Matheus de Oliveira
- Eduardo Schoof