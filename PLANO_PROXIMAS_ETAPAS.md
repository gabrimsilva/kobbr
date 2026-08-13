# 📋 Plano de Implementação - Próximas Etapas

## 🎯 Visão Geral
Este documento detalha o plano de implementação das funcionalidades futuras do sistema de vendas PDV.

---

## 1️⃣ HISTÓRICO DE VENDAS - Modal de Visualização Detalhada

### 📝 Descrição
Criar um modal completo para visualizar todos os detalhes de uma venda específica.

### 🔧 Implementação Técnica

#### Arquivos a Criar:
- `src/components/vendas/DetalhesVendaModal.tsx`

#### Funcionalidades do Modal:
- **Cabeçalho:**
  - Número da venda
  - Data e hora completa
  - Status da venda
  - Botão de fechar

- **Informações Gerais:**
  - Valor total
  - Forma de pagamento
  - Tipo de venda (PDV/Delivery)
  - Troco (se aplicável)
  - Observações

- **Lista de Itens:**
  - Nome do produto
  - Quantidade
  - Preço unitário
  - Subtotal
  - Variantes (se houver)

- **Informações do Vendedor:**
  - Nome do usuário que realizou a venda
  - Data/hora de criação

- **Ações:**
  - Botão para imprimir cupom
  - Botão para exportar detalhes

#### Estrutura de Dados:
```typescript
interface DetalhesVenda {
  id: string
  sale_number: string
  total_amount: number
  payment_method: string
  needs_change: boolean
  change_amount?: number
  sale_type: string
  notes?: string
  created_at: string
  created_by?: string
  items: ItemVenda[]
  vendedor?: {
    nome: string
    email: string
  }
}

interface ItemVenda {
  produto_id: string
  nome: string
  quantidade: number
  preco_unitario: number
  subtotal: number
  variantes?: string[]
}
```

#### Integração:
- Modificar `handleVisualizarVenda()` em `HistoricoVendas.tsx`
- Adicionar estado para controlar abertura do modal
- Buscar dados completos da venda incluindo informações do vendedor

---

## 2️⃣ HISTÓRICO DE VENDAS - Impressão de Cupom Retroativo

### 📝 Descrição
Permitir reimprimir cupom fiscal de vendas já realizadas.

### 🔧 Implementação Técnica

#### Arquivos a Criar:
- `src/components/vendas/CupomFiscal.tsx`
- `src/utils/impressao.ts`

#### Funcionalidades:
- **Geração de Cupom:**
  - Layout formatado para impressão térmica
  - Cabeçalho com dados da empresa
  - Lista de itens com formatação
  - Totais e forma de pagamento
  - Rodapé com agradecimento

- **Opções de Impressão:**
  - Impressão direta (se suportado pelo navegador)
  - Download como PDF
  - Visualização prévia antes de imprimir

#### Estrutura do Cupom:
```
========================================
        NOME DA EMPRESA
        Endereço da Empresa
        CNPJ: XX.XXX.XXX/XXXX-XX
========================================

Venda: VENDA-20250126-001
Data: 26/01/2025 14:30
Vendedor: João Silva

----------------------------------------
ITEM                    QTD  VALOR
----------------------------------------
Produto A                 2  R$ 10,00
Produto B                 1  R$ 15,00
----------------------------------------
SUBTOTAL                     R$ 25,00
DESCONTO                     R$  0,00
----------------------------------------
TOTAL                        R$ 25,00
----------------------------------------

Forma de Pagamento: PIX
Troco: R$ 0,00

========================================
     Obrigado pela preferência!
========================================
```

#### Bibliotecas Sugeridas:
- `react-to-print` - Para impressão de componentes React
- `jspdf` - Para geração de PDF
- `html2canvas` - Para captura de tela do cupom

#### Integração:
- Modificar `handleImprimirCupom()` em `HistoricoVendas.tsx`
- Adicionar configurações de impressora no sistema
- Salvar preferências de layout do cupom

---

## 3️⃣ MELHORIAS GERAIS - Exportação de Relatórios

### 📝 Descrição
Permitir exportar dados de vendas em formatos Excel e PDF.

### 🔧 Implementação Técnica

#### Arquivos a Criar:
- `src/services/exportacaoService.ts`
- `src/components/vendas/ExportacaoModal.tsx`

#### Funcionalidades:

##### Exportação Excel:
- **Dados a Exportar:**
  - Todas as vendas filtradas
  - Resumo por período
  - Resumo por forma de pagamento
  - Resumo por produto

- **Formato:**
  - Múltiplas abas (sheets)
  - Formatação de valores monetários
  - Totalizadores
  - Gráficos básicos

##### Exportação PDF:
- **Relatórios Disponíveis:**
  - Relatório de vendas detalhado
  - Relatório resumido
  - Relatório por período
  - Relatório por vendedor

- **Layout:**
  - Cabeçalho com logo e período
  - Tabelas formatadas
  - Totalizadores
  - Rodapé com data de geração

#### Bibliotecas Sugeridas:
- `xlsx` ou `exceljs` - Para geração de Excel
- `jspdf` + `jspdf-autotable` - Para geração de PDF
- `recharts` - Para gráficos no Excel

#### Interface de Exportação:
```typescript
interface OpcoesExportacao {
  formato: 'excel' | 'pdf'
  tipoRelatorio: 'detalhado' | 'resumido' | 'periodo' | 'vendedor'
  dataInicio?: Date
  dataFim?: Date
  incluirGraficos?: boolean
  agruparPor?: 'dia' | 'semana' | 'mes'
}
```

#### Integração:
- Adicionar botão "Exportar" no `HistoricoVendas.tsx`
- Modal para selecionar opções de exportação
- Indicador de progresso durante geração
- Download automático do arquivo

---

## 4️⃣ MELHORIAS GERAIS - Gráficos no Histórico

### 📝 Descrição
Adicionar visualizações gráficas para análise de vendas.

### 🔧 Implementação Técnica

#### Arquivos a Criar:
- `src/components/vendas/GraficosVendas.tsx`
- `src/components/vendas/GraficoVendasPorDia.tsx`
- `src/components/vendas/GraficoVendasPorFormaPagamento.tsx`
- `src/components/vendas/GraficoVendasPorProduto.tsx`

#### Gráficos a Implementar:

##### 1. Vendas por Dia (Linha/Barra)
- Eixo X: Dias do período
- Eixo Y: Valor total de vendas
- Tooltip com detalhes
- Filtro por período (7 dias, 30 dias, 90 dias, personalizado)

##### 2. Vendas por Forma de Pagamento (Pizza)
- Percentual de cada forma de pagamento
- Valor total por forma
- Quantidade de vendas por forma
- Cores distintas para cada forma

##### 3. Produtos Mais Vendidos (Barra Horizontal)
- Top 10 produtos
- Quantidade vendida
- Valor total gerado
- Ordenação por quantidade ou valor

##### 4. Vendas por Hora do Dia (Heatmap/Barra)
- Identificar horários de pico
- Média de vendas por hora
- Útil para gestão de equipe

##### 5. Comparativo de Períodos (Linha)
- Comparar semana atual vs anterior
- Comparar mês atual vs anterior
- Identificar tendências

#### Biblioteca Sugerida:
- `recharts` - Biblioteca de gráficos React
  - Responsiva
  - Customizável
  - Boa documentação
  - Leve

#### Estrutura de Dados para Gráficos:
```typescript
interface DadosGraficoVendas {
  vendasPorDia: {
    data: string
    valor: number
    quantidade: number
  }[]
  
  vendasPorFormaPagamento: {
    forma: string
    valor: number
    quantidade: number
    percentual: number
  }[]
  
  produtosMaisVendidos: {
    produto: string
    quantidade: number
    valor: number
  }[]
  
  vendasPorHora: {
    hora: number
    quantidade: number
    valor: number
  }[]
}
```

#### Integração:
- Adicionar seção de gráficos acima da tabela em `HistoricoVendas.tsx`
- Botão para expandir/recolher gráficos
- Sincronizar filtros com gráficos
- Opção de exportar gráficos como imagem

---

## 5️⃣ MELHORIAS GERAIS - Busca Avançada

### 📝 Descrição
Implementar sistema de busca avançada com múltiplos critérios.

### 🔧 Implementação Técnica

#### Arquivos a Criar:
- `src/components/vendas/BuscaAvancadaModal.tsx`
- `src/services/buscaService.ts`

#### Funcionalidades:

##### Critérios de Busca:
- **Por Venda:**
  - Número da venda
  - Intervalo de valores (min/max)
  - Data/hora específica ou intervalo
  - Forma de pagamento
  - Tipo de venda

- **Por Produto:**
  - Nome do produto
  - Categoria do produto
  - Código de barras
  - Vendas que contêm produto específico

- **Por Vendedor:**
  - Nome do vendedor
  - Email do vendedor
  - Vendas de um vendedor específico

- **Avançado:**
  - Vendas com troco
  - Vendas com observações
  - Vendas acima/abaixo de valor
  - Vendas com X ou mais itens

##### Interface:
```typescript
interface CriteriosBuscaAvancada {
  // Venda
  numeroVenda?: string
  valorMin?: number
  valorMax?: number
  dataInicio?: Date
  dataFim?: Date
  formasPagamento?: string[]
  tiposVenda?: string[]
  
  // Produto
  nomeProduto?: string
  categoriaProduto?: string
  codigoBarras?: string
  
  // Vendedor
  vendedorId?: string
  vendedorNome?: string
  
  // Avançado
  apenasComTroco?: boolean
  apenasComObservacoes?: boolean
  quantidadeItensMin?: number
  quantidadeItensMax?: number
}
```

##### Funcionalidades Adicionais:
- **Salvar Buscas:**
  - Salvar critérios de busca frequentes
  - Nomear buscas salvas
  - Executar busca salva com um clique

- **Histórico de Buscas:**
  - Últimas 10 buscas realizadas
  - Repetir busca anterior

- **Operadores Lógicos:**
  - E (AND) - todos os critérios devem ser atendidos
  - OU (OR) - pelo menos um critério deve ser atendido

#### Integração:
- Adicionar botão "Busca Avançada" em `HistoricoVendas.tsx`
- Modal com formulário de critérios
- Aplicar filtros na tabela
- Indicador visual de busca ativa
- Botão para limpar busca avançada

---

## 📊 Priorização Sugerida

### Fase 1 (Essencial) - 2-3 semanas
1. ✅ Modal de Visualização Detalhada
2. ✅ Impressão de Cupom Retroativo

### Fase 2 (Importante) - 2-3 semanas
3. ✅ Gráficos no Histórico
4. ✅ Busca Avançada

### Fase 3 (Complementar) - 1-2 semanas
5. ✅ Exportação de Relatórios (Excel/PDF)

---

## 🛠️ Dependências a Instalar

```bash
# Para gráficos
npm install recharts

# Para exportação Excel
npm install xlsx
# ou
npm install exceljs

# Para exportação PDF
npm install jspdf jspdf-autotable

# Para impressão
npm install react-to-print

# Para geração de imagens
npm install html2canvas

# Para manipulação de datas (já deve estar instalado)
npm install date-fns
```

---

## 📝 Checklist de Implementação

### Modal de Visualização Detalhada
- [ ] Criar componente `DetalhesVendaModal.tsx`
- [ ] Adicionar busca de dados do vendedor
- [ ] Implementar layout responsivo
- [ ] Adicionar animações de abertura/fechamento
- [ ] Integrar com `HistoricoVendas.tsx`
- [ ] Testar com diferentes tipos de venda

### Impressão de Cupom
- [ ] Criar componente `CupomFiscal.tsx`
- [ ] Implementar layout de impressão térmica
- [ ] Adicionar opção de visualização prévia
- [ ] Implementar impressão direta
- [ ] Adicionar geração de PDF
- [ ] Criar configurações de impressora
- [ ] Testar em diferentes navegadores

### Exportação de Relatórios
- [ ] Criar `exportacaoService.ts`
- [ ] Implementar exportação Excel
- [ ] Implementar exportação PDF
- [ ] Criar modal de opções
- [ ] Adicionar indicador de progresso
- [ ] Implementar diferentes tipos de relatório
- [ ] Testar com grandes volumes de dados

### Gráficos
- [ ] Instalar e configurar recharts
- [ ] Criar componente de gráfico de vendas por dia
- [ ] Criar componente de gráfico por forma de pagamento
- [ ] Criar componente de produtos mais vendidos
- [ ] Criar componente de vendas por hora
- [ ] Integrar gráficos com filtros existentes
- [ ] Adicionar opção de exportar gráficos
- [ ] Otimizar performance com grandes datasets

### Busca Avançada
- [ ] Criar `BuscaAvancadaModal.tsx`
- [ ] Implementar formulário de critérios
- [ ] Criar `buscaService.ts`
- [ ] Implementar lógica de busca no backend
- [ ] Adicionar salvamento de buscas
- [ ] Implementar histórico de buscas
- [ ] Adicionar operadores lógicos
- [ ] Testar performance de buscas complexas

---

## 🎨 Considerações de UX/UI

### Consistência Visual
- Manter padrão de cores do sistema
- Usar componentes do shadcn/ui
- Seguir guidelines de acessibilidade
- Responsividade em todos os dispositivos

### Performance
- Lazy loading de gráficos
- Paginação de resultados
- Cache de buscas frequentes
- Otimização de queries no Supabase

### Feedback ao Usuário
- Loading states em todas as operações
- Mensagens de sucesso/erro claras
- Confirmações para ações importantes
- Tooltips explicativos

---

## 🔒 Considerações de Segurança

### Permissões
- Verificar permissões antes de exportar dados
- Logs de exportações realizadas
- Limitar tamanho de exportações

### Dados Sensíveis
- Não expor dados de clientes em relatórios públicos
- Ofuscar informações sensíveis quando necessário
- Respeitar LGPD em exportações

---

## 📈 Métricas de Sucesso

### Modal de Visualização
- Tempo médio de carregamento < 500ms
- Taxa de uso > 30% das visualizações

### Impressão de Cupom
- Taxa de sucesso de impressão > 95%
- Tempo de geração < 2s

### Exportação
- Suporte a até 10.000 registros
- Tempo de geração < 10s para 1.000 registros

### Gráficos
- Renderização < 1s
- Atualização em tempo real com filtros

### Busca Avançada
- Tempo de resposta < 2s
- Suporte a buscas complexas com múltiplos critérios

---

## 📚 Documentação Adicional

Após implementação, criar:
- [ ] Guia do usuário para cada funcionalidade
- [ ] Documentação técnica da API
- [ ] Vídeos tutoriais
- [ ] FAQ de problemas comuns

---

**Última atualização:** 27/02/2026
**Responsável:** Equipe de Desenvolvimento
**Status:** Planejamento Concluído ✅
