# 🚀 Quick Start - Consumo Interno

**Guia rápido para testar a feature após as migrações serem executadas**

---

## 1️⃣ Pré-Requisitos

- ✅ As 4 migrações SQL foram executadas em ordem
- ✅ Você tem acesso ao Supabase SQL Editor ou DBeaver
- ✅ Você tem pelo menos um estabelecimento configurado no projeto multi-tenant

---

## 2️⃣ Verificar se Tudo Funcionou

```sql
-- Verificar tabela criada
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_name = 'internal_consumptions' AND table_schema = 'public';
-- Esperado: 1

-- Verificar RPC functions criadas
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name = 'registrar_consumo_interno' 
     OR routine_name = 'obter_consumos_por_periodo');
-- Esperado: 2 linhas

-- Verificar RLS está habilitado
SELECT tablename FROM pg_tables 
WHERE tablename = 'internal_consumptions' 
AND rowsecurity = true;
-- Esperado: internal_consumptions
```

---

## 3️⃣ Testar Registrar Consumo Interno

### Preparação
```sql
-- Obter um estabelecimento válido
SELECT id, nome FROM estabelecimentos LIMIT 1;
-- Guardar o ID (ex: '550e8400-e29b-41d4-a716-446655440000')

-- Verificar que tem stock disponível
SELECT si.id, si.product_id, si.nome, si.quantidade 
FROM stock_items si 
WHERE quantidade > 5 
LIMIT 3;
-- Guardar alguns product_id
```

### Executar RPC
```sql
-- Chamar RPC para registrar consumo
SELECT * FROM public.registrar_consumo_interno(
    p_estabelecimento_id := '550e8400-e29b-41d4-a716-446655440000'::uuid,
    p_items := '[
        {
            "product_id": "550e8400-e29b-41d4-a716-446655440001",
            "product_name": "Pizza Margherita",
            "quantity": 2,
            "unit_price": 25.00
        },
        {
            "product_id": "550e8400-e29b-41d4-a716-446655440002",
            "product_name": "Refrigerante 2L",
            "quantity": 1,
            "unit_price": 8.00
        }
    ]'::jsonb
);
```

### Resultado Esperado
```json
{
  "success": true,
  "consumption_id": "550e8400-e29b-41d4-a716-446655440010",
  "sale_id": "550e8400-e29b-41d4-a716-446655440011",
  "sale_number": "INT-2026-01-26-10-30-45-550e8400-e29b-41d4-a716-446655440012",
  "total_quantity": 3,
  "message": "Consumo interno registrado com sucesso"
}
```

---

## 4️⃣ Verificar Dados Registrados

### Verificar Consumo Interno
```sql
SELECT * FROM internal_consumptions 
WHERE estabelecimento_id = '550e8400-e29b-41d4-a716-446655440000'::uuid
ORDER BY created_at DESC 
LIMIT 1;
```

### Verificar Venda Interna Criada
```sql
SELECT id, sale_number, is_internal_consumption, total_amount, items, created_at
FROM sales 
WHERE is_internal_consumption = true
ORDER BY created_at DESC 
LIMIT 1;
```

### Verificar Stock Decrementado
```sql
SELECT si.product_id, si.nome, si.quantidade
FROM stock_items si
WHERE si.product_id IN (
    '550e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440002'
);
-- Esperado: quantities foram decrementadas (2 e 1 respectivamente)
```

### Verificar Movimento de Estoque
```sql
SELECT sm.id, sm.stock_item_id, sm.tipo, sm.quantidade, sm.motivo, sm.criado_em
FROM stock_movements sm
WHERE sm.motivo = 'Consumo Interno'
ORDER BY sm.criado_em DESC 
LIMIT 2;
-- Esperado: 2 movimentos de saída (um para cada produto)
```

---

## 5️⃣ Testar Consultar Consumos por Período

```sql
-- Últimos 30 dias, agrupado por dia
SELECT * FROM public.obter_consumos_por_periodo(
    p_estabelecimento_id := '550e8400-e29b-41d4-a716-446655440000'::uuid,
    p_data_inicio := CURRENT_DATE - interval '30 days',
    p_data_fim := CURRENT_DATE,
    p_granularidade := 'dia'
);
```

### Resultado Esperado
```
periodo    | total_unidades | total_transacoes | media_unidades_transacao
-----------|----------------|------------------|------------------------
2026-01-26 | 3              | 1                | 3.00
```

### Testar Outras Granularidades
```sql
-- Por semana (últimas 12 semanas)
SELECT * FROM public.obter_consumos_por_periodo(
    p_estabelecimento_id := '550e8400-e29b-41d4-a716-446655440000'::uuid,
    p_data_inicio := CURRENT_DATE - interval '12 weeks',
    p_data_fim := CURRENT_DATE,
    p_granularidade := 'semana'
);

-- Por mês (últimos 12 meses)
SELECT * FROM public.obter_consumos_por_periodo(
    p_estabelecimento_id := '550e8400-e29b-41d4-a716-446655440000'::uuid,
    p_data_inicio := CURRENT_DATE - interval '12 months',
    p_data_fim := CURRENT_DATE,
    p_granularidade := 'mes'
);
```

---

## 6️⃣ Testar Isolamento RLS

### Criar Segundo Estabelecimento e Usuário
```sql
-- Criar estabelecimento B
INSERT INTO estabelecimentos (nome, slug, ativo) 
VALUES ('Estabelecimento B Teste', 'est-b-teste', true)
RETURNING id;

-- Criar usuário B
-- (via dashboard ou criar funcionário vinculado)

-- Criar consumo em EST-B por USER-B
SELECT public.registrar_consumo_interno(
    p_estabelecimento_id := 'EST_B_ID'::uuid,
    p_items := '[{"product_id": "...", "quantity": 1}]'::jsonb
);
```

### Verificar Isolamento
```sql
-- Logado como USER_A, ver apenas consumos de EST_A
SELECT COUNT(*) FROM internal_consumptions;
-- Esperado: apenas contagem de EST_A

-- Logado como USER_B, ver apenas consumos de EST_B
SELECT COUNT(*) FROM internal_consumptions;
-- Esperado: apenas contagem de EST_B
```

---

## 7️⃣ Testar Erro - Stock Insuficiente

```sql
-- Tentar registrar consumo com quantidade > stock
SELECT * FROM public.registrar_consumo_interno(
    p_estabelecimento_id := '550e8400-e29b-41d4-a716-446655440000'::uuid,
    p_items := '[
        {
            "product_id": "550e8400-e29b-41d4-a716-446655440001",
            "product_name": "Pizza Margherita",
            "quantity": 99999
        }
    ]'::jsonb
);
```

### Resultado Esperado
```json
{
  "success": false,
  "message": "Estoque insuficiente para Pizza Margherita: solicitado 99999, disponível 98"
}
```

---

## 8️⃣ Testar Imutabilidade

### Tentar UPDATE (deve falhar)
```sql
UPDATE internal_consumptions 
SET total_quantity = 999 
WHERE id = '550e8400-e29b-41d4-a716-446655440010'::uuid;
-- Esperado: erro - Permission denied (RLS)
```

### Tentar DELETE (deve falhar)
```sql
DELETE FROM internal_consumptions 
WHERE id = '550e8400-e29b-41d4-a716-446655440010'::uuid;
-- Esperado: erro - Permission denied (RLS)
```

---

## 9️⃣ Checklist de Sucesso

- [x] Tabelas criadas
- [x] RPC functions acessíveis
- [x] Consumo registrado com sucesso
- [x] Venda interna criada (is_internal_consumption=true)
- [x] Stock foi decrementado
- [x] Movimento de estoque criado
- [x] Consulta de período retorna dados
- [x] Isolamento RLS funciona
- [x] Imutabilidade preservada
- [x] Erro tratado corretamente

Se todos os testes passaram: **✅ Phase 1 está funcionando perfeitamente!**

---

## 🔟 Próximos Passos

Após validar Phase 1:

1. **Phase 2 (Frontend)** - Implementar UI no PDV
   - Checkbox "Consumo Interno" no modal
   - Lógica para chamar RPC
   - Validações e feedback visual

2. **Phase 3 (Métricas)** - Adicionar gráficos
   - Card com total consumido
   - LineChart de evolução
   - Integração com RPC

3. **Phase 4 (Testing & Deploy)** - QA e produção
   - Testes manuais completos
   - Deploy para Hostinger
   - Monitoramento

---

## 📞 Troubleshooting

### Erro: "Função não existe"
```
Solução: Verificar que todas as 4 migrações foram executadas em ordem
```

### Erro: "Estabelecimento not found"
```
Solução: Substituir estabelecimento_id pelo UUID real de um estabelecimento existente
```

### Erro: "Estoque insuficiente" quando deveria ter stock
```
Solução: Verificar quantity em stock_items, pode ter sido decrementada por outro consumo
```

### Dados não aparecem em consultas
```
Solução: Verificar RLS - usuário deve estar vinculado ao mesmo estabelecimento
```

---

## 📚 Documentação Completa

- **Spec Completa**: `.kiro/specs/consumo-interno/tasks.md`
- **Status Phase 1**: `.kiro/specs/consumo-interno/PHASE_1_STATUS.md`
- **Migrations**: `.kiro/specs/consumo-interno/migrations/README.md`
- **Testes**: `.kiro/specs/consumo-interno/tests/01_isolamento_rls_test.sql`

---

**Tempo de Test**: ~15 minutos  
**Dificuldade**: ⭐⭐ (Básico - apenas copiar/colar SQL)  
**Sucesso esperado**: 99%+ se migrações foram executadas corretamente

Boa sorte! 🎉
