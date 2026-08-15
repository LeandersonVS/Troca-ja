# 🔄 Troca Já

**Você tem algo parado. Alguém tem algo que você precisa. Troque.**

Troca Já é uma plataforma brasileira de troca de produtos entre pessoas. Em vez de comprar e vender, os usuários cadastram itens parados em casa, encontram produtos de outras pessoas e propõem trocas diretas — com sistema de match, chat em tempo real e reputação.

## Arquitetura

- **Front-end**: `index.html` único (HTML + CSS + JS puro, sem build step), servido estático pela **Vercel**.
- **Back-end**: **Supabase** (Postgres + Auth + Storage + Realtime) — sem servidor próprio.
- **Segurança**: toda autorização é feita por Row Level Security no Postgres. A chave usada no front é a `publishable/anon key`, pública por design.

```
index.html            → app completo (design system + telas + integração Supabase)
supabase/schema.sql   → tabelas, triggers, RLS, storage e realtime (rodar 1x no SQL Editor)
SETUP.md              → passo a passo para quem administra a conta Supabase
```

## Funcionalidades

- Cadastro e login reais (e-mail/senha), recuperação de senha
- Anúncio de produtos com até 8 fotos (Supabase Storage)
- Feed público com busca e filtro por categoria
- Proposta de troca: escolha um produto seu para oferecer
- Aceite → **match automático** (trigger no banco) + notificações
- Chat em tempo real entre participantes do match (Supabase Realtime)
- Perfil com reputação, edição de perfil e avatar
- Gestão de anúncios: pausar, reativar, marcar como trocado, excluir

## Design system

Estrutura de tokens inspirada em marketplaces consumer (canvas branco, uma cor de marca usada com parcimônia, tipografia contida, uma única camada de sombra). Identidade: **verde + preto**.

| Token | Valor |
|---|---|
| Verde (marca) | `#00843D` |
| Verde pressionado | `#006B31` |
| Preto (ink) | `#111111` |
| Texto secundário | `#6A6A6A` |
| Hairline | `#DDDDDD` |
| Erro | `#C13515` |
| Raios | 4 / 8 / 14 / 20 / full |
| Fonte | Inter (400–800) |

## Rodando

1. Siga o [SETUP.md](./SETUP.md) para configurar o projeto Supabase (rodar `supabase/schema.sql`).
2. Confirme que `SUPABASE_URL` e `SUPABASE_ANON_KEY` no topo do `<script>` do `index.html` apontam para o seu projeto.
3. Local: `python3 -m http.server 8080` e abra `http://localhost:8080`.
4. Deploy: importe o repositório na Vercel (framework: **Other**, sem build). Depois adicione a URL do deploy em **Supabase → Authentication → URL Configuration**.

## Licença

Uso livre para fins de estudo, apresentação ou como base de um MVP.
