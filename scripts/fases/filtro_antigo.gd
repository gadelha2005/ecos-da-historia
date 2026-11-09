@tool
class_name FiltroAntigo
extends CanvasLayer
## [I7] Filtro de foto antiga (sépia + grão + vinheta) da fase 1904.
## Instancie scenes/fases/filtro_antigo.tscn na fase. Fica na camada 50:
## acima do mundo e abaixo da UI (HUD 70, Mensagem 80, pausa 90), que continua nítida.

@export_range(0.0, 1.0) var intensidade: float = 0.85:
	set(valor):
		intensidade = valor
		_aplicar("intensidade", valor)
@export_range(0.0, 0.5) var grao: float = 0.08:
	set(valor):
		grao = valor
		_aplicar("grao", valor)
@export_range(0.0, 1.0) var vinheta: float = 0.45:
	set(valor):
		vinheta = valor
		_aplicar("vinheta", valor)
@export var ativo: bool = true:
	set(valor):
		ativo = valor
		visible = valor


func _ready() -> void:
	_aplicar("intensidade", intensidade)
	_aplicar("grao", grao)
	_aplicar("vinheta", vinheta)
	visible = ativo


func _aplicar(parametro: String, valor: float) -> void:
	var efeito: ColorRect = get_node_or_null("Efeito")
	if efeito and efeito.material is ShaderMaterial:
		(efeito.material as ShaderMaterial).set_shader_parameter(parametro, valor)
