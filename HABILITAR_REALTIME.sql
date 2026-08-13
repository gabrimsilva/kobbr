-- ============================================================================
-- HABILITAR REALTIME (atualização automática do Kanban de pedidos)
-- ============================================================================
-- O app assina mudanças em 'public.pedidos' via postgres_changes. Para o
-- Supabase entregar esses eventos, a tabela precisa estar na publicação
-- 'supabase_realtime'. Por padrão ela NÃO vem habilitada.
-- Idempotente. Rode no SQL Editor do Supabase.
-- ============================================================================

-- 1. Adicionar 'pedidos' à publicação de realtime (se ainda não estiver)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'pedidos'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.pedidos;
  END IF;
END $$;

-- (Opcional) Habilitar também para comandas e histórico, caso queira
-- atualização automática nessas telas. Descomente se desejar:
-- DO $$
-- BEGIN
--   IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
--     WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='comandas') THEN
--     ALTER PUBLICATION supabase_realtime ADD TABLE public.comandas;
--   END IF;
-- END $$;

-- 2. (Recomendado) REPLICA IDENTITY FULL para enviar os dados completos da linha
--    nas atualizações/exclusões (melhora a detecção de mudanças).
ALTER TABLE public.pedidos REPLICA IDENTITY FULL;

-- 3. Conferir quais tabelas estão no realtime
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
