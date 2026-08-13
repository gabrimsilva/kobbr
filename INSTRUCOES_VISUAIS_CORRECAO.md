# 📸 Instruções Visuais: Como Diagnosticar e Corrigir

## 🎯 Objetivo
Corrigir o erro ao mudar status do pedido no Kanban.

---

## 📍 ETAPA 1: Verificar o Erro no Navegador

### 1.1 Abrir DevTools
```
Pressione: F12
ou
Clique com botão direito → Inspecionar
```

### 1.2 Ir para aba Console
```
DevTools → Console (primeira aba)
```

### 1.3 Tentar Mudar Status
```
1. Arraste um pedido de "Novos Pedidos" para "Em Separação"
2. Observe o console
```

### 1.4 O Que Você Deve Ver (SUCESSO):
```
🎯 Iniciando atualização de status: { pedidoId: "abc123", novoStatus: "Preparando" }
🔄 Atualizando status do pedido: { pedidoId: "abc123", novoStatus: "Preparando" }
📤 Dados do update: { status: "Preparando", atualizado_em: "2026-03-06T..." }
📥 Resposta do Supabase: { sucesso: true, pedidoAtualizado: "abc123", novoStatus: "Preparando" }
✅ Status atualizado com sucesso

+ Toast verde no canto superior direito: "Status atualizado para: Preparando"
```

### 1.5 O Que Você Pode Ver (ERRO):
```
🎯 Iniciando atualização de status: { ... }
🔄 Atualizando status do pedido: { ... }
📤 Dados do update: { ... }
❌ Erro detalhado ao atualizar status: {
  message: "new row violates check constraint",
  code: "23514",
  details: "..."
}

+ Toast vermelho: "Erro ao atualizar status do pedido"
```

---

## 📍 ETAPA 2: Verificar Requisições HTTP

### 2.1 Ir para aba Network
```
DevTools → Network (segunda aba)
```

### 2.2 Filtrar Requisições
```
No campo de busca, digite: pedidos
ou
Clique em "Fetch/XHR" para filtrar apenas requisições AJAX
```

### 2.3 Tentar Mudar Status Novamente
```
Arraste o pedido para outra coluna
```

### 2.4 Procurar Requisição com Erro
```
Procure por linhas em VERMELHO com status:
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 406 Not Acceptable
- 409 Conflict
- 500 Internal Server Error
```

### 2.5 Ver Detalhes do Erro
```
1. Clique na requisição com erro
2. Vá na aba "Response"
3. Leia a mensagem de erro JSON
```

Exemplo de resposta de erro:
```json
{
  "code": "23514",
  "message": "new row violates check constraint \"pedidos_status_valido\"",
  "details": "Failing row contains (Preparando, ...)",
  "hint": null
}
```

---

## 📍 ETAPA 3: Executar Script SQL no Supabase

### 3.1 Acessar Supabase Dashboard
```
1. Abra: https://supabase.com/dashboard
2. Faça login
3. Selecione seu projeto
```

### 3.2 Abrir SQL Editor
```
Menu lateral esquerdo → SQL Editor
ou
Ícone de banco de dados → SQL Editor
```

### 3.3 Criar Nova Query
```
Clique em: "+ New query"
```

### 3.4 Copiar Script
```
1. Abra o arquivo: CORRIGIR_ERRO_STATUS_PEDIDO.sql
2. Copie TODO o conteúdo (Ctrl+A, Ctrl+C)
3. Cole no SQL Editor do Supabase (Ctrl+V)
```

### 3.5 Executar Script
```
1. Clique no botão "Run" (ou pressione Ctrl+Enter)
2. Aguarde a execução (pode levar alguns segundos)
3. Verifique os resultados na parte inferior
```

### 3.6 Verificar Resultados
```
Procure por:
✅ "CREATE TRIGGER" - Trigger criado com sucesso
✅ "ALTER TABLE" - Constraint adicionada
✅ "CREATE POLICY" - Políticas RLS criadas
❌ "ERROR" - Se houver erro, leia a mensagem
```

---

## 📍 ETAPA 4: Fazer Build e Deploy

### 4.1 Abrir Terminal no Projeto
```
No VS Code:
Terminal → New Terminal
ou
Ctrl + `
```

### 4.2 Executar Build
```bash
npm run build
```

### 4.3 Aguardar Conclusão
```
Você verá:
✓ built in XXXms
✓ X modules transformed

Pasta 'dist/' será criada/atualizada
```

### 4.4 Upload para Hostinger
```
1. Acesse o painel da Hostinger
2. Vá em "Gerenciador de Arquivos"
3. Navegue até a pasta do subdomínio
4. Delete os arquivos antigos (EXCETO .htaccess se existir)
5. Faça upload de TODOS os arquivos da pasta 'dist/'
6. Aguarde o upload completar
```

---

## 📍 ETAPA 5: Testar em Produção

### 5.1 Limpar Cache do Navegador
```
1. Pressione: Ctrl + Shift + Delete
2. Selecione: "Imagens e arquivos em cache"
3. Clique em: "Limpar dados"
```

### 5.2 Acessar Sistema em Produção
```
1. Abra o site em produção
2. Faça login
3. Vá para página "Pedidos"
```

### 5.3 Abrir DevTools
```
Pressione F12
Vá para aba Console
```

### 5.4 Testar Mudança de Status
```
1. Arraste um pedido para outra coluna
2. Observe os logs no console
3. Verifique se aparece o toast verde
4. Confirme que o pedido mudou de coluna
```

### 5.5 Resultado Esperado (SUCESSO)
```
Console:
  🎯 Iniciando atualização de status
  ✅ Status atualizado com sucesso

Tela:
  🟢 Toast verde: "Status atualizado para: [status]"
  ✅ Pedido na nova coluna
  ✅ Pedido não volta para coluna original
```

### 5.6 Se Ainda Houver Erro
```
1. Copie TODOS os logs do console
2. Vá para aba Network
3. Copie a resposta da requisição com erro
4. Abra o arquivo: GUIA_RAPIDO_DIAGNOSTICO_STATUS.md
5. Siga as instruções específicas para o tipo de erro
```

---

## 📍 ETAPA 6: Verificação Final

### 6.1 Testar Todos os Status
```
Teste mudar pedido para cada status:
✅ Pedido criado → Preparando
✅ Preparando → Liberado
✅ Liberado → Finalizado
✅ Finalizado → (não deve permitir mudar)
```

### 6.2 Testar com Múltiplos Pedidos
```
1. Crie 3-5 pedidos de teste
2. Mude o status de cada um
3. Verifique se todos funcionam
```

### 6.3 Verificar Histórico
```
1. Clique em um pedido
2. Veja se o histórico de status está sendo registrado
3. Confirme que as datas estão corretas
```

---

## 🆘 Problemas Comuns e Soluções Rápidas

### Problema 1: "Constraint violation"
```
Solução:
1. Volte para o SQL Editor do Supabase
2. Execute:
   ALTER TABLE pedidos DROP CONSTRAINT IF EXISTS pedidos_status_valido;
3. Teste novamente
```

### Problema 2: "Permission denied"
```
Solução:
1. Volte para o SQL Editor do Supabase
2. Execute:
   DROP POLICY IF EXISTS "Permitir atualização pública pedidos" ON pedidos;
   CREATE POLICY "Permitir atualização pública pedidos" 
   ON pedidos FOR UPDATE USING (true) WITH CHECK (true);
3. Teste novamente
```

### Problema 3: "Network error" ou Timeout
```
Solução:
1. Verifique sua conexão com internet
2. Acesse: https://status.supabase.com
3. Aguarde alguns minutos
4. Tente novamente
```

### Problema 4: Toast não aparece
```
Solução:
1. Verifique se o build foi feito corretamente
2. Limpe o cache do navegador (Ctrl+Shift+Delete)
3. Recarregue a página (Ctrl+F5)
4. Teste novamente
```

### Problema 5: Logs não aparecem no console
```
Solução:
1. Verifique se o build foi feito após as alterações
2. Confirme que os arquivos foram enviados para produção
3. Limpe o cache e recarregue
4. Se ainda não aparecer, o build pode não ter incluído as alterações
```

---

## ✅ Checklist Final

Marque cada item conforme completar:

- [ ] Verifiquei o erro no console do navegador
- [ ] Verifiquei as requisições na aba Network
- [ ] Executei o script SQL no Supabase sem erros
- [ ] Fiz o build do projeto (npm run build)
- [ ] Fiz upload dos arquivos para produção
- [ ] Limpei o cache do navegador
- [ ] Testei mudar status de um pedido
- [ ] Vi os logs detalhados no console
- [ ] Vi o toast verde de sucesso
- [ ] O pedido mudou de coluna corretamente
- [ ] Testei todos os status possíveis
- [ ] Testei com múltiplos pedidos
- [ ] Verifiquei o histórico de status

---

## 🎉 Sucesso!

Se todos os itens do checklist estão marcados e o sistema está funcionando:

✅ **Problema resolvido!**

Agora você pode:
- Usar o sistema normalmente
- Mudar status dos pedidos sem erros
- Ter feedback visual claro
- Diagnosticar problemas futuros facilmente

---

## 📞 Precisa de Ajuda?

Se após seguir TODAS as etapas o problema persistir:

1. Tire prints das telas de erro
2. Copie os logs completos do console
3. Copie a resposta da requisição com erro
4. Copie o resultado do script SQL
5. Envie tudo para análise técnica

**Informações importantes para incluir:**
- Navegador e versão (Chrome 120, Firefox 115, etc)
- Sistema operacional (Windows 11, macOS, etc)
- Mensagem de erro exata
- Quando o erro começou a acontecer
- Se funciona em desenvolvimento mas não em produção
