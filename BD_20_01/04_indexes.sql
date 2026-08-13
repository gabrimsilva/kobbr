-- ============================================================================
-- ÍNDICES
-- ============================================================================
-- Arquivo: 04_indexes.sql
-- Descrição: Índices para otimização de performance
-- Data: 20/01/2026
-- ============================================================================

-- Índices para adicionais
CREATE INDEX IF NOT EXISTS idx_adicionais_ativo ON public.adicionais USING btree (ativo);
CREATE INDEX IF NOT EXISTS idx_adicionais_categoria_id ON public.adicionais USING btree (categoria_id);

-- Índices para avaliacoes
CREATE INDEX IF NOT EXISTS idx_avaliacoes_criado_em ON public.avaliacoes USING btree (criado_em DESC);

-- Índices para categorias
CREATE INDEX IF NOT EXISTS idx_categorias_ordem ON public.categorias USING btree (ordem);

-- Índices para clientes
CREATE INDEX IF NOT EXISTS idx_clientes_cpf ON public.clientes USING btree (cpf) WHERE (cpf IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_clientes_criado_em ON public.clientes USING btree (criado_em);
CREATE INDEX IF NOT EXISTS idx_clientes_telefone ON public.clientes USING btree (telefone);

-- Índices para comandas
CREATE INDEX IF NOT EXISTS idx_comandas_criado_em ON public.comandas USING btree (criado_em);
CREATE INDEX IF NOT EXISTS idx_comandas_criado_por ON public.comandas USING btree (criado_por);
CREATE INDEX IF NOT EXISTS idx_comandas_editado_por ON public.comandas USING btree (editado_por);
CREATE INDEX IF NOT EXISTS idx_comandas_finalizado_por ON public.comandas USING btree (finalizado_por);
CREATE INDEX IF NOT EXISTS idx_comandas_numero ON public.comandas USING btree (numero_comanda);
CREATE INDEX IF NOT EXISTS idx_comandas_numero_status ON public.comandas USING btree (numero_comanda, status) WHERE (status = 'aberta');
CREATE INDEX IF NOT EXISTS idx_comandas_status ON public.comandas USING btree (status);

-- Índices para combo_produtos
CREATE INDEX IF NOT EXISTS idx_combo_produtos_combo_id ON public.combo_produtos USING btree (combo_id);
CREATE INDEX IF NOT EXISTS idx_combo_produtos_produto_id ON public.combo_produtos USING btree (produto_id);

-- Índices para estoque
CREATE INDEX IF NOT EXISTS idx_estoque_nome ON public.estoque USING btree (nome);

-- Índices para funcionarios
CREATE INDEX IF NOT EXISTS idx_funcionarios_email ON public.funcionarios USING btree (email);
CREATE INDEX IF NOT EXISTS idx_funcionarios_user_id ON public.funcionarios USING btree (user_id);

-- Índices para historico_comandas
CREATE INDEX IF NOT EXISTS idx_historico_comandas_criado_por ON public.historico_comandas USING btree (criado_por);
CREATE INDEX IF NOT EXISTS idx_historico_comandas_finalizado_em ON public.historico_comandas USING btree (finalizado_em);
CREATE INDEX IF NOT EXISTS idx_historico_comandas_finalizado_por ON public.historico_comandas USING btree (finalizado_por);
CREATE INDEX IF NOT EXISTS idx_historico_comandas_numero ON public.historico_comandas USING btree (numero_comanda);

-- Índices para historico_geral
CREATE INDEX IF NOT EXISTS idx_historico_geral_criado_em ON public.historico_geral USING btree (criado_em);
CREATE INDEX IF NOT EXISTS idx_historico_geral_movido_em ON public.historico_geral USING btree (movido_em);
CREATE INDEX IF NOT EXISTS idx_historico_geral_pedido_id ON public.historico_geral USING btree (pedido_id);

-- Índices para historico_pedidos
CREATE INDEX IF NOT EXISTS idx_historico_pedidos_pedido_data ON public.historico_pedidos USING btree (pedido_id, criado_em);
CREATE INDEX IF NOT EXISTS idx_historico_pedidos_pedido_id ON public.historico_pedidos USING btree (pedido_id);

-- Índices para pedidos
CREATE INDEX IF NOT EXISTS idx_pedidos_cancelado_por ON public.pedidos USING btree (cancelado_por);
CREATE INDEX IF NOT EXISTS idx_pedidos_cliente_id ON public.pedidos USING btree (cliente_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pedidos_codigo_pedido ON public.pedidos USING btree (codigo_pedido);
CREATE INDEX IF NOT EXISTS idx_pedidos_criado_em ON public.pedidos USING btree (criado_em);
CREATE INDEX IF NOT EXISTS idx_pedidos_pedido_id ON public.pedidos USING btree (pedido_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_status_data ON public.pedidos USING btree (status, criado_em);
CREATE INDEX IF NOT EXISTS idx_pedidos_mercado_pago_payment_id ON public.pedidos USING btree (mercado_pago_payment_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_mercado_pago_status ON public.pedidos USING btree (mercado_pago_status);

-- Índices para produto_sabores
CREATE INDEX IF NOT EXISTS idx_produto_sabores_produto_id ON public.produto_sabores USING btree (produto_id);
CREATE INDEX IF NOT EXISTS idx_produto_sabores_sabor_id ON public.produto_sabores USING btree (sabor_id);

-- Índices para produtos
CREATE INDEX IF NOT EXISTS idx_produtos_categoria_id ON public.produtos USING btree (categoria_id);
CREATE INDEX IF NOT EXISTS idx_produtos_categoria_nome ON public.produtos USING btree (categoria_nome);

-- Índices para sabores
CREATE INDEX IF NOT EXISTS idx_sabores_categoria_id_fk ON public.sabores USING btree (categoria_id);
CREATE INDEX IF NOT EXISTS idx_sabores_tipo ON public.sabores USING btree (tipo);

-- Índices para tamanhos
CREATE INDEX IF NOT EXISTS idx_tamanhos_produto_id ON public.tamanhos USING btree (produto_id);
CREATE INDEX IF NOT EXISTS idx_tamanhos_produto_ordem ON public.tamanhos USING btree (produto_id, ordem) WHERE (ativo = true);

-- Índices para ia_conversas
CREATE INDEX IF NOT EXISTS idx_ia_conversas_status ON ia_conversas(status);
CREATE INDEX IF NOT EXISTS idx_ia_conversas_criado_em ON ia_conversas(criado_em DESC);

-- Índices para ia_arquivos_temp
CREATE INDEX IF NOT EXISTS idx_ia_arquivos_temp_conversa_id ON ia_arquivos_temp(conversa_id);

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================
