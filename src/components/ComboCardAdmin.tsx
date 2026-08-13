import { Button } from "@/components/ui/button"
import ConfirmDeleteDialog from "@/components/ConfirmDeleteDialog"
import { Package, Edit, Trash2 } from "lucide-react"

interface Combo {
  id: string
  nome: string
  descricao: string
  preco: number
  urlImagem: string
  categoria: string
  precoPromocional?: number
  [key: string]: any // Permite propriedades adicionais
}

interface ComboDetalhes {
  preco_original: number
  desconto: number
}

interface ComboCardProps {
  combo: Combo
  comboDetalhes?: ComboDetalhes
  onEditar: (combo: any) => void
  onExcluir: (combo: any) => void
}

const getCategoriaColor = (categoria: string) => {
  const colors = {
    lanches: 'bg-orange-100 text-orange-800',
    bebidas: 'bg-indigo-100 text-indigo-800',
    doces: 'bg-purple-100 text-purple-800',
    salgados: 'bg-yellow-100 text-yellow-800',
    refeicoes: 'bg-green-100 text-green-800',
    corpo: 'bg-green-100 text-green-800',
    lanche: 'bg-green-100 text-green-800',
    bebida: 'bg-indigo-100 text-indigo-800',
    combo: 'bg-purple-100 text-purple-800'
  }
  return colors[categoria as keyof typeof colors] || 'bg-gray-100 text-gray-800'
}

export default function ComboCard({ combo, comboDetalhes, onEditar, onExcluir }: ComboCardProps) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 overflow-hidden hover:shadow-md transition-shadow">
      {/* Layout Desktop */}
      <div className="hidden md:flex p-4 gap-4 items-center">
        {/* Imagem do combo */}
        <div className="relative w-20 h-20 flex-shrink-0">
          {combo.urlImagem ? (
            <img 
              src={combo.urlImagem} 
              alt={combo.nome}
              className="w-full h-full object-cover rounded-lg"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center bg-gray-100 rounded-lg">
              <Package className="h-8 w-8 text-gray-400" />
            </div>
          )}
        </div>

        {/* Conteúdo do card */}
        <div className="flex-1 min-w-0">
          {/* Cabeçalho com nome, badge e botões */}
          <div className="flex items-start justify-between mb-1">
            <div className="flex items-center gap-2 flex-1 min-w-0">
              <h3 className="font-semibold text-base truncate" title={combo.nome}>
                {combo.nome}
              </h3>
              <div className="flex gap-1 flex-shrink-0">
                <span className={`text-xs font-medium px-2 py-1 rounded ${getCategoriaColor('combo')}`}>
                  Combo
                </span>
                {combo.precoPromocional && combo.precoPromocional > 0 && (
                  <span className="text-xs font-medium px-2 py-1 rounded bg-yellow-100 text-yellow-800">
                    Promoção
                  </span>
                )}
              </div>
            </div>
            
            {/* Botões de ação Desktop */}
            <div className="flex space-x-1 flex-shrink-0 ml-2">
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => onEditar(combo)}
                className="h-8 w-8 p-0"
              >
                <Edit className="h-3 w-3" />
              </Button>
              <ConfirmDeleteDialog
                trigger={
                  <Button 
                    variant="outline" 
                    size="sm"
                    className="h-8 w-8 p-0"
                  >
                    <Trash2 className="h-3 w-3" />
                  </Button>
                }
                title="Confirmar Exclusão"
                description={`Tem certeza que deseja excluir o combo "${combo.nome}"? Esta ação não pode ser desfeita.`}
                onConfirm={() => onExcluir(combo)}
              />
            </div>
          </div>

          {/* Descrição */}
          <p className="text-sm text-muted-foreground line-clamp-2 mb-1" title={combo.descricao}>
            {combo.descricao}
          </p>

          {/* Preço e informações do combo */}
          <div className="flex items-center gap-3">
            {combo.precoPromocional && combo.precoPromocional > 0 ? (
              <>
                <span className="text-lg font-bold text-[color:var(--price-color)]">
                  R$ {combo.precoPromocional.toFixed(2).replace('.', ',')}
                </span>
                <span className="text-sm text-gray-500 line-through">
                  R$ {(combo.preco || 0).toFixed(2).replace('.', ',')}
                </span>
              </>
            ) : (
              <span className="text-lg font-bold text-[color:var(--price-color)]">
                R$ {(combo.preco || 0).toFixed(2).replace('.', ',')}
              </span>
            )}
            
            {comboDetalhes && (
              <div className="flex items-center gap-2 text-xs">
                <span className="text-gray-500 line-through">
                  De R$ {(comboDetalhes.preco_original || 0).toFixed(2).replace('.', ',')}
                </span>
                <span className="text-orange-600 font-semibold">
                  -{(comboDetalhes.desconto || 0).toFixed(0)}%
                </span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Layout Mobile */}
      <div className="md:hidden">
        {/* Imagem do combo */}
        <div className="relative h-32 bg-gray-100">
          {combo.urlImagem ? (
            <img 
              src={combo.urlImagem} 
              alt={combo.nome}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center bg-gray-200">
              <Package className="h-8 w-8 text-gray-400" />
            </div>
          )}
          
          {/* Badge da categoria */}
          <div className="absolute top-2 left-2 flex gap-1">
            <span className={`text-xs font-medium px-2 py-1 rounded ${getCategoriaColor('combo')}`}>
              Combo
            </span>
            {combo.precoPromocional && combo.precoPromocional > 0 && (
              <span className="text-xs font-medium px-2 py-1 rounded bg-yellow-100 text-yellow-800">
                Promoção
              </span>
            )}
          </div>
        </div>

        {/* Conteúdo do card Mobile */}
        <div className="p-4">
          {/* Título */}
          <div className="space-y-2">
            <h3 className="font-semibold text-base line-clamp-1" title={combo.nome}>
              {combo.nome}
            </h3>
            
            {/* Descrição */}
            <p className="text-sm text-muted-foreground line-clamp-2" title={combo.descricao}>
              {combo.descricao}
            </p>
          </div>

          {/* Preço */}
          <div className="mt-3">
            {combo.precoPromocional && combo.precoPromocional > 0 ? (
              <div className="flex items-center gap-2">
                <span className="text-lg font-bold text-[color:var(--price-color)]">
                  R$ {combo.precoPromocional.toFixed(2).replace('.', ',')}
                </span>
                <span className="text-sm text-gray-500 line-through">
                  R$ {(combo.preco || 0).toFixed(2).replace('.', ',')}
                </span>
              </div>
            ) : (
              <span className="text-lg font-bold text-[color:var(--price-color)]">
                R$ {(combo.preco || 0).toFixed(2).replace('.', ',')}
              </span>
            )}
          </div>

          {/* Informações do combo */}
          {comboDetalhes && (
            <div className="mt-2 text-xs space-y-1 bg-orange-50 p-2 rounded">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Original:</span>
                <span className="line-through text-red-600">
                  R$ {(comboDetalhes.preco_original || 0).toFixed(2).replace('.', ',')}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Desconto:</span>
                <span className="text-orange-600 font-semibold">
                  {(comboDetalhes.desconto || 0).toFixed(1)}%
                </span>
              </div>
            </div>
          )}

          {/* Botões Mobile */}
          <div className="mt-4 space-y-2">
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => onEditar(combo)}
              className="w-full"
            >
              <Edit className="h-4 w-4 mr-2" />
              Editar Combo
            </Button>
            <ConfirmDeleteDialog
              trigger={
                <Button 
                  variant="outline" 
                  size="sm"
                  className="w-full text-red-600 hover:text-red-700 hover:bg-red-50"
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  Remover Combo
                </Button>
              }
              title="Confirmar Exclusão"
              description={`Tem certeza que deseja excluir o combo "${combo.nome}"? Esta ação não pode ser desfeita.`}
              onConfirm={() => onExcluir(combo)}
            />
          </div>
        </div>
      </div>
    </div>
  )
}
