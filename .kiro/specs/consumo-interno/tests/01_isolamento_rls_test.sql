-- ============================================================================
-- TESTES DE INTEGRAÇÃO: Consumo Interno
-- Teste 1: Isolamento RLS por Estabelecimento
-- ============================================================================
-- Arquivo: 01_isolamento_rls_test.sql
-- Descrição: Validar que RLS policies isolam dados por estabelecimento
-- Data: 26/01/2026
-- Execução: Após migrations 01-02
-- ============================================================================

/*
ROTEIRO DE TESTE MANUAL:

Este arquivo contém queries para testar o isolamento RLS da feature Consumo Interno.
Requer um cliente SQL (DBeaver, pgAdmin, psql) com acesso direto ao Supabase.

Passos:
1. Criar dois estabelecimentos de teste
2. Criar dois usuários (um para cada estabelecimento)
3. Verificar isolamento de dados
4. Testar imutabilidade (sem UPDATE/DELETE)

Observação: Testes unitários de isolamento RLS em produção requerem
lógica especial para assumir identidade de diferentes usuários.
Para testes de desenvolvimento, usar este script diretamente no SQL Editor.
*/

-- ============================================================================
-- SETUP: Criar dados de teste (executar como admin do Supabase)
-- ============================================================================

-- Criar 2 estabelecimentos de teste
INSERT INTO public.estabelecimentos (nome, slug, ativo) VALUES 
    ('Estabelecimento A', 'est-a-teste', true),
    ('Estabelecimento B', 'est-b-teste', true)
RETURNING id, nome, slug;

-- Guardar os IDs para usar abaixo (substitua pelos valores reais)
-- EST_A_ID = '...'
-- EST_B_ID = '...'

-- Criar 2 usuários de teste no Supabase Auth (via dashboard ou Admin API)
-- USER_A_EMAIL = 'teste-a@example.com'
-- USER_B_EMAIL = 'teste-b@example.com'

-- Criar 2 funcionários vinculados aos estabelecimentos
INSERT INTO public.funcionarios (nome, email, funcao, user_id, estabelecimento_id) VALUES
    ('Usuário Teste A', 'teste-a@example.com', 'atendente', 'USER_A_ID_UUID', 'EST_A_ID'),
    ('Usuário Teste B', 'teste-b@example.com', 'atendente', 'USER_B_ID_UUID', 'EST_B_ID')
RETURNING id, nome, email;

-- Criar 2 itens de estoque para teste
INSERT INTO public.stock_items (product_id, nome, quantidade, ativo) VALUES
    ('PRODUCT_ID_1', 'Produto Teste 1', 100, true),
    ('PRODUCT_ID_2', 'Produto Teste 2', 50, true)
RETURNING id, product_id, nome, quantidade;


-- ============================================================================
-- TESTE 1: Usuário A vê apenas consumos de EST-A
-- ============================================================================

/*
Procedimento:
1. Conectar com JWT de USER_A (usando seu user_id)
2. Inserir consumo em EST_A
3. SELECT - deve retornar 1 registro
4. Conectar com JWT de USER_B
5. SELECT - deve retornar 0 registros
*/

-- Passo 1: Como USER_A, criar venda interna
SELECT public.registrar_consumo_interno(
    p_estabelecimento_id := 'EST_A_ID'::uuid,
    p_items := '[
        {
            "product_id": "PRODUCT_ID_1",
            "product_name": "Produto Teste 1",
            "quantity": 10,
            "unit_price": 25.00
        }
    ]'::jsonb,
    p_created_by := 'USER_A_ID'::uuid
);

-- Passo 2: Como USER_A, verificar que vê o registro
SELECT ic.id, ic.estabelecimento_id, ic.total_quantity, ic.created_at
FROM internal_consumptions ic
ORDER BY ic.created_at DESC
LIMIT 1;
-- Esperado: 1 registro (o que acabou de criar)

-- Passo 3: Como USER_B, verificar que NÃO vê o registro
-- (Simular: assumir que estamos agora com contexto de EST_B)
-- Em ambiente de teste real, fazer:
--   1. Logout como USER_A
--   2. Login como USER_B
--   3. Executar:
SELECT ic.id, ic.estabelecimento_id, ic.total_quantity, ic.created_at
FROM internal_consumptions ic
ORDER BY ic.created_at DESC;
-- Esperado: 0 registros (RLS bloqueou acesso)


-- ============================================================================
-- TESTE 2: Usuário A não consegue INSERT em EST-B
-- ============================================================================

/*
Procedimento:
1. Conectar com JWT de USER_A
2. Tentar INSERT com estabelecimento_id = EST_B_ID
3. Esperado: erro de RLS Permission denied
*/

-- Como USER_A, tentar inserir consumo em EST_B
SELECT public.registrar_consumo_interno(
    p_estabelecimento_id := 'EST_B_ID'::uuid,
    p_items := '[
        {
            "product_id": "PRODUCT_ID_2",
            "product_name": "Produto Teste 2",
            "quantity": 5,
            "unit_price": 10.00
        }
    ]'::jsonb,
    p_created_by := 'USER_A_ID'::uuid
);
-- Esperado: retorno com success=false, message contendo "Acesso negado"


-- ============================================================================
-- TESTE 3: Consumo interno é imutável (sem UPDATE/DELETE)
-- ============================================================================

/*
Procedimento:
1. Ter um consumo interno criado (de Teste 1)
2. Tentar UPDATE
3. Esperado: erro de RLS Permission denied
4. Tentar DELETE
5. Esperado: erro de RLS Permission denied
*/

-- Obter ID de um consumo interno existente
-- (substituir por ID real do registro criado em Teste 1)

-- Teste 3a: UPDATE deve falhar
UPDATE public.internal_consumptions
SET total_quantity = 999
WHERE id = 'CONSUMO_ID_DO_TESTE_1'::uuid;
-- Esperado: erro - "Permission denied" (política de UPDATE não existe)

-- Teste 3b: DELETE deve falhar
DELETE FROM public.internal_consumptions
WHERE id = 'CONSUMO_ID_DO_TESTE_1'::uuid;
-- Esperado: erro - "Permission denied" (política de DELETE não existe)


-- ============================================================================
-- TESTE 4: Validação de integridade de dados
-- ============================================================================

/*
Procedimento:
1. Verificar que sale correspondente foi criada
2. Verificar que is_internal_consumption = true em sales
3. Verificar que stock_items foi decrementado
4. Verificar que stock_movement foi criado
*/

-- Teste 4a: Venda interna foi criada
SELECT s.id, s.is_internal_consumption, s.total_amount, s.payment_method, s.sale_type
FROM public.sales s
WHERE s.is_internal_consumption = true
ORDER BY s.created_at DESC
LIMIT 1;
-- Esperado: 1 registro com is_internal_consumption=true, payment_method='INTERNAL'

-- Teste 4b: Stock foi decrementado
SELECT si.id, si.product_id, si.nome, si.quantidade
FROM public.stock_items si
WHERE si.product_id = 'PRODUCT_ID_1'::uuid;
-- Esperado: quantidade = 100 - 10 = 90

-- Teste 4c: Movimento de estoque foi criado
SELECT sm.id, sm.stock_item_id, sm.tipo, sm.quantidade, sm.motivo
FROM public.stock_movements sm
WHERE sm.motivo = 'Consumo Interno'
ORDER BY sm.criado_em DESC
LIMIT 1;
-- Esperado: 1 registro com tipo='saida', quantidade=10


-- ============================================================================
-- TESTE 5: Transação atômica (rollback em caso de erro)
-- ============================================================================

/*
Procedimento:
1. Tentar registrar consumo com quantidade > stock disponível
2. Esperado: erro retornado, nada inserido (rollback)
3. Verificar que stock não mudou
*/

-- Fazer snapshot do stock antes
SELECT si.id, si.quantidade
FROM public.stock_items si
WHERE si.product_id = 'PRODUCT_ID_1'::uuid;
-- Guardar quantidade inicial (ex: 90)

-- Tentar registrar consumo com quantidade insuficiente (150 > 90)
SELECT public.registrar_consumo_interno(
    p_estabelecimento_id := 'EST_A_ID'::uuid,
    p_items := '[
        {
            "product_id": "PRODUCT_ID_1",
            "product_name": "Produto Teste 1",
            "quantity": 150,
            "unit_price": 25.00
        }
    ]'::jsonb,
    p_created_by := 'USER_A_ID'::uuid
);
-- Esperado: success=false, message contendo "Estoque insuficiente"

-- Verificar que stock NÃO mudou (permanece 90)
SELECT si.id, si.quantidade
FROM public.stock_items si
WHERE si.product_id = 'PRODUCT_ID_1'::uuid;
-- Esperado: quantidade ainda = 90 (não mudou, rollback funcionou)

-- Verificar que nenhum consumo interno foi criado
SELECT COUNT(*) FROM internal_consumptions
WHERE estabelecimento_id = 'EST_A_ID'::uuid
AND created_at > now() - interval '5 minutes';
-- Esperado: count = 1 (apenas o do Teste 1, não o falho do Teste 5)


-- ============================================================================
-- LIMPEZA (executar ao final dos testes)
-- ============================================================================

/*
Restaurar ambiente para estado limpo:
*/

-- Deletar consumos internos criados (cascata deleta sales)
DELETE FROM public.internal_consumptions
WHERE estabelecimento_id IN ('EST_A_ID'::uuid, 'EST_B_ID'::uuid);

-- Deletar funcionários de teste
DELETE FROM public.funcionarios
WHERE email IN ('teste-a@example.com', 'teste-b@example.com');

-- Deletar estabelecimentos de teste
DELETE FROM public.estabelecimentos
WHERE slug IN ('est-a-teste', 'est-b-teste');

-- Deletar itens de estoque de teste
DELETE FROM public.stock_items
WHERE nome LIKE 'Produto Teste%';


-- ============================================================================
-- RESUMO DOS TESTES
-- ============================================================================

/*
✅ TESTE 1: Isolamento por estabelecimento
   - USER_A cria consumo em EST_A
   - USER_A vê consumo em EST_A
   - USER_B não vê consumo em EST_A
   - RLS está funcionando

✅ TESTE 2: Proteção de acesso
   - USER_A não consegue criar consumo em EST_B
   - RLS bloqueia insert em outro estabelecimento

✅ TESTE 3: Imutabilidade
   - Consumos internos não podem ser alterados
   - UPDATE bloqueado por RLS
   - DELETE bloqueado por RLS

✅ TESTE 4: Integridade de dados
   - Sale foi criada com is_internal_consumption=true
   - Stock foi decrementado corretamente
   - Movimento de estoque foi registrado

✅ TESTE 5: Atomicidade
   - Se erro em qualquer etapa, tudo é revertido
   - Stock não muda se falha
   - Nenhum consumo é criado se falha

Se todos os testes passarem: RLS policies e RPC functions estão implementadas corretamente!
*/

-- ============================================================================
-- FIM DOS TESTES — 01_isolamento_rls_test.sql
-- ============================================================================
