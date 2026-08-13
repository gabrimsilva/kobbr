-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - ESTOQUE
-- ============================================================================
-- Sistema de controle de estoque para ingredientes e insumos
-- Complementa todos os SQLs anteriores
-- ============================================================================

-- ============================================================================
-- FILOSOFIA: CONTROLE DE ESTOQUE COM RASTREABILIDADE
-- ============================================================================
-- 
-- REGRA FUNDAMENTAL: Estoque é rastreável e auditável
-- 
-- Por quê rastreabilidade?
--   ✅ Histórico completo de movimentações
--   ✅ Identificar perdas e desperdícios
--   ✅ Auditoria de quem fez cada movimentação
--   ✅ Relatórios precisos de consumo
--   ✅ Previsão de compras
-- 
-- Fluxo básico:
--   1. Cadastrar item de estoque
--   2. Definir quantidade mínima (alerta)
--   3. Registrar entradas (compras, devoluções)
--   4. Registrar saídas (consumo, perdas, vendas)
--   5. Sistema alerta quando quantidade < mínima
--   6. Relatórios de movimentação
-- 
-- Tipos de movimentação:
--   - entrada_compra: Compra de fornecedor
--   - entrada_devolucao: Devolução de cliente
--   - entrada_ajuste: Ajuste manual (inventário)
--   - saida_consumo: Consumo na produção
--   - saida_perda: Perda/desperdício
--   - saida_venda: Venda direta
--   - saida_ajuste: Ajuste manual (inventário)
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: itens_estoque
-- ============================================================================
-- Cadastro de itens do estoque (ingredientes, insumos, embalagens)
CREATE TABLE itens_estoque (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    
    -- Identificação
    nome TEXT NOT NULL,
    descricao TEXT,
    codigo_interno TEXT, -- Código interno da loja (SKU)
    codigo_barras TEXT, -- EAN/código de barras
    
    -- Categoria/Tipo
    -- NOTA: Valores fixos por simplicidade. Para 100% flexível, criar tabela categorias_estoque
    -- Evolução futura: categorias_estoque (id, nome, slug, ativo) + FK opcional
    categoria TEXT CHECK (categoria IN (
        'ingrediente', 'embalagem', 'bebida', 'limpeza', 'descartavel', 'outro'
    )),
    
    -- Unidade de medida
    unidade_medida TEXT NOT NULL CHECK (unidade_medida IN (
        'kg', 'g', 'l', 'ml', 'un', 'cx', 'pct', 'dz'
    )),
    
    -- Conversão de unidades (para cálculos automáticos de consumo)
    -- Permite comprar em kg, consumir em g, vender em un
    unidade_base TEXT CHECK (unidade_base IN ('g', 'ml', 'un')),
    fator_conversao NUMERIC(10, 6) DEFAULT 1,
    -- Exemplo: farinha comprada em kg → unidade_base='g', fator=1000
    
    -- Controle de quantidade
    quantidade_atual NUMERIC(10, 3) NOT NULL DEFAULT 0 CHECK (quantidade_atual >= 0),
    quantidade_minima NUMERIC(10, 3) NOT NULL DEFAULT 0 CHECK (quantidade_minima >= 0),
    quantidade_maxima NUMERIC(10, 3) CHECK (quantidade_maxima >= 0),
    
    -- Validade (simplificada - para controle por lote, criar tabela estoque_lotes no futuro)
    -- NOTA: Este campo é para validade única/média. Para controle preciso por lote de compra,
    --       evoluir para tabela estoque_lotes (item_id, lote, validade, quantidade, custo)
    validade DATE, -- Data de validade (se aplicável)
    dias_alerta_validade INTEGER DEFAULT 7, -- Alertar X dias antes do vencimento
    
    -- Alertas
    avisar_quantidade_baixa BOOLEAN DEFAULT true,
    avisar_validade_proxima BOOLEAN DEFAULT true,
    
    -- Custo (para relatórios financeiros)
    custo_unitario NUMERIC(10, 2) CHECK (custo_unitario >= 0),
    custo_total NUMERIC(10, 2) GENERATED ALWAYS AS (quantidade_atual * custo_unitario) STORED,
    
    -- Fornecedor (opcional)
    fornecedor_nome TEXT,
    fornecedor_contato TEXT,
    
    -- Localização física
    localizacao TEXT, -- Ex: Prateleira A, Geladeira 2, Freezer
    
    -- Status
    ativo BOOLEAN DEFAULT true,
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete
    
    -- Auditoria
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: quantidade máxima deve ser maior que mínima
    CHECK (quantidade_maxima IS NULL OR quantidade_maxima >= quantidade_minima)
);

-- Índices para performance
CREATE INDEX idx_itens_estoque_loja ON itens_estoque(loja_id);
CREATE INDEX idx_itens_estoque_ativo ON itens_estoque(ativo);
CREATE INDEX idx_itens_estoque_deleted_at ON itens_estoque(deleted_at);
CREATE INDEX idx_itens_estoque_categoria ON itens_estoque(categoria);
CREATE INDEX idx_itens_estoque_codigo_interno ON itens_estoque(codigo_interno);
CREATE INDEX idx_itens_estoque_codigo_barras ON itens_estoque(codigo_barras);
CREATE INDEX idx_itens_estoque_validade ON itens_estoque(validade);

-- Índice composto para alertas de estoque baixo
CREATE INDEX idx_itens_estoque_alerta_baixo 
    ON itens_estoque(loja_id, avisar_quantidade_baixa) 
    WHERE quantidade_atual <= quantidade_minima AND ativo = true AND deleted_at IS NULL;

-- Índice composto para alertas de validade
CREATE INDEX idx_itens_estoque_alerta_validade 
    ON itens_estoque(loja_id, avisar_validade_proxima, validade) 
    WHERE ativo = true AND deleted_at IS NULL AND validade IS NOT NULL;

-- ============================================================================
-- TABELA: estoque_movimentacoes
-- ============================================================================
-- Histórico de todas as movimentações de estoque (entrada/saída)
-- Rastreabilidade completa para auditoria
CREATE TABLE estoque_movimentacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_estoque_id UUID NOT NULL REFERENCES itens_estoque(id) ON DELETE RESTRICT,
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    
    -- Tipo de movimentação
    tipo_movimentacao TEXT NOT NULL CHECK (tipo_movimentacao IN (
        'entrada_compra', 'entrada_devolucao', 'entrada_ajuste',
        'saida_consumo', 'saida_perda', 'saida_venda', 'saida_ajuste'
    )),
    
    -- Quantidade movimentada (sempre positivo, tipo define se é entrada ou saída)
    quantidade NUMERIC(10, 3) NOT NULL CHECK (quantidade > 0),
    
    -- Saldo antes e depois (snapshot para auditoria)
    quantidade_anterior NUMERIC(10, 3) NOT NULL,
    quantidade_nova NUMERIC(10, 3) NOT NULL,
    
    -- Custo unitário no momento da movimentação
    custo_unitario NUMERIC(10, 2) CHECK (custo_unitario >= 0),
    custo_total NUMERIC(10, 2) CHECK (custo_total >= 0),
    
    -- Motivo/Observação
    motivo TEXT NOT NULL, -- Ex: "Compra do fornecedor X", "Perda por vencimento"
    observacoes TEXT,
    
    -- Documento relacionado (opcional)
    documento_numero TEXT, -- Ex: Nota fiscal, número do pedido
    documento_tipo TEXT, -- Ex: "nota_fiscal", "pedido", "inventario"
    
    -- Vinculação com pedido (se movimentação for por consumo em pedido)
    -- IMPORTANTE: 1 pedido pode gerar VÁRIAS movimentações (ingredientes diferentes)
    -- NUNCA deletar pedidos, apenas cancelar. Estoque não deve "sumir" junto.
    pedido_id UUID REFERENCES pedidos(id) ON DELETE SET NULL,
    
    -- Auditoria
    realizado_por UUID NOT NULL REFERENCES auth.users(id),
    realizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: quantidade_nova = quantidade_anterior +/- quantidade
    CHECK (
        (tipo_movimentacao LIKE 'entrada_%' AND quantidade_nova = quantidade_anterior + quantidade) OR
        (tipo_movimentacao LIKE 'saida_%' AND quantidade_nova = quantidade_anterior - quantidade)
    )
);

-- Índices para performance
CREATE INDEX idx_estoque_movimentacoes_item ON estoque_movimentacoes(item_estoque_id);
CREATE INDEX idx_estoque_movimentacoes_loja ON estoque_movimentacoes(loja_id);
CREATE INDEX idx_estoque_movimentacoes_tipo ON estoque_movimentacoes(tipo_movimentacao);
CREATE INDEX idx_estoque_movimentacoes_realizado_em ON estoque_movimentacoes(realizado_em DESC);
CREATE INDEX idx_estoque_movimentacoes_pedido ON estoque_movimentacoes(pedido_id);
CREATE INDEX idx_estoque_movimentacoes_realizado_por ON estoque_movimentacoes(realizado_por);

-- Índice composto para relatórios por período
CREATE INDEX idx_estoque_movimentacoes_loja_periodo 
    ON estoque_movimentacoes(loja_id, realizado_em DESC);

-- ============================================================================
-- TABELA: estoque_alertas
-- ============================================================================
-- Registro de alertas gerados (estoque baixo, validade próxima)
-- Permite rastrear quando alertas foram gerados e visualizados
CREATE TABLE estoque_alertas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_estoque_id UUID NOT NULL REFERENCES itens_estoque(id) ON DELETE CASCADE,
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    
    -- Tipo de alerta
    tipo_alerta TEXT NOT NULL CHECK (tipo_alerta IN (
        'estoque_baixo', 'estoque_critico', 'validade_proxima', 'vencido'
    )),
    
    -- Dados do alerta
    mensagem TEXT NOT NULL,
    nivel_urgencia TEXT NOT NULL DEFAULT 'medio' CHECK (nivel_urgencia IN ('baixo', 'medio', 'alto', 'critico')),
    
    -- Status
    visualizado BOOLEAN DEFAULT false,
    visualizado_por UUID REFERENCES auth.users(id),
    visualizado_em TIMESTAMP WITH TIME ZONE,
    
    resolvido BOOLEAN DEFAULT false,
    resolvido_por UUID REFERENCES auth.users(id),
    resolvido_em TIMESTAMP WITH TIME ZONE,
    observacoes_resolucao TEXT,
    
    -- Auditoria
    gerado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_estoque_alertas_item ON estoque_alertas(item_estoque_id);
CREATE INDEX idx_estoque_alertas_loja ON estoque_alertas(loja_id);
CREATE INDEX idx_estoque_alertas_tipo ON estoque_alertas(tipo_alerta);
CREATE INDEX idx_estoque_alertas_visualizado ON estoque_alertas(visualizado);
CREATE INDEX idx_estoque_alertas_resolvido ON estoque_alertas(resolvido);
CREATE INDEX idx_estoque_alertas_gerado_em ON estoque_alertas(gerado_em DESC);

-- Índice composto para alertas pendentes
CREATE INDEX idx_estoque_alertas_pendentes 
    ON estoque_alertas(loja_id, resolvido, nivel_urgencia, gerado_em DESC) 
    WHERE resolvido = false;

-- ============================================================================
-- TABELA: produto_ingredientes
-- ============================================================================
-- Relaciona produtos com ingredientes do estoque (receita/composição)
-- Permite cálculo automático de consumo quando pedido é aprovado
-- FECHA O CICLO: produto → pedido → estoque (sem gambiarra)
CREATE TABLE produto_ingredientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    item_estoque_id UUID NOT NULL REFERENCES itens_estoque(id) ON DELETE RESTRICT,
    
    -- Quantidade necessária por unidade do produto
    -- Exemplo: Pizza G precisa de 0.300 kg de farinha
    quantidade_por_unidade NUMERIC(10, 6) NOT NULL CHECK (quantidade_por_unidade > 0),
    
    -- Unidade de medida (deve ser compatível com item_estoque)
    unidade_medida TEXT NOT NULL CHECK (unidade_medida IN (
        'kg', 'g', 'l', 'ml', 'un', 'cx', 'pct', 'dz'
    )),
    
    -- Opcional: quantidade pode variar por tamanho
    tamanho_id UUID REFERENCES tamanhos(id) ON DELETE CASCADE,
    
    -- Controle
    obrigatorio BOOLEAN DEFAULT true, -- Se false, ingrediente é opcional
    ativo BOOLEAN DEFAULT true,
    
    -- Auditoria
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação: mesmo produto + ingrediente + tamanho
    UNIQUE(produto_id, item_estoque_id, tamanho_id)
);

-- Índices para performance
CREATE INDEX idx_produto_ingredientes_produto ON produto_ingredientes(produto_id);
CREATE INDEX idx_produto_ingredientes_item_estoque ON produto_ingredientes(item_estoque_id);
CREATE INDEX idx_produto_ingredientes_tamanho ON produto_ingredientes(tamanho_id);
CREATE INDEX idx_produto_ingredientes_ativo ON produto_ingredientes(ativo);

-- ============================================================================
-- TRIGGERS PARA ATUALIZAR updated_at
-- ============================================================================

CREATE TRIGGER update_itens_estoque_updated_at
    BEFORE UPDATE ON itens_estoque
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_produto_ingredientes_updated_at
    BEFORE UPDATE ON produto_ingredientes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Atualizar quantidade_atual após movimentação
-- ============================================================================
-- Sincroniza quantidade_atual do item com a movimentação registrada
-- 
-- IMPORTANTE - CONTROLE DE CONCORRÊNCIA (BACKEND):
-- Para evitar race conditions em movimentações simultâneas, o backend DEVE:
-- 1. Iniciar transação
-- 2. Buscar quantidade_atual com SELECT ... FOR UPDATE (lock)
-- 3. Calcular quantidade_nova
-- 4. Inserir movimentação
-- 5. Commit
-- 
-- Exemplo SQL correto:
-- BEGIN;
-- SELECT quantidade_atual FROM itens_estoque WHERE id = ? FOR UPDATE;
-- -- calcular quantidade_nova no backend
-- INSERT INTO estoque_movimentacoes (...);
-- COMMIT;
-- 
-- ❌ NUNCA fazer: buscar quantidade, calcular no backend, inserir sem lock
-- ✅ SEMPRE fazer: lock na leitura, calcular, inserir, commit

CREATE OR REPLACE FUNCTION atualizar_quantidade_estoque()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualiza quantidade_atual do item
    UPDATE itens_estoque
    SET quantidade_atual = NEW.quantidade_nova,
        updated_at = NOW()
    WHERE id = NEW.item_estoque_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_quantidade_estoque
    AFTER INSERT ON estoque_movimentacoes
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_quantidade_estoque();

-- ============================================================================
-- TRIGGER: Gerar alertas automaticamente
-- ============================================================================
-- Gera alertas quando quantidade fica baixa ou validade próxima
-- 
-- IMPORTANTE - ALTERAÇÃO MANUAL DE QUANTIDADE:
-- Este trigger roda em INSERT e UPDATE de quantidade_atual ou validade.
-- 
-- Comportamento esperado:
-- ✅ Movimentação via estoque_movimentacoes → trigger atualiza quantidade → alerta gerado
-- ✅ Edição manual de quantidade (inventário) → alerta gerado
-- ✅ Edição de outros campos (nome, descrição) → alerta NÃO gerado (correto)
-- 
-- REGRA DE NEGÓCIO (FRONTEND/BACKEND):
-- - Alterar quantidade_atual SEM criar movimentação deve ser EVITADO
-- - Idealmente, UI nunca permite edição direta de quantidade_atual
-- - Toda mudança de quantidade deve passar por estoque_movimentacoes
-- - Exceção: Ajustes de inventário (mas ainda assim criar movimentação tipo 'ajuste')

CREATE OR REPLACE FUNCTION gerar_alertas_estoque()
RETURNS TRIGGER AS $$
DECLARE
    v_tipo_alerta TEXT;
    v_mensagem TEXT;
    v_nivel_urgencia TEXT;
    v_dias_para_vencer INTEGER;
BEGIN
    -- Alerta de estoque baixo/crítico
    IF NEW.avisar_quantidade_baixa = true AND NEW.quantidade_atual <= NEW.quantidade_minima THEN
        -- Define nível de urgência
        IF NEW.quantidade_atual = 0 THEN
            v_tipo_alerta := 'estoque_critico';
            v_nivel_urgencia := 'critico';
            v_mensagem := format('CRÍTICO: Item "%s" está ZERADO no estoque!', NEW.nome);
        ELSIF NEW.quantidade_atual <= (NEW.quantidade_minima * 0.5) THEN
            v_tipo_alerta := 'estoque_critico';
            v_nivel_urgencia := 'alto';
            v_mensagem := format('Item "%s" está com estoque CRÍTICO: %s %s (mínimo: %s %s)', 
                NEW.nome, NEW.quantidade_atual, NEW.unidade_medida, NEW.quantidade_minima, NEW.unidade_medida);
        ELSE
            v_tipo_alerta := 'estoque_baixo';
            v_nivel_urgencia := 'medio';
            v_mensagem := format('Item "%s" está com estoque baixo: %s %s (mínimo: %s %s)', 
                NEW.nome, NEW.quantidade_atual, NEW.unidade_medida, NEW.quantidade_minima, NEW.unidade_medida);
        END IF;
        
        -- Insere alerta (se não existir um não resolvido)
        -- IMPORTANTE: Se item voltou ao normal e caiu de novo, alerta antigo deve estar resolvido=true
        --             Caso contrário, não cria novo alerta (evita duplicação)
        --             Regra de negócio: Admin deve marcar alertas como resolvidos quando repor estoque
        INSERT INTO estoque_alertas (item_estoque_id, loja_id, tipo_alerta, mensagem, nivel_urgencia)
        SELECT NEW.id, NEW.loja_id, v_tipo_alerta, v_mensagem, v_nivel_urgencia
        WHERE NOT EXISTS (
            SELECT 1 FROM estoque_alertas
            WHERE item_estoque_id = NEW.id
              AND tipo_alerta IN ('estoque_baixo', 'estoque_critico')
              AND resolvido = false
        );
    END IF;
    
    -- Alerta de validade próxima
    IF NEW.avisar_validade_proxima = true AND NEW.validade IS NOT NULL THEN
        v_dias_para_vencer := NEW.validade - CURRENT_DATE;
        
        IF v_dias_para_vencer < 0 THEN
            -- Já venceu
            v_tipo_alerta := 'vencido';
            v_nivel_urgencia := 'critico';
            v_mensagem := format('VENCIDO: Item "%s" venceu há %s dias!', NEW.nome, ABS(v_dias_para_vencer));
        ELSIF v_dias_para_vencer <= NEW.dias_alerta_validade THEN
            -- Próximo do vencimento
            v_tipo_alerta := 'validade_proxima';
            v_nivel_urgencia := CASE 
                WHEN v_dias_para_vencer <= 2 THEN 'alto'
                WHEN v_dias_para_vencer <= 5 THEN 'medio'
                ELSE 'baixo'
            END;
            v_mensagem := format('Item "%s" vence em %s dias (validade: %s)', 
                NEW.nome, v_dias_para_vencer, TO_CHAR(NEW.validade, 'DD/MM/YYYY'));
        ELSE
            -- Validade OK, não gera alerta
            RETURN NEW;
        END IF;
        
        -- Insere alerta (se não existir um não resolvido)
        -- IMPORTANTE: Mesma regra de duplicação - alerta antigo deve estar resolvido
        INSERT INTO estoque_alertas (item_estoque_id, loja_id, tipo_alerta, mensagem, nivel_urgencia)
        SELECT NEW.id, NEW.loja_id, v_tipo_alerta, v_mensagem, v_nivel_urgencia
        WHERE NOT EXISTS (
            SELECT 1 FROM estoque_alertas
            WHERE item_estoque_id = NEW.id
              AND tipo_alerta IN ('validade_proxima', 'vencido')
              AND resolvido = false
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_gerar_alertas_estoque
    AFTER INSERT OR UPDATE OF quantidade_atual, validade ON itens_estoque
    FOR EACH ROW
    EXECUTE FUNCTION gerar_alertas_estoque();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de itens com estoque baixo
CREATE OR REPLACE VIEW itens_estoque_baixo AS
SELECT 
    ie.*,
    ROUND((ie.quantidade_atual / NULLIF(ie.quantidade_minima, 0) * 100), 2) AS percentual_minimo,
    CASE 
        WHEN ie.quantidade_atual = 0 THEN 'ZERADO'
        WHEN ie.quantidade_atual <= (ie.quantidade_minima * 0.5) THEN 'CRÍTICO'
        ELSE 'BAIXO'
    END AS status_estoque
FROM itens_estoque ie
WHERE ie.deleted_at IS NULL
  AND ie.ativo = true
  AND ie.quantidade_atual <= ie.quantidade_minima
ORDER BY ie.quantidade_atual / NULLIF(ie.quantidade_minima, 0), ie.nome;

-- View de itens próximos do vencimento
CREATE OR REPLACE VIEW itens_validade_proxima AS
SELECT 
    ie.*,
    ie.validade - CURRENT_DATE AS dias_para_vencer,
    CASE 
        WHEN ie.validade < CURRENT_DATE THEN 'VENCIDO'
        WHEN ie.validade - CURRENT_DATE <= 2 THEN 'URGENTE'
        WHEN ie.validade - CURRENT_DATE <= 5 THEN 'ATENÇÃO'
        ELSE 'PRÓXIMO'
    END AS status_validade
FROM itens_estoque ie
WHERE ie.deleted_at IS NULL
  AND ie.ativo = true
  AND ie.validade IS NOT NULL
  AND ie.validade - CURRENT_DATE <= ie.dias_alerta_validade
ORDER BY ie.validade, ie.nome;

-- View de movimentações com detalhes
CREATE OR REPLACE VIEW estoque_movimentacoes_detalhado AS
SELECT 
    em.*,
    ie.nome AS item_nome,
    ie.unidade_medida,
    ie.categoria,
    p.nome AS realizado_por_nome,
    ped.codigo_pedido,
    CASE 
        WHEN em.tipo_movimentacao LIKE 'entrada_%' THEN 'ENTRADA'
        ELSE 'SAÍDA'
    END AS direcao
FROM estoque_movimentacoes em
INNER JOIN itens_estoque ie ON em.item_estoque_id = ie.id
LEFT JOIN profiles p ON em.realizado_por = p.id
LEFT JOIN pedidos ped ON em.pedido_id = ped.id
ORDER BY em.realizado_em DESC;

-- View de alertas pendentes
CREATE OR REPLACE VIEW estoque_alertas_pendentes AS
SELECT 
    ea.*,
    ie.nome AS item_nome,
    ie.quantidade_atual,
    ie.quantidade_minima,
    ie.unidade_medida,
    ie.validade
FROM estoque_alertas ea
INNER JOIN itens_estoque ie ON ea.item_estoque_id = ie.id
WHERE ea.resolvido = false
ORDER BY 
    CASE ea.nivel_urgencia
        WHEN 'critico' THEN 1
        WHEN 'alto' THEN 2
        WHEN 'medio' THEN 3
        ELSE 4
    END,
    ea.gerado_em DESC;

-- View de valor total do estoque por loja
CREATE OR REPLACE VIEW estoque_valor_total AS
SELECT 
    loja_id,
    l.nome AS loja_nome,
    COUNT(*) AS total_itens,
    COUNT(*) FILTER (WHERE quantidade_atual > 0) AS itens_com_estoque,
    COUNT(*) FILTER (WHERE quantidade_atual = 0) AS itens_zerados,
    SUM(custo_total) AS valor_total_estoque,
    SUM(CASE WHEN quantidade_atual <= quantidade_minima THEN 1 ELSE 0 END) AS itens_estoque_baixo
FROM itens_estoque ie
INNER JOIN lojas l ON ie.loja_id = l.id
WHERE ie.deleted_at IS NULL AND ie.ativo = true
GROUP BY loja_id, l.nome;

-- View de produtos com ingredientes (receita completa)
CREATE OR REPLACE VIEW produtos_receita AS
SELECT 
    p.id AS produto_id,
    p.nome AS produto_nome,
    p.categoria_id,
    t.id AS tamanho_id,
    t.tamanho_label,
    pi.id AS ingrediente_id,
    ie.nome AS ingrediente_nome,
    pi.quantidade_por_unidade,
    pi.unidade_medida,
    ie.quantidade_atual AS estoque_disponivel,
    ie.unidade_medida AS estoque_unidade,
    pi.obrigatorio,
    CASE 
        WHEN ie.quantidade_atual = 0 THEN 'SEM_ESTOQUE'
        WHEN ie.quantidade_atual <= ie.quantidade_minima THEN 'ESTOQUE_BAIXO'
        ELSE 'OK'
    END AS status_ingrediente
FROM produtos p
INNER JOIN produto_ingredientes pi ON p.id = pi.produto_id
INNER JOIN itens_estoque ie ON pi.item_estoque_id = ie.id
LEFT JOIN tamanhos t ON pi.tamanho_id = t.id
WHERE p.deleted_at IS NULL 
  AND p.ativo = true
  AND pi.ativo = true
  AND ie.deleted_at IS NULL
  AND ie.ativo = true
ORDER BY p.nome, t.ordem_exibicao, ie.nome;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE itens_estoque IS 'Cadastro de itens do estoque (ingredientes, insumos, embalagens) com controle de quantidade e validade';
COMMENT ON TABLE estoque_movimentacoes IS 'Histórico completo de movimentações de estoque (entradas e saídas) para rastreabilidade e auditoria';
COMMENT ON TABLE estoque_alertas IS 'Registro de alertas gerados automaticamente (estoque baixo, validade próxima) com controle de visualização e resolução';
COMMENT ON TABLE produto_ingredientes IS 'Relaciona produtos com ingredientes do estoque (receita/composição). Permite cálculo automático de consumo quando pedido é aprovado. FECHA O CICLO: produto → pedido → estoque';

COMMENT ON COLUMN itens_estoque.quantidade_atual IS 'Quantidade atual em estoque (atualizada automaticamente via trigger). IMPORTANTE: Nunca editar diretamente, sempre criar movimentação';
COMMENT ON COLUMN itens_estoque.quantidade_minima IS 'Quantidade mínima para gerar alerta de estoque baixo';
COMMENT ON COLUMN itens_estoque.quantidade_maxima IS 'Quantidade máxima recomendada (opcional, para controle de compras)';
COMMENT ON COLUMN itens_estoque.categoria IS 'Categoria do item. NOTA: Valores fixos por simplicidade. Para 100% flexível, evoluir para tabela categorias_estoque com FK';
COMMENT ON COLUMN itens_estoque.unidade_base IS 'Unidade base para conversão (g, ml, un). Permite comprar em kg e consumir em g';
COMMENT ON COLUMN itens_estoque.fator_conversao IS 'Fator de conversão para unidade_base. Exemplo: kg→g = 1000';
COMMENT ON COLUMN itens_estoque.validade IS 'Data de validade única/média. Para controle preciso por lote, evoluir para tabela estoque_lotes';
COMMENT ON COLUMN itens_estoque.avisar_quantidade_baixa IS 'Se true, gera alerta automático quando quantidade <= quantidade_minima';
COMMENT ON COLUMN itens_estoque.avisar_validade_proxima IS 'Se true, gera alerta automático quando validade próxima';
COMMENT ON COLUMN itens_estoque.dias_alerta_validade IS 'Quantos dias antes do vencimento deve gerar alerta (padrão: 7 dias)';
COMMENT ON COLUMN itens_estoque.custo_total IS 'Custo total calculado automaticamente (quantidade_atual * custo_unitario)';

COMMENT ON COLUMN estoque_movimentacoes.tipo_movimentacao IS 'Tipo: entrada_compra, entrada_devolucao, entrada_ajuste, saida_consumo, saida_perda, saida_venda, saida_ajuste';
COMMENT ON COLUMN estoque_movimentacoes.quantidade_anterior IS 'Snapshot da quantidade antes da movimentação (auditoria)';
COMMENT ON COLUMN estoque_movimentacoes.quantidade_nova IS 'Snapshot da quantidade depois da movimentação (auditoria)';
COMMENT ON COLUMN estoque_movimentacoes.pedido_id IS 'Vinculação com pedido (quando movimentação for por consumo em produção). IMPORTANTE: 1 pedido pode gerar VÁRIAS movimentações. NUNCA deletar pedidos, apenas cancelar';

COMMENT ON COLUMN estoque_alertas.tipo_alerta IS 'Tipo: estoque_baixo, estoque_critico, validade_proxima, vencido';
COMMENT ON COLUMN estoque_alertas.nivel_urgencia IS 'Nível de urgência: baixo, medio, alto, critico';
COMMENT ON COLUMN estoque_alertas.visualizado IS 'Se true, alerta foi visualizado por alguém';
COMMENT ON COLUMN estoque_alertas.resolvido IS 'Se true, problema foi resolvido (compra realizada, item reposto, etc). IMPORTANTE: Deve ser marcado como true quando item voltar ao normal, senão não gera novo alerta se cair novamente';

COMMENT ON COLUMN produto_ingredientes.quantidade_por_unidade IS 'Quantidade necessária por unidade do produto. Exemplo: Pizza G precisa de 0.300 kg de farinha';
COMMENT ON COLUMN produto_ingredientes.tamanho_id IS 'Opcional: permite quantidade diferente por tamanho (Pizza P usa menos farinha que Pizza G)';
COMMENT ON COLUMN produto_ingredientes.obrigatorio IS 'Se false, ingrediente é opcional (não bloqueia produção se faltar)';

COMMENT ON VIEW itens_estoque_baixo IS 'View com itens que estão com estoque abaixo do mínimo, ordenados por criticidade';
COMMENT ON VIEW itens_validade_proxima IS 'View com itens próximos do vencimento ou já vencidos';
COMMENT ON VIEW estoque_movimentacoes_detalhado IS 'View com movimentações e informações relacionadas (item, usuário, pedido)';
COMMENT ON VIEW estoque_alertas_pendentes IS 'View com alertas não resolvidos, ordenados por urgência';
COMMENT ON VIEW estoque_valor_total IS 'View com valor total do estoque e estatísticas por loja';
COMMENT ON VIEW produtos_receita IS 'View com produtos e seus ingredientes (receita completa). Mostra status do estoque de cada ingrediente. Útil para verificar se produto pode ser produzido';

COMMENT ON FUNCTION atualizar_quantidade_estoque IS 'Trigger que atualiza automaticamente quantidade_atual do item após cada movimentação. IMPORTANTE: Backend deve usar transação com SELECT FOR UPDATE para evitar race conditions';
COMMENT ON FUNCTION gerar_alertas_estoque IS 'Trigger que gera alertas automaticamente quando quantidade fica baixa ou validade próxima. Roda em INSERT/UPDATE de quantidade_atual ou validade. IMPORTANTE: Não gera alerta duplicado se já existir um não resolvido (resolvido=false). Alteração manual de quantidade deve ser evitada (sempre criar movimentação)';

-- ============================================================================
-- REGRAS DE NEGÓCIO IMPORTANTES (PARA BACKEND/FRONTEND)
-- ============================================================================
-- 
-- 1. CONTROLE DE CONCORRÊNCIA
--    - Movimentações simultâneas podem causar race condition
--    - SEMPRE usar transação com SELECT ... FOR UPDATE
--    - Exemplo correto:
--      BEGIN;
--      SELECT quantidade_atual FROM itens_estoque WHERE id = ? FOR UPDATE;
--      -- calcular quantidade_nova
--      INSERT INTO estoque_movimentacoes (...);
--      COMMIT;
-- 
-- 2. ALTERAÇÃO DE QUANTIDADE
--    - NUNCA editar quantidade_atual diretamente
--    - SEMPRE criar movimentação (entrada_ajuste ou saida_ajuste)
--    - Exceção: Inventário inicial (mas ainda assim criar movimentação)
--    - UI não deve permitir edição direta de quantidade_atual
-- 
-- 3. ALERTAS DUPLICADOS
--    - Sistema não gera alerta duplicado se já existir um não resolvido
--    - Admin DEVE marcar alertas como resolvidos quando repor estoque
--    - Se item volta ao normal e cai de novo, alerta antigo deve estar resolvido=true
-- 
-- 4. PEDIDOS E ESTOQUE
--    - 1 pedido pode gerar VÁRIAS movimentações (ingredientes diferentes)
--    - NUNCA deletar pedidos, apenas cancelar
--    - Estoque não deve "sumir" junto com pedido (ON DELETE SET NULL)
-- 
-- 5. CONSUMO AUTOMÁTICO (via produto_ingredientes)
--    - Quando pedido é aprovado, backend deve:
--      a) Ler produto_ingredientes
--      b) Calcular consumo total
--      c) Criar movimentações tipo 'saida_consumo'
--      d) Vincular com pedido_id
-- 
-- ============================================================================

-- ============================================================================
-- ROADMAP FUTURO (EVOLUÇÃO DO SISTEMA)
-- ============================================================================
-- 
-- 1. CONTROLE POR LOTE (quando precisar de rastreabilidade avançada)
--    CREATE TABLE estoque_lotes (
--        id UUID PRIMARY KEY,
--        item_estoque_id UUID REFERENCES itens_estoque(id),
--        lote TEXT NOT NULL,
--        validade DATE,
--        quantidade NUMERIC(10,3),
--        custo_unitario NUMERIC(10,2),
--        data_entrada DATE
--    );
--    Benefícios: Rastreabilidade por fornecedor, FIFO/FEFO automático
-- 
-- 2. CATEGORIAS DINÂMICAS (quando precisar de mais flexibilidade)
--    CREATE TABLE categorias_estoque (
--        id UUID PRIMARY KEY,
--        nome TEXT NOT NULL,
--        slug TEXT UNIQUE NOT NULL,
--        ativo BOOLEAN DEFAULT true
--    );
--    ALTER TABLE itens_estoque ADD COLUMN categoria_id UUID REFERENCES categorias_estoque(id);
--    Benefícios: Admin pode criar categorias sem alterar código
-- 
-- 3. CONSUMO AUTOMÁTICO POR PEDIDO (já preparado com produto_ingredientes)
--    Fluxo: Pedido aprovado → Sistema calcula ingredientes → Gera saida_consumo
--    Implementar: Trigger ou função no backend que lê produto_ingredientes
-- 
-- 4. PREVISÃO DE COMPRAS (Machine Learning)
--    Análise de histórico de movimentações para prever quando comprar
-- 
-- 5. INTEGRAÇÃO COM FORNECEDORES
--    API para pedidos automáticos quando estoque atingir mínimo
-- 
-- ============================================================================

-- ============================================================================
-- DADOS DE EXEMPLO (OPCIONAL - COMENTADO)
-- ============================================================================

/*
-- Exemplo de item de estoque com conversão
INSERT INTO itens_estoque (
    loja_id, nome, descricao, categoria, unidade_medida,
    unidade_base, fator_conversao,
    quantidade_atual, quantidade_minima, custo_unitario,
    avisar_quantidade_baixa, fornecedor_nome
)
VALUES (
    (SELECT id FROM lojas LIMIT 1),
    'Farinha de Trigo',
    'Farinha de trigo tipo 1 para massas',
    'ingrediente',
    'kg',
    'g',
    1000,
    50.000,
    10.000,
    8.50,
    true,
    'Distribuidora ABC'
);

-- Exemplo de movimentação (entrada)
INSERT INTO estoque_movimentacoes (
    item_estoque_id,
    loja_id,
    tipo_movimentacao,
    quantidade,
    quantidade_anterior,
    quantidade_nova,
    custo_unitario,
    custo_total,
    motivo,
    documento_numero,
    realizado_por
)
VALUES (
    (SELECT id FROM itens_estoque WHERE nome = 'Farinha de Trigo'),
    (SELECT loja_id FROM itens_estoque WHERE nome = 'Farinha de Trigo'),
    'entrada_compra',
    50.000,
    0,
    50.000,
    8.50,
    425.00,
    'Compra inicial de estoque',
    'NF-12345',
    (SELECT id FROM profiles WHERE role_principal = 'admin' LIMIT 1)
);

-- Exemplo de produto_ingredientes (receita)
INSERT INTO produto_ingredientes (
    produto_id,
    item_estoque_id,
    tamanho_id,
    quantidade_por_unidade,
    unidade_medida,
    obrigatorio
)
VALUES (
    (SELECT id FROM produtos WHERE nome = 'Pizza Calabresa'),
    (SELECT id FROM itens_estoque WHERE nome = 'Farinha de Trigo'),
    (SELECT id FROM tamanhos WHERE tamanho_label = 'G'),
    0.300, -- 300g de farinha por pizza G
    'kg',
    true
);
*/
