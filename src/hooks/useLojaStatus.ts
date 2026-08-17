import { useState, useEffect } from 'react'
import { configuracaoService } from "@/services"

interface DiaDaSemana {
  nome: string
  aberto: boolean
  abertura: string
  fechamento: string
}

const verificarSeEstaAberta = (horarios: DiaDaSemana[]): boolean => {
  const agora = new Date()
  const diaAtual = agora.getDay() // 0 = domingo, 1 = segunda, etc.
  const horaAtual = agora.getHours()
  const minutoAtual = agora.getMinutes()
  const tempoAtualEmMinutos = horaAtual * 60 + minutoAtual

  // Mapear dia da semana (JS usa 0=domingo, mas nosso array começa com segunda)
  const indiceDia = diaAtual === 0 ? 6 : diaAtual - 1 // Converte domingo (0) para índice 6, outros dias -1

  const diaConfig = horarios[indiceDia]
  
  if (!diaConfig || !diaConfig.aberto) {
    return false
  }

  // Converter horários para minutos
  const [horaAbertura, minutoAbertura] = diaConfig.abertura.split(':').map(Number)
  const [horaFechamento, minutoFechamento] = diaConfig.fechamento.split(':').map(Number)
  
  const aberturaEmMinutos = horaAbertura * 60 + minutoAbertura
  let fechamentoEmMinutos = horaFechamento * 60 + minutoFechamento

  // Se o fechamento é 00:00, considerar como 24:00 (1440 minutos)
  if (fechamentoEmMinutos === 0) {
    fechamentoEmMinutos = 24 * 60
  }

  // Verificar se está no horário de funcionamento
  if (fechamentoEmMinutos > aberturaEmMinutos) {
    // Horário normal (não cruza meia-noite)
    return tempoAtualEmMinutos >= aberturaEmMinutos && tempoAtualEmMinutos < fechamentoEmMinutos
  } else {
    // Horário que cruza meia-noite (ex: 22:00 às 02:00)
    return tempoAtualEmMinutos >= aberturaEmMinutos || tempoAtualEmMinutos < fechamentoEmMinutos
  }
}

export const useLojaStatus = () => {
  const [isAberta, setIsAberta] = useState(false)
  const [loading, setLoading] = useState(true)
  const [horarios, setHorarios] = useState<DiaDaSemana[]>([])

  useEffect(() => {
    let mounted = true
    
    const carregarHorarios = async () => {
      try {
        if (!mounted) return
        setLoading(true)
        
        const config = await configuracaoService.buscarPorChave('horario_funcionamento')
        
        if (!mounted) return
        
        let horariosData: DiaDaSemana[]
        
        if (config?.valor) {
          horariosData = JSON.parse(config.valor) as DiaDaSemana[]
        } else {
          // Horários padrão se não configurado
          horariosData = [
            { nome: 'Segunda-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
            { nome: 'Terça-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
            { nome: 'Quarta-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
            { nome: 'Quinta-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
            { nome: 'Sexta-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
            { nome: 'Sábado', aberto: true, abertura: '17:00', fechamento: '00:00' },
            { nome: 'Domingo', aberto: false, abertura: '17:00', fechamento: '23:00' }
          ]
        }
        
        setHorarios(horariosData)
        setIsAberta(verificarSeEstaAberta(horariosData))
        setLoading(false)
      } catch (error) {
        console.error('Erro ao carregar horários:', error)
        if (mounted) {
          setIsAberta(false)
          setLoading(false)
        }
      }
    }

    carregarHorarios()

    return () => {
      mounted = false
    }
  }, [])

  // Effect separado para o intervalo de atualização
  useEffect(() => {
    if (horarios.length === 0) return

    // Atualizar status a cada minuto
    const interval = setInterval(() => {
      setIsAberta(verificarSeEstaAberta(horarios))
    }, 60000) // 60 segundos

    return () => clearInterval(interval)
  }, [horarios])

  const recarregar = async () => {
    setLoading(true)
    try {
      const config = await configuracaoService.buscarPorChave('horario_funcionamento')
      
      let horariosData: DiaDaSemana[]
      
      if (config?.valor) {
        horariosData = JSON.parse(config.valor) as DiaDaSemana[]
      } else {
        horariosData = [
          { nome: 'Segunda-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
          { nome: 'Terça-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
          { nome: 'Quarta-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
          { nome: 'Quinta-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
          { nome: 'Sexta-feira', aberto: true, abertura: '18:00', fechamento: '23:00' },
          { nome: 'Sábado', aberto: true, abertura: '17:00', fechamento: '00:00' },
          { nome: 'Domingo', aberto: false, abertura: '17:00', fechamento: '23:00' }
        ]
      }
      
      setHorarios(horariosData)
      setIsAberta(verificarSeEstaAberta(horariosData))
    } catch (error) {
      console.error('Erro ao recarregar horários:', error)
      setIsAberta(false)
    } finally {
      setLoading(false)
    }
  }

  return { isAberta, loading, horarios, recarregar }
}