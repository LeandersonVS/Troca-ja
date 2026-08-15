# Setup Supabase — Troca Já

Passo a passo pra quem tem acesso à conta Supabase. Leva ~5 minutos, sem precisar entender o projeto.

## 1. Criar o projeto (pule se já existe)

1. Acesse [supabase.com](https://supabase.com) → **New project**.
2. Nome: `troca-ja` (ou qualquer nome). Região: `South America (São Paulo)`.
3. Guarde a senha do banco em local seguro.

## 2. Rodar o schema

1. No menu lateral do projeto: **SQL Editor** → **New query**.
2. Abra o arquivo [`supabase/schema.sql`](./supabase/schema.sql) deste repositório, copie todo o conteúdo, cole no editor.
3. Clique **Run**. Deve terminar sem erro (cria tabelas, triggers, regras de segurança, bucket de fotos e realtime do chat).
4. Pode rodar de novo sem problema — o script é idempotente.

## 3. Login imediato após cadastro (recomendado)

Por padrão o Supabase exige confirmação de e-mail antes do primeiro login.
Para o usuário entrar direto após criar a conta:

1. **Authentication → Sign In / Providers → Email**.
2. Desative **Confirm email**.

Se preferir manter a confirmação ativa, o app já trata isso: mostra a tela "Confirme seu e-mail" após o cadastro.

> Login com Google **não** é usado neste projeto — não precisa configurar provider nenhum além de Email.

## 4. Pegar as credenciais e enviar

1. **Project Settings** (engrenagem) → **Data API** (ou **API Keys**).
2. Copie:
   - **Project URL** (ex: `https://abcxyzproj.supabase.co`)
   - **Publishable key** (começa com `sb_publishable_...`)
3. Envie esses dois valores pra quem está configurando o front-end (`index.html`).

> Esses dois valores são seguros de compartilhar — são a chave pública do Supabase, protegida pelas regras de segurança (RLS) criadas no passo 2. **Nunca** envie a `service_role`/`secret key` nem a senha do banco.

## 5. Adicionar domínio da Vercel (depois do deploy)

1. **Authentication → URL Configuration**.
2. Em **Site URL** e **Redirect URLs**, adicione a URL do deploy na Vercel (ex: `https://troca-ja.vercel.app`). Isso é necessário para o link de recuperação de senha voltar pro app.

---

Pronto. Quem estiver com o `index.html` só precisa conferir as constantes `SUPABASE_URL` e `SUPABASE_ANON_KEY` no topo do `<script>`.
