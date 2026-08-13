import { Button } from "@/components/ui/button"
import { FileText } from "lucide-react"
import jsPDF from "jspdf"
import autoTable from "jspdf-autotable"
import { format } from "date-fns"
import { ptBR } from "date-fns/locale"
import { useState, useEffect } from "react"
import { supabase, tenantId } from "@/services"

interface MetricasResumo {
  faturamentoTotal: number
  quantidadeVendas: number
  ticketMedio: number
  quantidadeProdutosVendidos: number
  produtosMaisVendidos: { nome: string; quantidade: number; total: number }[]
  vendasPorDia: { data: string; total: number; quantidade: number }[]
  vendasPorCategoria: { categoria: string; total: number; quantidade: number }[]
  faturamentoPorFormaPagamento: { forma: string; total: number; quantidade: number }[]
}

interface RelatorioMetricasProps {
  metricas: MetricasResumo | null
  dataInicio: Date
  dataFim: Date
  periodo: string
}

export default function RelatorioMetricas({ metricas, dataInicio, dataFim, periodo }: RelatorioMetricasProps) {
  const [nomeEstabelecimento, setNomeEstabelecimento] = useState('Estabelecimento')

  useEffect(() => {
    carregarNomeEstabelecimento()
  }, [])

  const carregarNomeEstabelecimento = async () => {
    try {
      const estabelecimentoId = tenantId()
      if (!estabelecimentoId) return

      const { data, error } = await supabase
        .from('estabelecimentos')
        .select('nome')
        .eq('id', estabelecimentoId)
        .single()

      if (!error && data?.nome) {
        setNomeEstabelecimento(data.nome)
      }
    } catch (error) {
      console.error('Erro ao carregar nome do estabelecimento:', error)
    }
  }
  
  const formatarMoeda = (valor: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(valor)
  }

  const gerarPDF = () => {
    if (!metricas) return

    const doc = new jsPDF()
    let yPos = 20

    // Cabeçalho
    doc.setFontSize(18)
    doc.setFont("helvetica", "bold")
    doc.text(`Relatório de Vendas - ${nomeEstabelecimento}`, 105, yPos, { align: "center" })
    
    yPos += 10
    doc.setFontSize(10)
    doc.setFont("helvetica", "normal")
    const periodoTexto = periodo === "0" ? "Hoje" : 
                         periodo === "all" ? "Todo o período" :
                         `Últimos ${periodo} dias`
    doc.text(`Período: ${periodoTexto}`, 105, yPos, { align: "center" })
    doc.text(`${format(dataInicio, "dd/MM/yyyy")} até ${format(dataFim, "dd/MM/yyyy")}`, 105, yPos + 5, { align: "center" })
    doc.text(`Gerado em: ${format(new Date(), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR })}`, 105, yPos + 10, { align: "center" })
    
    yPos += 20

    // Resumo Geral
    doc.setFontSize(14)
    doc.setFont("helvetica", "bold")
    doc.text("Indicadores Principais", 14, yPos)
    yPos += 8

    autoTable(doc, {
      startY: yPos,
      head: [['Métrica', 'Valor']],
      body: [
        ['Faturamento Total', formatarMoeda(metricas.faturamentoTotal)],
        ['Quantidade de Vendas', metricas.quantidadeVendas.toString()],
        ['Ticket Médio', formatarMoeda(metricas.ticketMedio)],
        ['Produtos Vendidos (unidades)', metricas.quantidadeProdutosVendidos.toString()],
      ],
      theme: 'grid',
      headStyles: { fillColor: [0, 136, 254] },
      margin: { left: 14 },
    })

    yPos = (doc as any).lastAutoTable.finalY + 10

    // Nova página - Produtos Vendidos (TODOS)
    doc.addPage()
    yPos = 20

    doc.setFontSize(14)
    doc.setFont("helvetica", "bold")
    doc.text("Produtos Vendidos", 14, yPos)
    yPos += 8

    autoTable(doc, {
      startY: yPos,
      head: [['Produto', 'Quantidade', 'Total']],
      body: metricas.produtosMaisVendidos.map(p => [
        p.nome,
        p.quantidade.toString(),
        formatarMoeda(p.total)
      ]),
      theme: 'striped',
      headStyles: { fillColor: [136, 132, 216] },
      margin: { left: 14, right: 14 },
    })

    yPos = (doc as any).lastAutoTable.finalY + 10

    // Vendas por Categoria
    if (yPos > 250) {
      doc.addPage()
      yPos = 20
    }

    doc.setFontSize(14)
    doc.setFont("helvetica", "bold")
    doc.text("Faturamento por Categoria", 14, yPos)
    yPos += 8

    autoTable(doc, {
      startY: yPos,
      head: [['Categoria', 'Quantidade', 'Total']],
      body: metricas.vendasPorCategoria.map(c => [
        c.categoria,
        c.quantidade.toString(),
        formatarMoeda(c.total)
      ]),
      theme: 'striped',
      headStyles: { fillColor: [130, 202, 157] },
      margin: { left: 14, right: 14 },
    })

    // Nova página - Formas de Pagamento
    doc.addPage()
    yPos = 20

    doc.setFontSize(14)
    doc.setFont("helvetica", "bold")
    doc.text("Faturamento por Forma de Pagamento", 14, yPos)
    yPos += 8

    autoTable(doc, {
      startY: yPos,
      head: [['Forma de Pagamento', 'Quantidade', 'Total']],
      body: metricas.faturamentoPorFormaPagamento.map(f => [
        f.forma,
        f.quantidade.toString(),
        formatarMoeda(f.total)
      ]),
      theme: 'grid',
      headStyles: { fillColor: [0, 136, 254] },
      margin: { left: 14, right: 14 },
    })

    yPos = (doc as any).lastAutoTable.finalY + 10

    // Vendas por Dia
    if (yPos > 200) {
      doc.addPage()
      yPos = 20
    }

    doc.setFontSize(14)
    doc.setFont("helvetica", "bold")
    doc.text("Faturamento Diário", 14, yPos)
    yPos += 8

    autoTable(doc, {
      startY: yPos,
      head: [['Data', 'Quantidade', 'Total']],
      body: metricas.vendasPorDia.map(v => [
        v.data,
        v.quantidade.toString(),
        formatarMoeda(v.total)
      ]),
      theme: 'striped',
      headStyles: { fillColor: [255, 187, 40] },
      margin: { left: 14, right: 14 },
    })

    // Salvar PDF
    const nomeArquivo = `relatorio-vendas-${format(new Date(), "yyyy-MM-dd-HHmm")}.pdf`
    doc.save(nomeArquivo)
  }

  return (
    <Button 
      onClick={gerarPDF} 
      variant="outline"
      disabled={!metricas}
      className="gap-2"
    >
      <FileText className="h-4 w-4" />
      Gerar Relatório PDF
    </Button>
  )
}
