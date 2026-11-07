class_name HudDialogo
extends CanvasLayer

signal tensao_estourou

@onready var barra_tensao: ProgressBar = %BarraTensao
@onready var barra_confianca: ProgressBar = %BarraConfianca
@onready var vinheta: ColorRect = %Vinheta

var _estourou: bool = false
var _vinheta_atual: float = 0.0
var _tween_tensao: Tween
var _tween_confianca: Tween
var _tween_vinheta: Tween


func _ready() -> void:
	for barra in [barra_tensao, barra_confianca]:
		barra.min_value = 0
		barra.max_value = 100
		barra.value = 0
		barra.show_percentage = false
	_estilizar(barra_tensao, Color(0.85, 0.2, 0.15))
	_estilizar(barra_confianca, Color(0.2, 0.7, 0.35))
	_aplicar_vinheta(0.0)


func definir_tensao(valor: int) -> void:
	var v := clampi(valor, 0, 100)
	_tween_tensao = _animar_barra(barra_tensao, v, _tween_tensao)
	_animar_vinheta(v / 100.0)
	if v >= 100 and not _estourou:
		_estourou = true
		tensao_estourou.emit()
	elif v < 100:
		_estourou = false


func definir_confianca(valor: int) -> void:
	var v := clampi(valor, 0, 100)
	_tween_confianca = _animar_barra(barra_confianca, v, _tween_confianca)


func _animar_barra(barra: ProgressBar, alvo: int, antigo: Tween) -> Tween:
	if antigo != null and antigo.is_valid():
		antigo.kill()
	var tw := create_tween()
	tw.tween_property(barra, "value", float(alvo), 0.3)
	return tw


func _animar_vinheta(alvo: float) -> void:
	if _tween_vinheta != null and _tween_vinheta.is_valid():
		_tween_vinheta.kill()
	_tween_vinheta = create_tween()
	_tween_vinheta.tween_method(_aplicar_vinheta, _vinheta_atual, alvo, 0.4)


func _aplicar_vinheta(valor: float) -> void:
	_vinheta_atual = valor
	var material := vinheta.material as ShaderMaterial
	material.set_shader_parameter("intensidade", valor)


func _estilizar(barra: ProgressBar, cor: Color) -> void:
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0, 0, 0, 0.5)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = cor
	barra.add_theme_stylebox_override("background", fundo)
	barra.add_theme_stylebox_override("fill", cheio)
