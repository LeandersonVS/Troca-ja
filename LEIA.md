# 🔄 Troca Já

**Você tem algo parado. Alguém tem algo que você precisa. Troque.**

Troca Já é uma plataforma brasileira de troca de produtos entre pessoas. Em vez de comprar e vender, os usuários cadastram itens parados em casa, encontram produtos de outras pessoas e propõem trocas diretas — com sistema de match, chat e reputação.

Este repositório contém um **protótipo de front-end navegável** (`troca-ja.html`), com todas as telas e fluxos principais implementados usando dados mockados em memória.

---

## 📦 O que está incluído

Um único arquivo HTML autocontido (`troca-ja.html`) — HTML + CSS + JavaScript puro, sem build step, sem dependências além de uma fonte do Google Fonts. Basta abrir no navegador.

### Telas implementadas
- Landing page (hero, como funciona, categorias, CTA)
- Login / Cadastro / Recuperação de senha (com login social mock)
- Feed de produtos (busca, filtros por categoria, seções "Recomendados", "Perto de você", "Novidades")
- Detalhes do produto
- Cadastrar produto
- Meus produtos (com estatísticas e status: ativo / em negociação / trocado)
- Matches
- Chat (com respostas automáticas simuladas e banner de segurança)
- Perfil (próprio e de terceiros, com reputação)
- Notificações
- Configurações
- Painel administrativo

### Fluxos funcionais (com dados mockados)
- Cadastro/login → redireciona para o feed
- "Tenho interesse" em um produto → modal para escolher o que oferecer em troca → proposta enviada
- Simulação de aceite da outra parte → **animação de Match** 🎉
- Chat liberado após o match, com envio de mensagens e resposta automática simulada
- Ações rápidas: pausar/excluir produto, bloquear/denunciar usuário, compartilhar produto (todas via toast de feedback)

> ⚠️ **Importante:** não há backend, banco de dados ou persistência real. Tudo roda no navegador, em memória (`DB` no JavaScript), e os dados são perdidos ao recarregar a página. É uma prova de conceito de produto e experiência, não uma aplicação em produção.

---

## 🎨 Identidade visual

| Elemento | Valor |
|---|---|
| Azul vibrante | `#2563EB` |
| Verde/teal | `#14B8A6` |
| Fundo claro | `#F8FAFC` |
| Texto principal | `#0F172A` |
| Cinza secundário | `#64748B` |
| Ação positiva | `#22C55E` |

- Tipografia: **Sora** (display) + **Inter** (texto)
- Logo: duas setas formando um ciclo de troca
- Cards com cantos arredondados, sombras suaves e gradiente azul → teal
- Design mobile-first, com barra de navegação inferior no estilo app

---

## ▶️ Como rodar

Não precisa de instalação. Basta abrir o arquivo diretamente no navegador:

```bash
open troca-ja.html      # macOS
start troca-ja.html     # Windows
xdg-open troca-ja.html  # Linux
```

Ou publicar como um arquivo estático em qualquer host (Vercel, Netlify, GitHub Pages, S3 etc.).

---

## 🗂️ Estrutura do código

Tudo em um único arquivo (`troca-ja.html`), organizado em blocos:

```
<style>          → design system (variáveis CSS, componentes)
<script>
  DB              → dados mockados (usuários, produtos, matches, mensagens, notificações)
  state           → estado da aplicação (tela atual, login, modais)
  render()        → roteador simples que troca a tela renderizada
  Screen*()       → uma função por tela (ScreenLanding, ScreenFeed, ScreenChat, ...)
  attachHandlers() → liga os eventos de clique/submit depois de cada render
```

Navegação entre telas é feita via `nav(nome_da_tela, params)`, sem framework — um roteador simples via `data-nav` nos elementos.

---

## 🚀 Próximos passos para virar um SaaS real

Este protótipo cobre a experiência de produto. Para se tornar uma aplicação em produção, faltam:

**Frontend**
- Migrar para React/Next.js + TypeScript + Tailwind (estrutura de componentes reutilizáveis: `Button`, `ProductCard`, `ChatBubble`, `MatchCard`, etc.)
- Upload real de imagens (com preview, compressão e limite de 8 fotos)

**Backend**
- API REST (ou serverless) com autenticação (e-mail/senha + Google OAuth)
- Banco de dados PostgreSQL com as entidades: `Users`, `Products`, `Categories`, `ProductImages`, `Interests`, `TradeProposals`, `Matches`, `Chats`, `Messages`, `Notifications`, `Reviews`, `Reports`, `Favorites`, `TradeHistory`
- Storage de imagens (produtos e avatares)
- Chat em tempo real (WebSocket ou serviço gerenciado tipo Pusher/Ably)
- Sistema de notificações (push e e-mail)

**Confiança e segurança**
- Verificação de e-mail
- Moderação de conteúdo e detecção de anúncios suspeitos
- Sistema de denúncias e bloqueio com fila de moderação
- Sistema de reputação (avaliações de 1 a 5 estrelas pós-troca)

**Painel administrativo**
- Métricas reais (usuários, produtos, matches, trocas, denúncias) com gráficos
- Gerenciamento de usuários, produtos, categorias, denúncias e avaliações

---

## 📄 Licença

Protótipo de produto — uso livre para fins de estudo, apresentação ou como base de um MVP.
