# Como Limpar o Cache do Favicon

O favicon (ícone da aba do navegador) tem um cache muito persistente. Siga estes passos:

## Método 1: Limpar Cache Completo (Recomendado)

### Chrome/Edge:
1. Pressione `Ctrl + Shift + Delete`
2. Selecione "Todo o período"
3. Marque "Imagens e arquivos em cache"
4. Clique em "Limpar dados"
5. Feche TODAS as abas do site
6. Feche o navegador completamente
7. Abra novamente e acesse http://localhost:5173/

### Firefox:
1. Pressione `Ctrl + Shift + Delete`
2. Selecione "Tudo"
3. Marque "Cache"
4. Clique em "Limpar agora"
5. Feche TODAS as abas do site
6. Feche o navegador completamente
7. Abra novamente e acesse http://localhost:5173/

## Método 2: Forçar Atualização do Favicon

1. Acesse diretamente: http://localhost:5173/favicon.svg?v=20250425
2. Pressione `Ctrl + F5` para forçar atualização
3. Volte para http://localhost:5173/
4. Pressione `Ctrl + Shift + R`

## Método 3: Modo Anônimo/Privado

1. Abra uma janela anônima/privada (`Ctrl + Shift + N` no Chrome)
2. Acesse http://localhost:5173/
3. O favicon deve aparecer correto

## Método 4: Limpar Cache Específico do Site

### Chrome/Edge:
1. Abra http://localhost:5173/
2. Pressione `F12` para abrir DevTools
3. Clique com botão direito no ícone de atualizar
4. Selecione "Limpar cache e fazer hard refresh"
5. Feche e abra o navegador novamente

## Método 5: Deletar Cache Manualmente

### Windows:
1. Feche o navegador completamente
2. Pressione `Win + R`
3. Digite: `%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache`
4. Delete todos os arquivos da pasta
5. Abra o navegador novamente

## Verificar se Funcionou

O novo favicon deve ser:
- ✅ Fundo azul (não rosa)
- ✅ Ícone de prato com comida/hambúrguer
- ❌ NÃO deve ser um batom rosa

## Observação

O cache do favicon pode levar até 24 horas para atualizar naturalmente. Os métodos acima forçam a atualização imediata.

## Alternativa: Usar Outro Navegador

Se nenhum método funcionar, teste em outro navegador que você não tenha usado antes (Firefox, Edge, Opera, etc.). O novo navegador não terá o cache antigo.
