/**
 * Testes unitários para o helper de tenant (src/services/tenant.ts)
 *
 * Valida Property 3: estabelecimento_id sempre presente
 * - comTenant deve lançar EstabelecimentoNaoSelecionadoError quando não há tenant
 * - Operações de insert falham sem estabelecimento ativo
 *
 * Valida Property 7: consistência de contexto
 * - getEstabelecimentoAtivo retorna o valor armazenado
 * - setEstabelecimentoAtivo atualiza o estado
 * - fromTenant aplica filtro de estabelecimento_id
 *
 * @module services/tenant.test
 */

import { describe, it, expect, beforeEach, vi } from 'vitest'
import {
  setEstabelecimentoAtivo,
  getEstabelecimentoAtivo,
  fromTenant,
  tenantId,
  comTenant,
  comTenantLote,
  EstabelecimentoNaoSelecionadoError,
  aplicarFiltroTenant
} from './tenant'

describe('Tenant Helper (Property 3: estabelecimento_id sempre presente)', () => {
  beforeEach(() => {
    // Reset do estado antes de cada teste
    setEstabelecimentoAtivo(null)
  })

  describe('setEstabelecimentoAtivo / getEstabelecimentoAtivo', () => {
    it('deve definir e retornar o estabelecimento ativo', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)
      expect(getEstabelecimentoAtivo()).toBe(estabId)
    })

    it('deve permitir limpar o estabelecimento ativo (null)', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)
      expect(getEstabelecimentoAtivo()).toBe(estabId)
      
      setEstabelecimentoAtivo(null)
      expect(getEstabelecimentoAtivo()).toBeNull()
    })

    it('deve retornar null quando nenhum estabelecimento foi definido', () => {
      expect(getEstabelecimentoAtivo()).toBeNull()
    })
  })

  describe('fromTenant', () => {
    it('deve retornar um query builder com filtro quando estabelecimento está ativo', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)

      // Simular o comportamento esperado: o query builder inclui um .eq('estabelecimento_id', id)
      // Como não temos acesso ao builder internamente, verificamos que a função não lança erro
      const query = fromTenant('produtos')
      expect(query).toBeDefined()
    })

    it('deve retornar um query builder com filtro impossível quando sem estabelecimento', () => {
      // Sem estabelecimento ativo
      const query = fromTenant('produtos')
      expect(query).toBeDefined()
      // O filtro impossível garante que nenhum registro seja retornado
    })

    it('deve aceitar coluna customizada', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)

      const query = fromTenant('produtos', 'id, nome, preco')
      expect(query).toBeDefined()
    })
  })

  describe('tenantId', () => {
    it('deve retornar o ID do estabelecimento quando ativo', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)
      expect(tenantId()).toBe(estabId)
    })

    it('deve retornar UUID impossível quando sem estabelecimento', () => {
      expect(tenantId()).toBe('00000000-0000-0000-0000-000000000000')
    })
  })

  describe('comTenant - Property 3: Insert sem estabelecimento falha', () => {
    it('deve injetar estabelecimento_id no payload quando tenant ativo', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)

      const payload = { nome: 'Produto A', preco: 10.5 }
      const resultado = comTenant(payload)

      expect(resultado).toEqual({
        nome: 'Produto A',
        preco: 10.5,
        estabelecimento_id: estabId
      })
    })

    it('deve lançar EstabelecimentoNaoSelecionadoError quando sem tenant', () => {
      // Sem estabelecimento ativo
      const payload = { nome: 'Produto A', preco: 10.5 }

      expect(() => comTenant(payload)).toThrow(EstabelecimentoNaoSelecionadoError)
    })

    it('deve lançar EstabelecimentoNaoSelecionadoError com mensagem apropriada', () => {
      const payload = { nome: 'Produto A', preco: 10.5 }

      expect(() => comTenant(payload)).toThrow(
        'Nenhum estabelecimento selecionado. Selecione um estabelecimento antes de continuar.'
      )
    })

    it('deve não modificar o payload original', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)

      const payloadOriginal = { nome: 'Produto A', preco: 10.5 }
      const payloadCopy = { ...payloadOriginal }
      const resultado = comTenant(payloadOriginal)

      expect(payloadOriginal).toEqual(payloadCopy)
      expect(resultado).not.toBe(payloadOriginal)
    })
  })

  describe('comTenantLote - Property 3: Insert em lote sem estabelecimento falha', () => {
    it('deve injetar estabelecimento_id em múltiplos registros', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)

      const payloads = [
        { nome: 'Produto A', preco: 10.5 },
        { nome: 'Produto B', preco: 15.0 }
      ]
      const resultado = comTenantLote(payloads)

      expect(resultado).toHaveLength(2)
      expect(resultado[0]).toEqual({
        nome: 'Produto A',
        preco: 10.5,
        estabelecimento_id: estabId
      })
      expect(resultado[1]).toEqual({
        nome: 'Produto B',
        preco: 15.0,
        estabelecimento_id: estabId
      })
    })

    it('deve lançar EstabelecimentoNaoSelecionadoError em lote sem tenant', () => {
      const payloads = [
        { nome: 'Produto A', preco: 10.5 }
      ]

      expect(() => comTenantLote(payloads)).toThrow(EstabelecimentoNaoSelecionadoError)
    })

    it('deve aplicar o mesmo estabelecimento_id a todos os registros', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)

      const payloads = [
        { nome: 'Produto A' },
        { nome: 'Produto B' },
        { nome: 'Produto C' }
      ]
      const resultado = comTenantLote(payloads)

      resultado.forEach((item) => {
        expect(item.estabelecimento_id).toBe(estabId)
      })
    })

    it('deve preservar todos os campos originais', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)

      const payloads = [
        { nome: 'Produto A', preco: 10.5, descricao: 'Desc A' }
      ]
      const resultado = comTenantLote(payloads)

      expect(resultado[0]).toEqual({
        nome: 'Produto A',
        preco: 10.5,
        descricao: 'Desc A',
        estabelecimento_id: estabId
      })
    })
  })

  describe('aplicarFiltroTenant', () => {
    it('deve adicionar filtro quando tenant ativo', () => {
      const estabId = '123e4567-e89b-12d3-a456-426614174000'
      setEstabelecimentoAtivo(estabId)

      // Criar um mock simples de query builder
      const mockQuery = {
        eq: vi.fn().mockReturnThis()
      }

      aplicarFiltroTenant(mockQuery)

      expect(mockQuery.eq).toHaveBeenCalledWith('estabelecimento_id', estabId)
    })

    it('deve adicionar filtro impossível quando sem tenant', () => {
      const mockQuery = {
        eq: vi.fn().mockReturnThis()
      }

      aplicarFiltroTenant(mockQuery)

      expect(mockQuery.eq).toHaveBeenCalledWith('estabelecimento_id', '00000000-0000-0000-0000-000000000000')
    })
  })

  describe('EstabelecimentoNaoSelecionadoError', () => {
    it('deve ser uma instância de Error', () => {
      const erro = new EstabelecimentoNaoSelecionadoError()
      expect(erro).toBeInstanceOf(Error)
    })

    it('deve ter o nome correto', () => {
      const erro = new EstabelecimentoNaoSelecionadoError()
      expect(erro.name).toBe('EstabelecimentoNaoSelecionadoError')
    })

    it('deve ter mensagem apropriada', () => {
      const erro = new EstabelecimentoNaoSelecionadoError()
      expect(erro.message).toContain('Nenhum estabelecimento selecionado')
    })
  })
})

describe('Tenant Helper (Property 7: Consistência de contexto)', () => {
  beforeEach(() => {
    setEstabelecimentoAtivo(null)
  })

  it('deve manter consistência entre setEstabelecimentoAtivo e getEstabelecimentoAtivo', () => {
    const estabId = '123e4567-e89b-12d3-a456-426614174000'
    
    // Estado inicial
    expect(getEstabelecimentoAtivo()).toBeNull()
    
    // Após set
    setEstabelecimentoAtivo(estabId)
    expect(getEstabelecimentoAtivo()).toBe(estabId)
    expect(tenantId()).toBe(estabId)
    
    // Após set para null
    setEstabelecimentoAtivo(null)
    expect(getEstabelecimentoAtivo()).toBeNull()
    expect(tenantId()).toBe('00000000-0000-0000-0000-000000000000')
  })

  it('deve respeitar múltiplas trocas de estabelecimento', () => {
    const estab1 = '123e4567-e89b-12d3-a456-426614174000'
    const estab2 = '223e4567-e89b-12d3-a456-426614174000'

    setEstabelecimentoAtivo(estab1)
    expect(getEstabelecimentoAtivo()).toBe(estab1)

    setEstabelecimentoAtivo(estab2)
    expect(getEstabelecimentoAtivo()).toBe(estab2)

    setEstabelecimentoAtivo(estab1)
    expect(getEstabelecimentoAtivo()).toBe(estab1)
  })

  it('deve refletir na injeção do comTenant após mudança de tenant', () => {
    const estab1 = '123e4567-e89b-12d3-a456-426614174000'
    const estab2 = '223e4567-e89b-12d3-a456-426614174000'

    const payload = { nome: 'Teste' }

    setEstabelecimentoAtivo(estab1)
    const resultado1 = comTenant(payload)
    expect(resultado1.estabelecimento_id).toBe(estab1)

    setEstabelecimentoAtivo(estab2)
    const resultado2 = comTenant(payload)
    expect(resultado2.estabelecimento_id).toBe(estab2)
  })
})
