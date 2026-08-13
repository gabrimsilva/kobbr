import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import { supabase } from '@/lib/supabase'
import { toast } from 'react-hot-toast'
import { Save, ExternalLink, Info } from 'lucide-react'

export default function ConfiguracoesAnalyticsPage() {
  const [measurementId, setMeasurementId] = useState('')
  const [ativo, setAtivo] = useState(false)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    loadConfig()
  }, [])

  const loadConfig = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('configuracoes')
        .select('chave, valor')
        .in('chave', ['google_analytics_measurement_id', 'google_analytics_ativo'])

      if (error) throw error

      if (data) {
        const measurementIdConfig = data.find(c => c.chave === 'google_analytics_measurement_id')
        const ativoConfig = data.find(c => c.chave === 'google_analytics_ativo')

        setMeasurementId(measurementIdConfig?.valor || '')
        setAtivo(ativoConfig?.valor === 'true')
      }
    } catch (error) {
      console.error('Erro ao carregar configurações:', error)
      toast.error('Erro ao carregar configurações')
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async () => {
    try {
      setSaving(true)

      // Validar formato do Measurement ID
      if (measurementId && !measurementId.match(/^G-[A-Z0-9]+$/)) {
        toast.error('Formato inválido. Use o formato G-XXXXXXXXXX')
        return
      }

      // Atualizar Measurement ID
      const { error: error1 } = await supabase
        .from('configuracoes')
        .update({ valor: measurementId })
        .eq('chave', 'google_analytics_measurement_id')

      if (error1) throw error1

      // Atualizar status ativo
      const { error: error2 } = await supabase
        .from('configuracoes')
        .update({ valor: ativo ? 'true' : 'false' })
        .eq('chave', 'google_analytics_ativo')

      if (error2) throw error2

      toast.success('Configurações salvas com sucesso!')
      
      // Recarregar a página para aplicar as mudanças
      setTimeout(() => {
        window.location.reload()
      }, 1500)
    } catch (error) {
      console.error('Erro ao salvar configurações:', error)
      toast.error('Erro ao salvar configurações')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="w-8 h-8 border-2 border-red-600 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-600">Carregando...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Configurações do Google Analytics</h1>
          <p className="text-gray-600 mt-1">Configure a integração com o Google Analytics 4</p>
        </div>

        {/* Card de Configuração */}
        <Card>
          <CardHeader>
            <CardTitle>Google Analytics 4 (GA4)</CardTitle>
            <CardDescription>
              Configure o Measurement ID para enviar eventos para o Google Analytics
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Ativar/Desativar */}
            <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
              <div className="flex-1">
                <Label htmlFor="ativo" className="text-base font-medium">
                  Ativar Google Analytics
                </Label>
                <p className="text-sm text-gray-600 mt-1">
                  Enviar eventos para o Google Analytics 4
                </p>
              </div>
              <Switch
                id="ativo"
                checked={ativo}
                onChange={setAtivo}
              />
            </div>

            {/* Measurement ID */}
            <div className="space-y-2">
              <Label htmlFor="measurementId">
                Measurement ID
              </Label>
              <Input
                id="measurementId"
                placeholder="G-XXXXXXXXXX"
                value={measurementId}
                onChange={(e) => setMeasurementId(e.target.value)}
                disabled={!ativo}
              />
              <p className="text-sm text-gray-600">
                Encontre seu Measurement ID no Google Analytics em: Admin → Propriedade → Fluxos de dados
              </p>
            </div>

            {/* Informações */}
            <div className="bg-indigo-50 border border-indigo-200 rounded-lg p-4">
              <div className="flex gap-3">
                <Info className="h-5 w-5 text-indigo-600 flex-shrink-0 mt-0.5" />
                <div className="space-y-2 text-sm text-indigo-900">
                  <p className="font-medium">Como funciona:</p>
                  <ul className="list-disc list-inside space-y-1 ml-2">
                    <li>Os eventos são sempre salvos no banco de dados local</li>
                    <li>Se o GA4 estiver ativo, os eventos também são enviados para o Google Analytics</li>
                    <li>Você pode visualizar os dados na página de Analytics do sistema</li>
                    <li>Os dados do Google Analytics aparecem em tempo real no painel do GA4</li>
                  </ul>
                </div>
              </div>
            </div>

            {/* Link para o Google Analytics */}
            <div className="pt-4 border-t">
              <a
                href="https://analytics.google.com/"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 text-indigo-600 hover:text-indigo-700 text-sm font-medium"
              >
                <ExternalLink className="h-4 w-4" />
                Abrir Google Analytics
              </a>
            </div>

            {/* Botão Salvar */}
            <div className="flex justify-end pt-4">
              <Button
                onClick={handleSave}
                disabled={saving}
                className="bg-red-600 hover:bg-red-700"
              >
                {saving ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
                    Salvando...
                  </>
                ) : (
                  <>
                    <Save className="h-4 w-4 mr-2" />
                    Salvar Configurações
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Card de Eventos Rastreados */}
        <Card>
          <CardHeader>
            <CardTitle>Eventos Rastreados</CardTitle>
            <CardDescription>
              Lista de eventos que são enviados para o Google Analytics
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium text-sm">page_view</p>
                <p className="text-xs text-gray-600">Visualização de página</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium text-sm">view_item</p>
                <p className="text-xs text-gray-600">Visualização de produto</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium text-sm">add_to_cart</p>
                <p className="text-xs text-gray-600">Adicionar ao carrinho</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium text-sm">remove_from_cart</p>
                <p className="text-xs text-gray-600">Remover do carrinho</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium text-sm">view_cart</p>
                <p className="text-xs text-gray-600">Visualizar carrinho</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium text-sm">begin_checkout</p>
                <p className="text-xs text-gray-600">Iniciar checkout</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium text-sm">add_payment_info</p>
                <p className="text-xs text-gray-600">Adicionar pagamento</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium text-sm">add_shipping_info</p>
                <p className="text-xs text-gray-600">Adicionar entrega</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium text-sm">purchase</p>
                <p className="text-xs text-gray-600">Compra finalizada</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
