-- ============================================
-- MIGRATION: Sistema de Estoque Automático
-- Data: 2026-02-26
-- Descrição: Adiciona controle de estoque com variedades
-- ============================================
-- 
-- INSTRUÇÕES:
-- 1. Abra o Supabase SQL Editor
-- 2. Copie e cole TODO este arquivo
-- 3. Execute
-- ============================================

-- ============================================
-- 1. ALTERAR TABELA PRODUTOS
-- ============================================
ALTER TABLE produtos 
ADD COLUMN IF NOT EXISTS requires_stock BOOLEAN DEFAULT true;

COMMENT ON COLUMN produtos.requires_stock IS 'Indica se o produto precisa de controle de estoque';

-- ============================================
-- 2. CRIAR TABELA STOCK_ITEMS
-- ============================================
CREATE TABLE IF NOT EXISTS stock_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL UNIQUE,
    total_qty INTEGER DEFAULT 0 CHECK (total_qty >= 0),
    min_qty INTEGER DEFAULT 0 CHECK (min_qty >= 0),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT fk_stock_product 
        FOREIGN KEY (product_id) 
        REFERENCES produtos(id) 
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_stock_items_product_id ON stock_items(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_items_active ON stock_items(active);

COMMENT ON TABLE stock_items IS 'Controle de estoque por produto';
COMMENT ON COLUMN stock_items.product_id IS 'Produto vinculado (único)';
COMMENT ON COLUMN stock_items.total_qty IS 'Quantidade total em estoque';
COMMENT ON COLUMN stock_items.min_qty IS 'Quantidade mínima (alerta)';
COMMENT ON COLUMN stock_items.active IS 'Estoque ativo';

-- ============================================
-- 3. CRIAR TABELA STOCK_VARIANTS
-- ============================================
CREATE TABLE IF NOT EXISTS stock_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_item_id UUID NOT NULL,
    label VARCHAR(100) NOT NULL,
    sku VARCHAR(100),
    qty INTEGER DEFAULT 0 CHECK (qty >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT fk_variant_stock 
        FOREIGN KEY (stock_item_id) 
        REFERENCES stock_items(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT uq_stock_variant_label 
        UNIQUE (stock_item_id, label)
);

CREATE INDEX IF NOT EXISTS idx_stock_variants_stock_item ON stock_variants(stock_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_variants_sku ON stock_variants(sku);

COMMENT ON TABLE stock_variants IS 'Variedades de um produto (cor, fragrância, tamanho)';
COMMENT ON COLUMN stock_variants.stock_item_id IS 'Item de estoque pai';
COMMENT ON COLUMN stock_variants.label IS 'Nome da variante (ex: Rosa Claro, Lavanda, 50ml)';
COMMENT ON COLUMN stock_variants.sku IS 'Código SKU da variante (opcional)';
COMMENT ON COLUMN stock_variants.qty IS 'Quantidade específica desta variante';

-- ============================================
-- 4. CRIAR TABELA STOCK_MOVEMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_item_id UUID NOT NULL,
    variant_id UUID,
    type VARCHAR(10) NOT NULL CHECK (type IN ('IN', 'OUT', 'ADJUST')),
    qty INTEGER NOT NULL,
    ref_type VARCHAR(50),
    ref_id UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT fk_movement_stock 
        FOREIGN KEY (stock_item_id) 
        REFERENCES stock_items(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_movement_variant 
        FOREIGN KEY (variant_id) 
        REFERENCES stock_variants(id) 
        ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_stock_movements_stock_item ON stock_movements(stock_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_variant ON stock_movements(variant_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_type ON stock_movements(type);
CREATE INDEX IF NOT EXISTS idx_stock_movements_ref ON stock_movements(ref_type, ref_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_created ON stock_movements(created_at DESC);

COMMENT ON TABLE stock_movements IS 'Histórico de movimentações de estoque';
COMMENT ON COLUMN stock_movements.type IS 'Tipo: IN (entrada), OUT (saída), ADJUST (ajuste)';
COMMENT ON COLUMN stock_movements.qty IS 'Quantidade movimentada (positivo ou negativo)';
COMMENT ON COLUMN stock_movements.ref_type IS 'Tipo de referência (SALE, PURCHASE, MANUAL)';
COMMENT ON COLUMN stock_movements.ref_id IS 'ID da referência (ex: ID da venda)';
COMMENT ON COLUMN stock_movements.notes IS 'Observações sobre a movimentação';

-- ============================================
-- 5. TRIGGER PARA UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_stock_items_updated_at ON stock_items;
CREATE TRIGGER trigger_stock_items_updated_at
    BEFORE UPDATE ON stock_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_stock_variants_updated_at ON stock_variants;
CREATE TRIGGER trigger_stock_variants_updated_at
    BEFORE UPDATE ON stock_variants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. FUNÇÃO PARA RECALCULAR TOTAL
-- ============================================
CREATE OR REPLACE FUNCTION recalculate_stock_total(p_stock_item_id UUID)
RETURNS VOID AS $$
DECLARE
    v_total INTEGER;
    v_has_variants BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM stock_variants 
        WHERE stock_item_id = p_stock_item_id
    ) INTO v_has_variants;
    
    IF v_has_variants THEN
        SELECT COALESCE(SUM(qty), 0) 
        INTO v_total
        FROM stock_variants 
        WHERE stock_item_id = p_stock_item_id;
        
        UPDATE stock_items 
        SET total_qty = v_total 
        WHERE id = p_stock_item_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. TRIGGER PARA AUTO-RECALCULAR TOTAL
-- ============================================
CREATE OR REPLACE FUNCTION trigger_recalculate_stock_total()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM recalculate_stock_total(OLD.stock_item_id);
    ELSE
        PERFORM recalculate_stock_total(NEW.stock_item_id);
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_variant_recalculate ON stock_variants;
CREATE TRIGGER trigger_variant_recalculate
    AFTER INSERT OR UPDATE OR DELETE ON stock_variants
    FOR EACH ROW
    EXECUTE FUNCTION trigger_recalculate_stock_total();

-- ============================================
-- 8. POLÍTICAS RLS (Row Level Security)
-- ============================================
ALTER TABLE stock_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir acesso total para autenticados" ON stock_items;
CREATE POLICY "Permitir acesso total para autenticados" ON stock_items
    FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir acesso total para autenticados" ON stock_variants;
CREATE POLICY "Permitir acesso total para autenticados" ON stock_variants
    FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir acesso total para autenticados" ON stock_movements;
CREATE POLICY "Permitir acesso total para autenticados" ON stock_movements
    FOR ALL USING (auth.role() = 'authenticated');

-- ============================================
-- FIM DA MIGRATION
-- ============================================
-- Sucesso! Estrutura de estoque criada.
