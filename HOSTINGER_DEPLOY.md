# Deploy na Hostinger - Casa do Pai

## Arquivo Pronto para Upload

**Arquivo**: `dist.zip` (1.2 MB)  
**Localização**: `c:\Users\gmsilva\Desktop\SISTEMAS\_RODANDO\casa_do_pai\dist.zip`  
**Build Date**: 2026-07-14  
**Status**: ✅ Pronto para deploy

---

## Conteúdo do Build

O arquivo `dist.zip` contém:

```
dist/
├── index.html                 (Arquivo principal da aplicação)
├── assets/                    (Arquivos compilados de JS/CSS)
│   ├── *.js                   (Chunks de JavaScript)
│   └── *.css                  (Estilos compilados)
├── .htaccess                  (Configurações do Apache)
├── favicon.ico, favicon.svg   (Ícones)
├── patterns/                  (Padrões SVG)
├── sounds/                    (Áudios)
└── [outros arquivos estáticos]
```

---

## Instruções de Upload na Hostinger

### Opção 1: Via Gerenciador de Arquivos (Painel Hostinger)

1. **Acesse o Painel Hostinger**
   - URL: https://hpanel.hostinger.com
   - Faça login com suas credenciais

2. **Navegue para Gerenciador de Arquivos**
   - Menu → Arquivos → Gerenciador de Arquivos
   - Acesse a pasta `public_html` (ou a pasta do seu domínio)

3. **Delete o conteúdo antigo** (IMPORTANTE!)
   - Selecione todos os arquivos atuais
   - Clique em "Deletar"
   - **NÃO delete o .htaccess se houver configurações customizadas**

4. **Upload do novo dist.zip**
   - Clique em "Upload"
   - Selecione o arquivo `dist.zip`
   - Aguarde o upload completar

5. **Extraia o ZIP**
   - Clique com botão direito no `dist.zip`
   - Selecione "Extrair aqui" ou "Descompactar"
   - Mova todos os arquivos da pasta `dist` para `public_html` (um nível acima)

6. **Delete o dist.zip**
   - Após extrair, delete o arquivo `dist.zip`
   - Verifique se todos os arquivos estão em `public_html`

7. **Teste a aplicação**
   - Acesse seu domínio no navegador
   - Verifique se tudo carregou corretamente

---

### Opção 2: Via FTP (FileZilla ou similares)

1. **Obtenha credenciais FTP** no painel Hostinger
   - Menu → Contas → Contas FTP
   - Crie ou copie credenciais existentes

2. **Conecte via FTP**
   - Host: `ftp.seudominio.com.br`
   - Usuário: [seu usuário FTP]
   - Senha: [sua senha FTP]
   - Porta: 21

3. **Navegue para `public_html`**
   - Localize e abra a pasta `public_html`

4. **Delete conteúdo antigo**
   - Selecione todos os arquivos
   - Clique em "Deletar"

5. **Upload do dist.zip**
   - Arraste o `dist.zip` para `public_html`
   - Aguarde upload completar

6. **Extraia na Hostinger**
   - Acesse o Gerenciador de Arquivos do painel
   - Clique com botão direito no `dist.zip`
   - Selecione "Extrair"
   - Mova arquivos para `public_html` se necessário

7. **Teste a aplicação**
   - Acesse seu domínio

---

### Opção 3: Via Hostinger Git Integration (Recomendado para futuras atualizações)

1. **Configure GitHub**
   - Push seu código para um repositório GitHub

2. **No Painel Hostinger**
   - Menu → Configurações Git
   - Conecte seu repositório GitHub

3. **Faça deploy**
   - Selecione branch `main`
   - Defina pasta de deploy como `dist`
   - Clique em "Deploy"

4. **Futuras atualizações**
   - Push para GitHub
   - Hostinger faz deploy automaticamente

---

## Checklist Pré-Deploy

- [x] Build completado com sucesso (`npm run build`)
- [x] Nenhum erro de TypeScript
- [x] dist.zip criado (1.2 MB)
- [x] StatusTimeline component integrado
- [x] Realtime funcionando
- [ ] Configuração de ambiente checada (.env)
- [ ] URL da API do Supabase corrigida se necessário
- [ ] CORS configurado corretamente
- [ ] Certificado SSL ativado

---

## Pós-Deploy - Verificações

1. **Teste a aplicação**
   - Abra `https://seudominio.com.br`
   - Verifique se carrega sem erros

2. **Teste funcionalidades principais**
   - Fazer um pedido (delivery)
   - Verificar se StatusTimeline aparece na confirmação
   - Testar atualização de status em tempo real

3. **Verifique o console do navegador**
   - F12 → Console
   - Não deve haver erros críticos

4. **Teste em mobile**
   - Abra em celular
   - Verifique responsividade

5. **Verifique HTTPS**
   - Deve ter cadeado 🔒 verde na barra de URL

---

## Configurações Recomendadas no Painel Hostinger

### Cache
- Menu → Configurações → Cache
- Ativar "Cache de Página Estática"
- TTL: 24 horas (ou conforme necessário)

### Compressão
- Menu → Configurações → Compressão
- Ativar "Compressão Gzip"

### SSL
- Menu → Certificados SSL
- Verificar se "Let's Encrypt" está ativado
- Forçar HTTPS se possível

---

## Troubleshooting

### "Página não encontra nada"
- Verifique se o `index.html` está em `public_html`
- Adicione a seguinte linha ao `.htaccess`:
  ```apache
  <IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteRule ^index\.html$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.html [L]
  </IfModule>
  ```

### "Assets não carregam (404)"
- Verifique se a pasta `assets` está em `public_html`
- Verifique o console do navegador (F12) para ver URLs dos assets

### "Realtime não funciona"
- Verifique se as credenciais do Supabase estão corretas
- Verifique conectividade WebSocket (não bloqueado por firewall)
- Teste em modo incógnito

### "CORS errors"
- Verifique configurações CORS no Supabase
- Adicione seu domínio às origens permitidas

---

## Informações de Rollback

Se houver problemas após o deploy:

1. **Baixe a versão anterior**
   - Se você tiver um backup, extraia-o

2. **Reupload via Gerenciador de Arquivos**
   - Delete os novos arquivos
   - Upload da versão anterior

3. **Limpe o cache**
   - No painel Hostinger: Menu → Cache → Limpar Cache
   - No navegador: Ctrl+Shift+Delete (limpar cache)

---

## Contato Suporte Hostinger

- **Chat ao vivo**: Disponível no painel Hostinger
- **Email**: support@hostinger.com.br
- **Central de Ajuda**: https://www.hostinger.com.br/ajuda

---

**Última Atualização**: 2026-07-14  
**Versão da Aplicação**: Casa do Pai v1.0 + StatusTimeline  
**Status**: Pronto para Deploy ✅
