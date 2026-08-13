# Mapa do Brasil SVG

## 📥 Como Adicionar o Mapa

O componente `MapaBrasil` precisa de um arquivo SVG do mapa do Brasil com IDs específicos para cada estado.

### Opção 1: Download Manual (Recomendado)

1. Acesse: https://github.com/raphamorim/react-brazil-map/blob/master/src/brazil.svg
2. Clique em "Raw" ou "Download"
3. Salve o arquivo como `public/brazil.svg`

### Opção 2: Usar SVG Alternativo

1. Acesse: https://commons.wikimedia.org/wiki/File:Brazil_Blank_Map.svg
2. Baixe o arquivo SVG
3. Edite os IDs dos paths para o formato `BR-XX` (ex: `BR-SP`, `BR-RJ`, etc.)
4. Salve como `public/brazil.svg`

### Opção 3: Criar Manualmente

Se preferir, você pode criar um SVG simples com retângulos representando cada estado:

```xml
<svg viewBox="0 0 500 600" xmlns="http://www.w3.org/2000/svg">
  <path id="BR-AC" d="..." />
  <path id="BR-AL" d="..." />
  <!-- ... outros estados ... -->
</svg>
```

## 🗺️ Formato Esperado

O SVG deve ter paths com IDs no formato:
- `BR-AC` (Acre)
- `BR-AL` (Alagoas)
- `BR-AP` (Amapá)
- `BR-AM` (Amazonas)
- `BR-BA` (Bahia)
- `BR-CE` (Ceará)
- `BR-DF` (Distrito Federal)
- `BR-ES` (Espírito Santo)
- `BR-GO` (Goiás)
- `BR-MA` (Maranhão)
- `BR-MT` (Mato Grosso)
- `BR-MS` (Mato Grosso do Sul)
- `BR-MG` (Minas Gerais)
- `BR-PA` (Pará)
- `BR-PB` (Paraíba)
- `BR-PR` (Paraná)
- `BR-PE` (Pernambuco)
- `BR-PI` (Piauí)
- `BR-RJ` (Rio de Janeiro)
- `BR-RN` (Rio Grande do Norte)
- `BR-RS` (Rio Grande do Sul)
- `BR-RO` (Rondônia)
- `BR-RR` (Roraima)
- `BR-SC` (Santa Catarina)
- `BR-SP` (São Paulo)
- `BR-SE` (Sergipe)
- `BR-TO` (Tocantins)

## ✅ Verificar Instalação

Após adicionar o arquivo, acesse:
- http://localhost:5173/brazil.svg

Se o mapa aparecer, está funcionando!

## 🐛 Troubleshooting

### Erro: "Não foi possível carregar o mapa"

**Solução**: Verifique se o arquivo `public/brazil.svg` existe e está acessível.

### Mapa aparece mas sem cores

**Solução**: Verifique se os IDs dos paths estão no formato correto (`BR-XX`).

### Estados não são reconhecidos

**Solução**: O componente MapaBrasil tem um mapeamento de nomes de estados para siglas. Verifique os logs do console para ver quais estados não foram reconhecidos.
