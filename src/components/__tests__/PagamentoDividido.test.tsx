import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import PagamentoDividido from '../PagamentoDividido'

describe('PagamentoDividido Component', () => {
  const defaultProps = {
    totalPedido: 150,
    onConfirm: vi.fn(),
    onCancel: vi.fn(),
    formasPagamento: ['PIX', 'Dinheiro', 'Débito', 'Crédito']
  }

  it('should render component with correct structure', () => {
    render(<PagamentoDividido {...defaultProps} />)
    
    // Verificar título informativo
    expect(screen.getByText(/Configure as duas formas de pagamento/i)).toBeInTheDocument()
    expect(screen.getAllByText(/R\$\s*150,00/)).toHaveLength(2) // Aparece no título e no resumo
    
    // Verificar campos de pagamento 1
    expect(screen.getByText('Pagamento 1')).toBeInTheDocument()
    expect(screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento1Tipo' })).toBeInTheDocument()
    
    // Verificar campos de pagamento 2
    expect(screen.getByText('Pagamento 2')).toBeInTheDocument()
    expect(screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento2Tipo' })).toBeInTheDocument()
    
    // Verificar botões
    expect(screen.getByRole('button', { name: /Cancelar/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Confirmar Pagamento Dividido/i })).toBeInTheDocument()
  })

  it('should disable confirm button initially', () => {
    render(<PagamentoDividido {...defaultProps} />)
    
    const confirmButton = screen.getByRole('button', { name: /Confirmar Pagamento Dividido/i })
    expect(confirmButton).toBeDisabled()
  })

  it('should show error when selecting duplicate payment types', async () => {
    render(<PagamentoDividido {...defaultProps} />)
    
    const select1 = screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento1Tipo' })
    const select2 = screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento2Tipo' })
    
    fireEvent.change(select1, { target: { value: 'PIX' } })
    fireEvent.change(select2, { target: { value: 'PIX' } })
    
    await waitFor(() => {
      expect(screen.getByText(/As formas de pagamento devem ser diferentes/i)).toBeInTheDocument()
    })
  })

  it('should show error when sum is incorrect', async () => {
    render(<PagamentoDividido {...defaultProps} />)
    
    const select1 = screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento1Tipo' })
    const select2 = screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento2Tipo' })
    const input1 = screen.getByLabelText(/Valor/i, { selector: '#pagamento1Valor' })
    const input2 = screen.getByLabelText(/Valor/i, { selector: '#pagamento2Valor' })
    
    fireEvent.change(select1, { target: { value: 'PIX' } })
    fireEvent.change(select2, { target: { value: 'Dinheiro' } })
    fireEvent.change(input1, { target: { value: '50' } })
    fireEvent.change(input2, { target: { value: '50' } })
    
    await waitFor(() => {
      expect(screen.getByText(/A soma dos valores.*deve ser igual ao total do pedido/i)).toBeInTheDocument()
    })
  })

  it('should show error when values are empty or zero', async () => {
    render(<PagamentoDividido {...defaultProps} />)
    
    const select1 = screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento1Tipo' })
    const input1 = screen.getByLabelText(/Valor/i, { selector: '#pagamento1Valor' })
    
    fireEvent.change(select1, { target: { value: 'PIX' } })
    fireEvent.change(input1, { target: { value: '0' } })
    
    await waitFor(() => {
      expect(screen.getByText(/Todos os campos devem ser preenchidos com valores maiores que zero/i)).toBeInTheDocument()
    })
  })

  it('should enable confirm button when configuration is valid', async () => {
    render(<PagamentoDividido {...defaultProps} />)
    
    const select1 = screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento1Tipo' })
    const select2 = screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento2Tipo' })
    const input1 = screen.getByLabelText(/Valor/i, { selector: '#pagamento1Valor' })
    const input2 = screen.getByLabelText(/Valor/i, { selector: '#pagamento2Valor' })
    
    fireEvent.change(select1, { target: { value: 'PIX' } })
    fireEvent.change(select2, { target: { value: 'Dinheiro' } })
    fireEvent.change(input1, { target: { value: '50' } })
    fireEvent.change(input2, { target: { value: '100' } })
    
    await waitFor(() => {
      const confirmButton = screen.getByRole('button', { name: /Confirmar Pagamento Dividido/i })
      expect(confirmButton).not.toBeDisabled()
    })
  })

  it('should call onConfirm with correct data when confirmed', async () => {
    const onConfirm = vi.fn()
    render(<PagamentoDividido {...defaultProps} onConfirm={onConfirm} />)
    
    const select1 = screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento1Tipo' })
    const select2 = screen.getByLabelText(/Forma de Pagamento/i, { selector: '#pagamento2Tipo' })
    const input1 = screen.getByLabelText(/Valor/i, { selector: '#pagamento1Valor' })
    const input2 = screen.getByLabelText(/Valor/i, { selector: '#pagamento2Valor' })
    
    fireEvent.change(select1, { target: { value: 'PIX' } })
    fireEvent.change(select2, { target: { value: 'Dinheiro' } })
    fireEvent.change(input1, { target: { value: '50' } })
    fireEvent.change(input2, { target: { value: '100' } })
    
    await waitFor(() => {
      const confirmButton = screen.getByRole('button', { name: /Confirmar Pagamento Dividido/i })
      expect(confirmButton).not.toBeDisabled()
    })
    
    const confirmButton = screen.getByRole('button', { name: /Confirmar Pagamento Dividido/i })
    fireEvent.click(confirmButton)
    
    expect(onConfirm).toHaveBeenCalledWith({
      formaPagamentoDividido: true,
      pagamento1Tipo: 'PIX',
      pagamento1Valor: 50,
      pagamento2Tipo: 'Dinheiro',
      pagamento2Valor: 100
    })
  })

  it('should call onCancel when cancel button is clicked', () => {
    const onCancel = vi.fn()
    render(<PagamentoDividido {...defaultProps} onCancel={onCancel} />)
    
    const cancelButton = screen.getByRole('button', { name: /Cancelar/i })
    fireEvent.click(cancelButton)
    
    expect(onCancel).toHaveBeenCalled()
  })

  it('should display real-time calculation of total and difference', async () => {
    render(<PagamentoDividido {...defaultProps} />)
    
    const input1 = screen.getByLabelText(/Valor/i, { selector: '#pagamento1Valor' })
    const input2 = screen.getByLabelText(/Valor/i, { selector: '#pagamento2Valor' })
    
    fireEvent.change(input1, { target: { value: '30' } })
    fireEvent.change(input2, { target: { value: '40' } })
    
    await waitFor(() => {
      expect(screen.getByText(/Total configurado:/i)).toBeInTheDocument()
      expect(screen.getByText(/Faltam R\$\s*80,00/i)).toBeInTheDocument()
    })
  })

  it('should format currency values correctly', async () => {
    render(<PagamentoDividido {...defaultProps} />)
    
    const input1 = screen.getByLabelText(/Valor/i, { selector: '#pagamento1Valor' })
    
    fireEvent.change(input1, { target: { value: '50.50' } })
    
    await waitFor(() => {
      expect(screen.getAllByText(/R\$\s*50,50/i).length).toBeGreaterThan(0) // Aparece no preview e no resumo
    })
  })
})
