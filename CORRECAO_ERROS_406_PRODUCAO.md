# Correção de Erros 406 em Produção

## Problema Identificado
Ao acessar a página de produtos em produção, o sistema apresentava múltiplos erros 406 (Not Acceptable) causados por tentativas de carregar configurações que não existem no banco de dados.

## Configurações Removidas
As seguintes configurações foram completamente removidas do sistema:

1. `background_pattern` - Padrão de fundo (ícones de comida)
2. `background_pattern_size` - Tamanho do padrão
3. `background_pattern_opacity` - Opacidade do padrão

Essas configurações faziam parte da funcionalidade de "Padrão de Fundo" que foi removida anteriormente, mas o componente que as carregava ainda estava ativo.

## Correções Aplicadas

### 1. Remoção do Componente BackgroundPattern
- **Arquivo deletado**: `src/components/BackgroundPattern.tsx`
- **Motivo**: Este componente tentava carregar as configurações removidas (`background_pattern`, `background_pattern_size`, `background_pattern_opacity`)

### 2. Atualização do App.tsx
- **Arquivo**: `src/App.tsx`
- **Alterações**:
  - Removida importação: `import BackgroundPattern from "@/components/BackgroundPattern"`
  - Removido uso: `<BackgroundPattern />` do JSX

### 3. Correção do Hook useConfiguracoesLoja
- **Arquivo**: `src/hooks/useConfiguracoesLoja.ts`
- **Problema**: Tentava buscar configurações com chaves incorretas
- **Correções**:
  - `nomeEstabelecimento` → `nome_loja`
  - `endereco` → `endereco_loja`
  - `telefone` → `telefone_loja`
  - `email` → `email_loja`

## Build de Produção

### Comando Executado
```bash
npm run build
```

### Resultado
- Build concluído com sucesso
- Todos os módulos compilados sem erros
- Arquivo `.htaccess` recriado na pasta `dist/`

### Arquivos Prontos para Deploy
A pasta `dist/` está pronta para ser enviada para a Hostinger, contendo:
- Todos os assets compilados e otimizados
- Arquivo `.htaccess` com regras de rewrite para SPA
- Variáveis de ambiente do Supabase compiladas

## Próximos Passos

1. **Upload para Hostinger**
   - Fazer upload completo da pasta `dist/` para o subdomínio
   - Garantir que o arquivo `.htaccess` foi enviado

2. **Teste em Produção**
   - Acessar a página de produtos
   - Verificar se os erros 406 foram resolvidos
   - Testar navegação entre páginas

3. **Monitoramento**
   - Verificar console do navegador para novos erros
   - Confirmar que todas as configurações estão carregando corretamente

## Observações Importantes

- O componente `BackgroundPattern` foi completamente removido, não apenas desabilitado
- Todas as referências às configurações de padrão de fundo foram eliminadas
- O hook `useConfiguracoesLoja` agora usa as chaves corretas do banco de dados
- O build está limpo e otimizado para produção

## Data da Correção
04/03/2026
