# 📊 Estrutura Completa do Banco de Dados

## 🗂️ Diagrama de Relacionamentos

```
┌─────────────────┐
│   categorias    │
└────────┬────────┘
         │
         ├──────────────┐
         │              │
    ┌────▼────┐    ┌───▼──────┐
    │ produtos│    │ sabores  │
    └────┬────┘    └────┬─────┘
         │              │
         └──────┬───────┘
                │
         ┌──────▼──────┐
         │produto_     │
         │sabores      │
         └─────────────┘

┌─────────────┐      ┌──────────┐
│  clientes   │◄─────┤ pedidos  │
└─────────────┘      └────┬─────┘
                          │
                     ┌────▼──────────┐
                     │historico_     │
                     │pedidos        │
                     └───────────────┘
```

## 📋 Tabelas por Categoria

### 🛒 **Produtos e Cardápio**
| Tabela | Descrição | Registros Típicos |
|--------|-----------|-------------------|
| `categorias` | Categorias de produtos | 5-15 |
| `produtos` | Produtos disponíveis | 20-100 |
| `sabores` | Sabores de pizzas | 30-80 |
| `tamanhos` | Tamanhos dos produtos | 3-5 por produto |
| `adicionais` | Adicionais disponíveis | 10-30 |
| `combos` | Combos promocionais | 5-20 |
| `produto_sabores` | Relação N:N | Variável |
| `combo_produtos` | Relação N:N | Variável |

### 📦 **Pedidos e Vendas**
| Tabela | Descrição | Crescimento |
|--------|-----------|-------------|
| `pedidos` | Pedidos ativos | Limpo periodicamente |
| `historico_pedidos` | Status dos pedidos | Cresce continuamente |
| `historico_geral` | Pedidos finalizados | Cresce continuamente |
| `clientes` | Cadastro de clientes | Cresce continuamente |

### 🏪 **PDV e Comandas**
| Tabela | Descrição | Registros Típicos |
|--------|-----------|-------------------|
| `comandas` | Comandas abertas | 0-24 (máx) |
| `historico_comandas` | Comandas finalizadas | Cresce continuamente |

### 👥 **Usuários e Permissões**
| Tabela | Descrição | Registros Típicos |
|--------|-----------|-------------------|
| `profile` | Administradores | 1-5 |
| `funcionarios` | Funcionários | 5-50 |

### 🤖 **Assistente IA**
| Tabela | Descrição | Limpeza |
|--------|-----------|---------|
| `ia_config` | Configurações IA | 1 registro |
| `ia_conversas` | Conversas ativas | Limpar após 30 dias |
| `ia_arquivos_temp` | Arquivos temporários | Limpar após 30 dias |

### ⚙️ **Configurações e Sistema**
| Tabela | Descrição | Registros |
|--------|-----------|-----------|
| `configuracoes` | Config do sistema | 20-50 |
| `estoque` | Controle de estoque | 10-100 |
| `avaliacoes` | Avaliações clientes | Cresce continuamente |

## 🔑 Campos Importantes

### Pedidos
```sql
pedidos {
  id: UUID (PK)
  pedido_id: TEXT (UNIQUE) -- UUID legível
  codigo_pedido: VARCHAR -- Código amigável (ex: 8122)
  cliente_id: UUID (FK → clientes)
  status: TEXT -- Status atual
  total: NUMERIC
  itens: JSONB -- Array de itens
  mercado_pago_payment_id: TEXT -- Integração MP
  taxa_extra_km: DECIMAL -- Taxa por distância
  desconto: NUMERIC -- Valor do desconto
  tipo_desconto: TEXT -- 'valor' ou 'percentual'
  forma_pagamento_dividido: BOOLEAN -- Pagamento dividido
  pagamento_1_tipo: TEXT -- Tipo do 1º pagamento
  pagamento_1_valor: NUMERIC -- Valor do 1º pagamento
  pagamento_2_tipo: TEXT -- Tipo do 2º pagamento
  pagamento_2_valor: NUMERIC -- Valor do 2º pagamento
}
```

### Clientes
```sql
clientes {
  id: UUID (PK)
  nome: VARCHAR
  telefone: VARCHAR
  total_pedidos: INTEGER -- Contador
  valor_total_gasto: NUMERIC -- Acumulado
  ultimo_pedido_em: TIMESTAMPTZ
}
```

### Produtos
```sql
produtos {
  id: UUID (PK)
  nome: VARCHAR
  preco: NUMERIC
  categoria_id: UUID (FK → categorias)
  sabores_disponiveis: BOOLEAN
  permite_adicionais: BOOLEAN
  ativo: BOOLEAN
}
```

## 📊 Índices Principais

### Performance Crítica
- `idx_pedidos_status_data` - Consultas de pedidos por status
- `idx_pedidos_codigo_pedido` - Busca rápida por código
- `idx_clientes_telefone` - Busca de cliente por telefone
- `idx_produtos_categoria_id` - Listagem por categoria

### Mercado Pago
- `idx_pedidos_mercado_pago_payment_id` - Webhook lookup
- `idx_pedidos_mercado_pago_status` - Status de pagamento

## 🔐 Políticas RLS

### Acesso Público (Anônimo)
- ✅ Leitura: `produtos`, `categorias`, `sabores`, `combos`, `tamanhos`
- ✅ Inserção: `pedidos`, `clientes`, `avaliacoes`

### Acesso Autenticado
- ✅ Todas operações: Tabelas administrativas
- ✅ CRUD completo: `configuracoes`, `estoque`, `funcionarios`

### Acesso Restrito
- 🔒 `profile` - Apenas administradores
- 🔒 `ia_config` - Apenas autenticados

## 💾 Storage Buckets

| Bucket | Público | Tamanho Máx | Tipos Permitidos |
|--------|---------|-------------|------------------|
| `produtos-imagens` | ✅ Sim | 5MB | jpg, png, webp, gif |
| `sistema-imagens` | ✅ Sim | - | Todos |
| `ia-uploads` | ❌ Não | - | Todos |

## 🔄 Triggers Automáticos

### Atualização de Timestamps
- Todas as tabelas com `atualizado_em` têm trigger automático

### Sincronização
- `trigger_sync_pedido_status` - Sincroniza status com histórico

## 📈 Estatísticas Estimadas

### Crescimento Mensal (Pizzaria Média)
- Pedidos: ~1.000-3.000
- Clientes novos: ~200-500
- Histórico de status: ~10.000-30.000 (10 status/pedido)

### Tamanho do Banco (Estimativa)
- Inicial: ~5-10 MB
- Após 1 mês: ~50-100 MB
- Após 1 ano: ~500 MB - 1 GB

## 🧹 Manutenção Recomendada

### Limpeza Periódica
```sql
-- Limpar conversas IA antigas (30+ dias)
DELETE FROM ia_conversas 
WHERE criado_em < NOW() - INTERVAL '30 days'
  AND status IN ('finalizado', 'cancelado');

-- Limpar arquivos órfãos
SELECT limpar_arquivos_orfaos();

-- Mover pedidos finalizados para histórico (7+ dias)
-- (Implementar via Edge Function)
```

### Backup
- Diário: Tabelas de pedidos e clientes
- Semanal: Banco completo
- Mensal: Backup arquivado

## 🔍 Queries Úteis

### Pedidos do dia
```sql
SELECT * FROM pedidos 
WHERE DATE(criado_em) = CURRENT_DATE
ORDER BY criado_em DESC;
```

### Pedidos com desconto
```sql
SELECT codigo_pedido, cliente_nome, subtotal, desconto, tipo_desconto, total
FROM pedidos
WHERE desconto > 0
ORDER BY criado_em DESC;
```

### Pedidos com pagamento dividido
```sql
SELECT codigo_pedido, cliente_nome, total,
       pagamento_1_tipo, pagamento_1_valor,
       pagamento_2_tipo, pagamento_2_valor
FROM pedidos
WHERE forma_pagamento_dividido = true
ORDER BY criado_em DESC;
```

### Top 10 clientes
```sql
SELECT nome, telefone, total_pedidos, valor_total_gasto
FROM clientes
ORDER BY valor_total_gasto DESC
LIMIT 10;
```

### Produtos sem estoque
```sql
SELECT * FROM vw_estoque_baixo
WHERE quantidade = 0;
```

### Média de avaliações
```sql
SELECT AVG(estrelas) as media, COUNT(*) as total
FROM avaliacoes
WHERE aprovada = true;
```

---

**Última Atualização:** 20/01/2026  
**Versão do Banco:** PostgreSQL 17.6.1  
**Total de Tabelas:** 22  
**Total de Views:** 10  
**Total de Funções:** 7
