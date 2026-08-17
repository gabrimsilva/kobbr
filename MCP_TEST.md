# 🧪 Teste de Conexão MCP - Supabase

## Status da Configuração

✅ **Arquivo MCP criado**: `.kiro/settings/mcp.json`  
✅ **Credenciais configuradas**:
- Project Ref: `jeqhvbjtyrqvownitfdc`
- Access Token: Configurado
- Auto Approve: Habilitado

## 🔍 Como Verificar se o MCP está Funcionando

### Método 1: Via Kiro UI
1. Abra o painel lateral do Kiro
2. Procure pela seção **"MCP Servers"**
3. Verifique se o servidor `supabase` está:
   - ✅ **Connected** (verde)
   - ⚠️ **Connecting** (amarelo)
   - ❌ **Disconnected** (vermelho)

### Método 2: Via Command Palette
1. Pressione `Ctrl+Shift+P` (ou `Cmd+Shift+P` no Mac)
2. Digite: `MCP: List Servers`
3. Verifique se `supabase` aparece na lista

### Método 3: Via Command Palette - Reconnect
1. Pressione `Ctrl+Shift+P`
2. Digite: `MCP: Reconnect Server`
3. Selecione `supabase`
4. Aguarde a conexão

## 🧪 Testes para Executar

Após confirmar que o MCP está conectado, você pode pedir à IA para:

### 1. Listar Tabelas
```
"Liste todas as tabelas do banco de dados"
```

### 2. Ver Estrutura de uma Tabela
```
"Mostre a estrutura da tabela produtos"
```

### 3. Executar Query SQL
```
"Execute: SELECT count(*) FROM produtos"
```

### 4. Verificar Extensions
```
"Quais extensions estão instaladas no Supabase?"
```

### 5. Ver Migrations
```
"Liste as migrations aplicadas no banco"
```

## ⚠️ Troubleshooting

### Problema: Servidor não conecta

**Solução 1**: Verificar credenciais
- Confirme se o `project-ref` está correto
- Verifique se o `SUPABASE_ACCESS_TOKEN` é válido

**Solução 2**: Reinstalar o servidor
```bash
npm install -g @supabase/mcp-server-supabase@latest
```

**Solução 3**: Verificar logs do Kiro
1. Abra **View** > **Output**
2. Selecione **Kiro** no dropdown
3. Procure por erros relacionados ao MCP

### Problema: Comando não é executado

**Solução**: Verificar se `npx` está disponível
```bash
npx --version
```

Se não estiver instalado:
```bash
npm install -g npx
```

## 📝 Resultado Esperado

Quando o MCP estiver funcionando corretamente, a IA deve ser capaz de:

1. ✅ Listar todas as tabelas do banco
2. ✅ Descrever a estrutura de qualquer tabela
3. ✅ Executar queries SQL de leitura
4. ✅ Executar queries SQL de escrita (com confirmação)
5. ✅ Ver informações sobre migrations
6. ✅ Ver extensions instaladas

## 🔗 Referências

- [Supabase MCP Server](https://github.com/supabase-community/mcp-server-supabase)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Kiro MCP Documentation](https://docs.kiro.dev/mcp)

---

**Última atualização**: 13/08/2026  
**Status**: Aguardando teste de conexão
