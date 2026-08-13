import { useState, useEffect } from 'react';
import { cacheService, CACHE_KEYS, CACHE_TTL } from '@/lib/cacheService';
import { produtoService, categoriaService, comboService } from '@/services';
import type { ProdutoSupabase, CategoriaSupabase, ComboSupabase } from '@/types/supabase';

/**
 * Hook para carregar produtos com cache
 */
export function useCachedProdutos() {
  const [produtos, setProdutos] = useState<ProdutoSupabase[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadProdutos();
  }, []);

  const loadProdutos = async () => {
    try {
      setLoading(true);
      
      // Tentar buscar do cache primeiro
      const cached = cacheService.get<ProdutoSupabase[]>(CACHE_KEYS.PRODUTOS);
      if (cached) {
        setProdutos(cached);
        setLoading(false);
        return;
      }

      // Se não estiver no cache, buscar do banco
      const data = await produtoService.buscarTodos();
      setProdutos(data);
      
      // Armazenar no cache
      cacheService.set(CACHE_KEYS.PRODUTOS, data, CACHE_TTL.MEDIUM);
    } catch (err) {
      console.error('Erro ao carregar produtos:', err);
      setError(err instanceof Error ? err.message : 'Erro desconhecido');
    } finally {
      setLoading(false);
    }
  };

  const refresh = () => {
    cacheService.remove(CACHE_KEYS.PRODUTOS);
    loadProdutos();
  };

  return { produtos, loading, error, refresh };
}

/**
 * Hook para carregar categorias com cache
 */
export function useCachedCategorias() {
  const [categorias, setCategorias] = useState<CategoriaSupabase[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadCategorias();
  }, []);

  const loadCategorias = async () => {
    try {
      setLoading(true);
      
      const cached = cacheService.get<CategoriaSupabase[]>(CACHE_KEYS.CATEGORIAS);
      if (cached) {
        setCategorias(cached);
        setLoading(false);
        return;
      }

      const data = await categoriaService.buscarTodas();
      setCategorias(data);
      cacheService.set(CACHE_KEYS.CATEGORIAS, data, CACHE_TTL.LONG);
    } catch (err) {
      console.error('Erro ao carregar categorias:', err);
      setError(err instanceof Error ? err.message : 'Erro desconhecido');
    } finally {
      setLoading(false);
    }
  };

  const refresh = () => {
    cacheService.remove(CACHE_KEYS.CATEGORIAS);
    loadCategorias();
  };

  return { categorias, loading, error, refresh };
}

/**
 * Hook para carregar combos com cache
 */
export function useCachedCombos() {
  const [combos, setCombos] = useState<ComboSupabase[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadCombos();
  }, []);

  const loadCombos = async () => {
    try {
      setLoading(true);
      
      const cached = cacheService.get<ComboSupabase[]>(CACHE_KEYS.COMBOS);
      if (cached) {
        setCombos(cached);
        setLoading(false);
        return;
      }

      const data = await comboService.buscarTodos();
      setCombos(data);
      cacheService.set(CACHE_KEYS.COMBOS, data, CACHE_TTL.MEDIUM);
    } catch (err) {
      console.error('Erro ao carregar combos:', err);
      setError(err instanceof Error ? err.message : 'Erro desconhecido');
    } finally {
      setLoading(false);
    }
  };

  const refresh = () => {
    cacheService.remove(CACHE_KEYS.COMBOS);
    loadCombos();
  };

  return { combos, loading, error, refresh };
}

/**
 * Hook para carregar todos os dados do PDV com cache
 */
export function useCachedPDVData() {
  const { produtos, loading: loadingProdutos, error: errorProdutos, refresh: refreshProdutos } = useCachedProdutos();
  const { categorias, loading: loadingCategorias, error: errorCategorias, refresh: refreshCategorias } = useCachedCategorias();
  const { combos, loading: loadingCombos, error: errorCombos, refresh: refreshCombos } = useCachedCombos();

  const loading = loadingProdutos || loadingCategorias || loadingCombos;
  const error = errorProdutos || errorCategorias || errorCombos;

  const refreshAll = () => {
    refreshProdutos();
    refreshCategorias();
    refreshCombos();
  };

  return {
    produtos,
    categorias,
    combos,
    loading,
    error,
    refreshAll,
  };
}
