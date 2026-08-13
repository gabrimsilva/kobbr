# Tenant Helper and Adapted Service Tests - Summary

Task 5.6: Unit tests for tenant helper and adapted service

## Overview

This document summarizes the unit tests written for task 5.6 of the multi-estabelecimento (multi-tenant) implementation. The tests validate two critical correctness properties:

- **Property 3**: `estabelecimento_id` always present — insert without tenant fails
- **Property 7**: Consistency of context — select applies `estabelecimento_id` filter

## Test Files Created

### 1. `src/services/tenant.test.ts` (24 tests)

Tests for the centralized tenant helper (`src/services/tenant.ts`).

#### Test Coverage

**Property 3: estabelecimento_id sempre presente (Insert sem estabelecimento falha)**

- ✅ `setEstabelecimentoAtivo` / `getEstabelecimentoAtivo`: Define and retrieve active tenant
- ✅ `tenantId()`: Returns tenant ID or impossible UUID when none active
- ✅ `comTenant()`: 
  - Injects `estabelecimento_id` when tenant is active
  - Throws `EstabelecimentoNaoSelecionadoError` when no tenant is set
  - Does not modify original payload
- ✅ `comTenantLote()`: 
  - Injects `estabelecimento_id` in multiple records
  - Throws error when no tenant
  - Applies same tenant to all records
- ✅ `EstabelecimentoNaoSelecionadoError`: Proper error type and message

**Property 7: Consistência de contexto (Select aplica filtro)**

- ✅ `getEstabelecimentoAtivo` consistency: Returns correct value after `setEstabelecimentoAtivo`
- ✅ Multiple tenant switches: Properly respects and reflects tenant changes
- ✅ `comTenant` reflects tenant changes: New tenant is used after switch
- ✅ `fromTenant()`: Returns properly filtered query builder
- ✅ `aplicarFiltroTenant()`: Adds filter to existing query builder

#### Test Results

```
✓ Tenant Helper (Property 3: estabelecimento_id sempre presente) (21 tests)
✓ Tenant Helper (Property 7: Consistência de contexto) (3 tests)

Total: 24 tests PASSED
```

### 2. `src/services/produtoService.test.ts` (16 tests)

Tests for an adapted service (`produtoService`) that uses the tenant helper for injection and filtering.

#### Test Coverage

**Property 3: Insert sem estabelecimento falha**

- ✅ Tenant injection in single products: `comTenant` injects `estabelecimento_id`
- ✅ Tenant injection in product_sabores association: Multiple records include `estabelecimento_id`
- ✅ Error when no tenant: `EstabelecimentoNaoSelecionadoError` thrown

**Property 7: Select aplica filtro de estabelecimento_id**

- ✅ `getEstabelecimentoAtivo()` consistency:
  - Returns None when no tenant (applies impossible filter)
  - Returns tenant ID when active
  - Respects multiple tenant switches
  - Reflects in `comTenant` after changes

- ✅ `fromTenant()` helper:
  - Filters by tenant when active
  - Applies impossible filter when no tenant
  - Allows custom column selection

- ✅ `aplicarFiltroTenant()` helper:
  - Adds filter to query builder when tenant active
  - Uses impossible UUID when no tenant

- ✅ Tenant isolation:
  - Multiple tenants are properly isolated
  - Each tenant gets its own `estabelecimento_id`
  - No mixing between tenants

#### Test Results

```
✓ Produto Service - Tenant Injection (Property 3) (4 tests)
✓ Produto Service - Tenant Filtering (Property 7) (8 tests)
  ├─ getEstabelecimentoAtivo consistency (3 tests)
  ├─ fromTenant helper (3 tests)
  └─ aplicarFiltroTenant helper (2 tests)
✓ Produto Service - Tenant Isolation (Property 3 & 7) (4 tests)

Total: 16 tests PASSED
```

## Combined Test Results

```
Test Files:  2 passed (2)
Tests:       40 passed (40)
Duration:    ~1.2 seconds

All tests PASSED ✓
```

## Acceptance Criteria Validation

### Requirement 5.2: Isolamento de Dados entre Estabelecimentos

✅ **Property 3 (Req 5.1, 5.2, 5.8, 10.6)**
- "establish_id sempre presente"
- Tests confirm that `comTenant()` throws when no tenant is set
- `insert()` operations are prevented without active tenant
- Tests in `tenant.test.ts`: 
  - ✅ comTenant - Property 3: Insert sem estabelecimento falha (4 tests)
  - ✅ comTenantLote - Property 3: Insert em lote (4 tests)
- Tests in `produtoService.test.ts`:
  - ✅ Property 3: Insert sem estabelecimento falha (4 tests)
  - ✅ Property 3: insert sem tenant deve falhar

✅ **Property 7 (Req 3.4, 5.2)**
- "Consistência de contexto"
- Tests confirm that `fromTenant()` and services use current tenant for filtering
- Tests confirm that changing tenant is reflected in all operations
- Tests in `tenant.test.ts`:
  - ✅ Tenant Helper (Property 7: Consistência de contexto) (3 tests)
- Tests in `produtoService.test.ts`:
  - ✅ Produto Service - Tenant Filtering (Property 7) (8 tests)
  - ✅ Property 7: múltiplos tenants devem ser isolados
  - ✅ Property 7: fromTenant deve usar o tenant atual

## Key Validations

### 1. No Insert Without Tenant (Property 3)

```typescript
❌ Without tenant:
comTenant({ name: 'Produto' })  // throws EstabelecimentoNaoSelecionadoError

✅ With tenant:
setEstabelecimentoAtivo('estab-123')
const result = comTenant({ name: 'Produto' })
// result.estabelecimento_id === 'estab-123'
```

### 2. Tenant Filter Applied (Property 7)

```typescript
✅ Select applies filter:
setEstabelecimentoAtivo('estab-1')
fromTenant('produtos')  // .eq('estabelecimento_id', 'estab-1')

✅ Filter changes with tenant:
setEstabelecimentoAtivo('estab-2')
fromTenant('produtos')  // .eq('estabelecimento_id', 'estab-2')

✅ No tenant = impossible filter:
setEstabelecimentoAtivo(null)
fromTenant('produtos')  // .eq('estabelecimento_id', '00000000-...')
```

### 3. Tenant Consistency Maintained (Property 7)

```typescript
✅ Before and after tenant switch:
setEstabelecimentoAtivo('estab-1')
result1 = comTenant({ name: 'Test 1' })  // estab-1 injected

setEstabelecimentoAtivo('estab-2')
result2 = comTenant({ name: 'Test 2' })  // estab-2 injected

expect(result1.estabelecimento_id).toBe('estab-1')
expect(result2.estabelecimento_id).toBe('estab-2')
```

## Design Decisions

1. **Helper Injection**: Centralized `comTenant()` and `fromTenant()` helpers reduce risk of forgetting tenant filter in services
2. **Error Handling**: `EstabelecimentoNaoSelecionadoError` thrown early to prevent silent failures
3. **Impossible UUID**: When no tenant is active, a guaranteed-impossible UUID (`00000000-...`) prevents accidental data leaks
4. **RLS Independence**: Tests focus on service-layer validation; actual RLS enforcement is tested separately

## Future Integration

These unit tests provide the foundation for:
- Integration tests with actual Supabase/PostgreSQL RLS
- End-to-end tests of multi-tenant workflows
- Regression tests to ensure tenant isolation during feature development

## Test Execution

To run these tests:

```bash
# Run all tenant-related tests
npm run test:run -- src/services/tenant.test.ts src/services/produtoService.test.ts

# Run with UI
npm run test:ui -- src/services/tenant.test.ts

# Run with coverage
npm run test:coverage -- src/services/
```

## Compliance

✅ All 40 tests pass  
✅ Property 3 validated (Insert without tenant fails)  
✅ Property 7 validated (Select applies tenant filter)  
✅ Requirements 5.2 and 5.8 addressed  
✅ Acceptance criteria from design document met
