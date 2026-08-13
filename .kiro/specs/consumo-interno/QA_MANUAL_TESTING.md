# 🧪 Manual QA Testing Guide - Consumo Interno

**Duration**: ~2.5 hours  
**Prerequisite**: Migrations executed in Supabase  
**Environment**: Development or staging

---

## 📋 Quick Setup Before Testing

### 1. Ensure Migrations Are Applied
```bash
# Check if migrations are applied
supabase migration list

# If not, apply them
supabase db push
```

### 2. Ensure Supabase Connection
```bash
# Verify your .env has:
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_key_here
```

### 3. Start Dev Server
```bash
npm run dev
```

Open: http://localhost:5173

---

## 🧑‍💼 User Flow Testing

### Test Case 1: Register Internal Consumption from PDV

**Scenario**: User adds items to cart and registers as internal consumption

**Steps**:
```
1. Navigate to PDV page
   ✓ Button: PDV (in navigation)
   
2. Add 3 items to cart
   ✓ Click product tiles
   ✓ See items added to right panel
   ✓ Total amount shown
   
3. Open payment modal
   ✓ Click "Finalizar Pedido" button
   ✓ Modal appears (PagamentoPix or similar)
   
4. Mark "Consumo Interno" checkbox
   ✓ Checkbox visible
   ✓ Checkbox toggled ON
   ✓ Form fields change:
     - Payment method → disabled
     - Client field → disabled (if any)
     - Total amount → shows R$ 0,00
   
5. Confirm order
   ✓ Click "Confirmar Pedido" button
   ✓ Toast notification: "✓ Consumo Interno registrado com sucesso"
   ✓ Modal closes
   ✓ Cart clears
   ✓ Return to PDV view
```

**Expected Results**:
- ✅ Consumption registered in `internal_consumptions` table
- ✅ Stock updated (items decremented)
- ✅ No sale created with payment (zero amount)
- ✅ User sees success message

**Failure Scenarios**:
- ❌ If stock insufficient → See error: "Estoque insuficiente para [produto]"
- ❌ If RPC fails → See error: "Erro ao registrar consumo: [details]"
- ❌ If unauthorized → See error: "Usuário não autenticado"

---

### Test Case 2: View Consumption in Metrics - Card Component

**Scenario**: After registering consumption, view in Métricas page

**Steps**:
```
1. Navigate to Métricas page
   ✓ Click "Métricas" in navigation
   ✓ Page loads (might take 2-3s)
   
2. Scroll to "Consumo Interno" section
   ✓ Section visible at bottom of page
   ✓ Title: "📦 Consumo Interno"
   
3. Verify Card Component (left side)
   ✓ Title: "Consumo Interno"
   ✓ Subtitle: "Total de unidades consumidas internamente"
   ✓ Large number showing units (should be ≥ 3 from Test Case 1)
   ✓ Period selector showing "Últimos 30 dias" (default)
   ✓ Variation indicator visible (e.g., "+500%" if first time)
   ✓ Statistics below showing:
     - Number of transactions
     - Average units per transaction
   
4. Change period selector
   ✓ Click selector
   ✓ Options: "Últimos 7 dias", "Últimos 30 dias", "Últimos 90 dias", "Último ano"
   ✓ Select different period
   ✓ Card updates in < 2 seconds
   ✓ Verify total matches period
```

**Expected Behavior**:
- ✅ Card loads data < 2s
- ✅ Variation shows vs previous period
- ✅ Period selector changes instantly (< 200ms visual response)
- ✅ Statistics calculate correctly

**Empty State** (if no consumptions):
- ✓ Total shows 0
- ✓ Message: "Nenhum consumo registrado neste período"
- ✓ Variation shows neutral

---

### Test Case 3: View Consumption Evolution - LineChart Component

**Scenario**: View evolution of consumption over time

**Steps**:
```
1. View LineChart (right side, same section)
   ✓ Title: "Evolução de Consumo Interno"
   ✓ Subtitle: "Histórico de consumo ao longo do tempo"
   ✓ Chart visible below title
   ✓ X-axis: Time periods (dates/weeks/months)
   ✓ Y-axis: Quantity
   ✓ Blue line showing data points
   
2. Verify default display
   ✓ Default period: "Últimos 30 dias"
   ✓ Default granularity: "Por dia"
   ✓ Chart shows daily data for 30 days
   
3. Change time interval
   ✓ Click interval selector
   ✓ Options: "Últimos 30 dias", "Últimos 90 dias", "Último ano"
   ✓ Select "Último ano"
   ✓ Chart updates in < 1 second
   ✓ Granularity auto-changes to "Por mês"
   ✓ Chart shows 12 months of data
   
4. Change granularity
   ✓ Click granularity selector
   ✓ Options: "Por dia", "Por semana", "Por mês"
   ✓ Select "Por semana"
   ✓ Chart updates in < 500ms
   ✓ Data grouped by week
   
5. Test tooltip
   ✓ Hover over a data point
   ✓ Tooltip appears showing:
     - 📦 Unidades: [number]
     - 🔄 Transações: [number]
     - 📊 Média: [number with 2 decimals]
   ✓ Tooltip style: white background, gray border
   ✓ Disappear on mouse leave
   
6. View statistics panel
   ✓ Above chart: 4 statistics
     - Total: sum of all units
     - Transações: count of consumptions
     - Pico: highest day/week/month
     - Mínimo: lowest day/week/month
   ✓ Stats update when interval/granularity changes
```

**Expected Behavior**:
- ✅ Chart renders < 1s even with 365 data points
- ✅ Interval selector changes auto-update granularity
- ✅ Tooltip shows correct data
- ✅ Statistics calculate correctly
- ✅ X-axis rotates when many data points (> 20)

**Edge Cases**:
- 🔵 No data for period → Show message "Nenhum dado disponível"
- 🔵 Single data point → Chart still renders (single dot)
- 🔵 Weekend gaps → Chart shows only populated days (no gaps)

---

## 📱 Responsive Design Testing

### Test Case 4: Mobile Responsiveness

**Steps**:
```
1. Open DevTools (F12)
   
2. Toggle device toolbar (Ctrl+Shift+M)
   
3. Set to iPhone 12 Pro (390px)
   ✓ CardConsumoInterno stacks vertically
   ✓ LineChartConsumoInterno takes full width
   ✓ Period selector still functional
   ✓ Chart scales to mobile width
   ✓ No horizontal scroll
   
4. Test tablet (iPad, 768px)
   ✓ Card and Chart side-by-side if space allows
   ✓ Or stacked depending on layout rules
   ✓ Touch-friendly selector sizing
   
5. Test desktop (1920px)
   ✓ 3-column grid: Card (1/3) + Chart (2/3)
   ✓ Maximum width readable
```

---

## 🔒 Security & Isolation Testing

### Test Case 5: RLS Isolation (Multi-Tenant)

**Scenario**: User A cannot see User B's consumption

**Prerequisite**:
- Create 2 establishments in DB
- Create 2 users (one per establishment)
- User A registers consumption in Est. A
- User B logs in

**Steps**:
```
1. Login as User A (Estabelecimento A)
   ✓ Register consumption in PDV
   
2. Navigate to Métricas
   ✓ CardConsumoInterno shows total from Est. A
   ✓ LineChartConsumoInterno shows data from Est. A
   
3. Logout and login as User B (Estabelecimento B)
   
4. Navigate to Métricas
   ✓ CardConsumoInterno shows 0 (no consumptions for Est. B)
   ✓ LineChartConsumoInterno shows empty state
   ✓ Message: "Nenhum consumo registrado neste período"
```

**Expected Result**:
- ✅ User B does NOT see User A's data
- ✅ Each user sees only their establishment's data
- ✅ RLS policies working correctly

---

## ⚡ Performance Testing

### Test Case 6: Performance Metrics

**Equipment**: Laptop/Desktop (Chrome DevTools)

**Steps**:
```
1. Open DevTools (F12)
   
2. Go to Performance tab
   
3. Record while loading Métricas page
   ✓ Total page load: < 3 seconds
   ✓ CardConsumoInterno render: < 50ms
   ✓ LineChartConsumoInterno render: < 200ms (with data)
   
4. Network tab
   ✓ RPC calls made: 2 (obter_consumos_por_periodo x2 for card + chart)
   ✓ RPC latency: < 500ms each
   ✓ Total network time: < 1s
   
5. Change period on Card
   ✓ Record performance
   ✓ Response time: < 200ms
   ✓ No layout shift
   
6. Change granularity on Chart
   ✓ Record performance
   ✓ Response time: < 300ms
   ✓ Smooth animation
```

---

## ❌ Error Handling Testing

### Test Case 7: Error Scenarios

**Scenario 1: Network Error**
```
1. Open DevTools Network tab
2. Throttle to "Offline"
3. Change period on Card
   ✓ See loading state (spinner)
   ✓ After timeout, see error: "Erro ao carregar dados"
   ✓ Error icon + message displayed
```

**Scenario 2: RPC Function Fails**
```
1. Database is down (or RPC disabled)
2. Navigate to Métricas
   ✓ Page loads but Consumo Interno section shows error
   ✓ Error message visible: "[error details]"
   ✓ Retry button available (if implemented)
```

**Scenario 3: Invalid Data**
```
1. Try to register consumption with 0 items
   ✓ Validation prevents submission
   ✓ Message: "Adicione pelo menos um item ao carrinho"
   
2. Try to register consumption with stock insufficient
   ✓ RPC returns error
   ✓ Toast shows: "Estoque insuficiente para [item]"
```

---

## 📊 Data Validation Testing

### Test Case 8: Data Accuracy

**Steps**:
```
1. Register consumption: 5 units of Item A
   
2. Open SQL Editor in Supabase Dashboard
   
3. Query: SELECT * FROM internal_consumptions WHERE sale_id = '...'
   ✓ Record exists
   ✓ total_quantity = 5
   ✓ consumed_at = today's date
   ✓ estabelecimento_id = current user's establishment
   
4. Query: SELECT quantity FROM stock_items WHERE id = 'item_a_id'
   ✓ Quantity decreased by 5
   
5. Open Métricas page
   ✓ CardConsumoInterno shows 5 units
   ✓ LineChartConsumoInterno shows 1 transaction with 5 units
   
6. Calculate: 5 units / 1 transaction = 5 average
   ✓ Card statistics show average = 5
```

---

## 🎯 Browser Compatibility

### Test Case 9: Cross-Browser Testing

**Test on**:
- ✓ Chrome 120+ (Primary)
- ✓ Firefox 121+ (Secondary)
- ✓ Safari 17+ (if available)
- ✓ Edge 120+

**For each browser**:
```
1. Load Métricas page
   ✓ No console errors
   ✓ No UI rendering issues
   
2. Change period selector
   ✓ Works smoothly
   
3. Hover over chart
   ✓ Tooltip appears correctly
   ✓ Chart interactive
   
4. Mobile view (if browser supports)
   ✓ Responsive behavior works
```

---

## ✅ Final Sign-Off Checklist

```
FUNCTIONALITY
[ ] PDV → Register Consumo → See in Metrics (full flow)
[ ] Card shows correct total
[ ] Card shows correct variation
[ ] Chart shows correct evolution
[ ] Period selector works (Card)
[ ] Interval selector works (Chart)
[ ] Granularity selector works (Chart)

RESPONSIVENESS
[ ] Mobile (< 400px): Stacked layout
[ ] Tablet (768px): Appropriate layout
[ ] Desktop (> 1200px): Full 3-column layout

PERFORMANCE
[ ] Page load < 3s
[ ] Card updates < 2s
[ ] Chart updates < 1s
[ ] Chart renders < 200ms with 365 points

SECURITY
[ ] User A sees only User A's data
[ ] User B sees only User B's data
[ ] RLS policies enforced

ERROR HANDLING
[ ] Network errors show error message
[ ] Empty state handled (no data)
[ ] Loading states visible
[ ] Validation messages clear

CROSS-BROWSER
[ ] Chrome: ✓
[ ] Firefox: ✓
[ ] Safari: ✓
[ ] Edge: ✓

DATA ACCURACY
[ ] DB records match displayed totals
[ ] Stock decremented correctly
[ ] Statistics calculate correctly
[ ] Dates/times accurate
```

---

## 📝 Test Report Template

**After completing all tests, fill in**:

```
PHASE 4 MANUAL QA REPORT
=======================

Date: ___________
Tester: __________
Environment: Dev / Staging / Production
Browser: __________
Device: __________

PASS / FAIL by Test Case:
- Test 1 (PDV Registration): [ ] PASS [ ] FAIL - Notes: ___
- Test 2 (Card Display): [ ] PASS [ ] FAIL - Notes: ___
- Test 3 (Chart Display): [ ] PASS [ ] FAIL - Notes: ___
- Test 4 (Responsive): [ ] PASS [ ] FAIL - Notes: ___
- Test 5 (Security): [ ] PASS [ ] FAIL - Notes: ___
- Test 6 (Performance): [ ] PASS [ ] FAIL - Notes: ___
- Test 7 (Errors): [ ] PASS [ ] FAIL - Notes: ___
- Test 8 (Accuracy): [ ] PASS [ ] FAIL - Notes: ___
- Test 9 (Browser): [ ] PASS [ ] FAIL - Notes: ___

OVERALL: [ ] PASS - Ready for Deploy [ ] FAIL - See notes

Issues Found:
1. ___
2. ___
3. ___

Sign-Off: __________ Date: __________
```

---

## 🚀 Next Steps After Testing

1. **If PASS**: Proceed to production deployment
2. **If FAIL**: 
   - Document issues
   - Create bug fixes
   - Retest failed cases
   - Repeat until PASS

3. **After Deploy**:
   - Monitor error logs (Supabase)
   - Check performance metrics
   - Gather user feedback
   - Plan Phase 5 optimizations

---

**Good luck testing!** 🎉

If you encounter issues, check browser console (F12) for detailed logs prefixed with 📦, 📊, ✅, ❌.
