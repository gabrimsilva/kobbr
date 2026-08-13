/**
 * Serviço de cache simples para melhorar performance
 * Armazena dados em memória E sessionStorage para persistir entre recargas
 */

interface CacheItem<T> {
  data: T;
  timestamp: number;
  ttl: number; // Time to live em milissegundos
}

class CacheService {
  private cache: Map<string, CacheItem<any>> = new Map();
  private useSessionStorage = true;

  constructor() {
    // Restaurar cache do sessionStorage ao inicializar
    this.restoreFromSessionStorage();
  }

  /**
   * Restaura o cache do sessionStorage
   */
  private restoreFromSessionStorage(): void {
    if (!this.useSessionStorage || typeof window === 'undefined') return;

    try {
      const keys = Object.keys(sessionStorage);
      keys.forEach(key => {
        if (key.startsWith('cache_')) {
          const data = sessionStorage.getItem(key);
          if (data) {
            const cacheKey = key.replace('cache_', '');
            const item = JSON.parse(data) as CacheItem<any>;
            this.cache.set(cacheKey, item);
          }
        }
      });
    } catch (error) {
      // Erro ao restaurar cache
    }
  }

  /**
   * Salva um item no sessionStorage
   */
  private saveToSessionStorage(key: string, item: CacheItem<any>): void {
    if (!this.useSessionStorage || typeof window === 'undefined') return;

    try {
      sessionStorage.setItem(`cache_${key}`, JSON.stringify(item));
    } catch (error) {
      // Erro ao salvar no sessionStorage
    }
  }

  /**
   * Remove um item do sessionStorage
   */
  private removeFromSessionStorage(key: string): void {
    if (!this.useSessionStorage || typeof window === 'undefined') return;

    try {
      sessionStorage.removeItem(`cache_${key}`);
    } catch (error) {
      // Erro ao remover do sessionStorage
    }
  }

  /**
   * Armazena dados no cache
   * @param key - Chave única para o cache
   * @param data - Dados a serem armazenados
   * @param ttl - Tempo de vida em milissegundos (padrão: 5 minutos)
   */
  set<T>(key: string, data: T, ttl: number = 5 * 60 * 1000): void {
    const item: CacheItem<T> = {
      data,
      timestamp: Date.now(),
      ttl,
    };
    
    this.cache.set(key, item);
    this.saveToSessionStorage(key, item);
  }

  /**
   * Recupera dados do cache
   * @param key - Chave do cache
   * @returns Dados armazenados ou null se expirado/não encontrado
   */
  get<T>(key: string): T | null {
    const item = this.cache.get(key);

    if (!item) {
      return null;
    }

    const now = Date.now();
    const isExpired = now - item.timestamp > item.ttl;

    if (isExpired) {
      this.cache.delete(key);
      this.removeFromSessionStorage(key);
      return null;
    }

    return item.data as T;
  }

  /**
   * Remove um item específico do cache
   * @param key - Chave do cache
   */
  remove(key: string): void {
    this.cache.delete(key);
    this.removeFromSessionStorage(key);
  }

  /**
   * Remove todos os itens que começam com um prefixo
   * @param prefix - Prefixo das chaves
   */
  removeByPrefix(prefix: string): void {
    const keysToRemove: string[] = [];
    
    this.cache.forEach((_, key) => {
      if (key.startsWith(prefix)) {
        keysToRemove.push(key);
      }
    });

    keysToRemove.forEach(key => {
      this.cache.delete(key);
      this.removeFromSessionStorage(key);
    });
  }

  /**
   * Limpa todo o cache
   */
  clear(): void {
    this.cache.clear();

    if (typeof window !== 'undefined') {
      try {
        const keys = Object.keys(sessionStorage);
        keys.forEach(key => {
          if (key.startsWith('cache_')) {
            sessionStorage.removeItem(key);
          }
        });
      } catch (error) {
        // Erro ao limpar sessionStorage
      }
    }
  }

  /**
   * Verifica se uma chave existe e não está expirada
   * @param key - Chave do cache
   */
  has(key: string): boolean {
    return this.get(key) !== null;
  }
}

// Instância singleton
export const cacheService = new CacheService();

// Chaves de cache comuns
export const CACHE_KEYS = {
  PRODUTOS: 'produtos',
  CATEGORIAS: 'categorias',
  COMBOS: 'combos',
  SABORES: 'sabores',
  ADICIONAIS: 'adicionais',
  TAMANHOS: (produtoId: string) => `tamanhos_${produtoId}`,
  CONFIGURACOES: 'configuracoes',
};

// Tempos de cache (em milissegundos)
export const CACHE_TTL = {
  SHORT: 2 * 60 * 1000,      // 2 minutos
  MEDIUM: 5 * 60 * 1000,     // 5 minutos
  LONG: 15 * 60 * 1000,      // 15 minutos
  VERY_LONG: 60 * 60 * 1000, // 1 hora
};
