class_name FiltroCor
extends CanvasLayer
## [K1] Filtro de cor por zona do hub (camada 50: acima do mundo, abaixo da UI).
## Cada uma das 4 zonas (0 = 1904 Saúde ... 3 = 1982 Educação) tem um retângulo no mundo
## e um valor t de 0 (cinza) a 1 (colorida). Como a câmera anda, os retângulos são
## convertidos de mundo para tela a cada frame.

## Ao entrar na cena, pega a cor de cada zona de GameState.cor_zona (1 se a chave já foi encaixada).
@export var ler_game_state: bool = true

var _zonas_mundo: Array[Rect2] = [Rect2(), Rect2(), Rect2(), Rect2()]
var _t: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _t_geral: float = 0.0
var _tweens: Array[Tween] = [null, null, null, null]

@onready var efeito: ColorRect = $Efeito


func _ready() -> void:
	if ler_game_state:
		for fase in 4:
			_t[fase] = GameState.cor_zona(fase)
	_enviar_t()
	definir_t_geral(_t_geral)


func _process(_delta: float) -> void:
	_enviar_zonas()


## Retângulo da zona `fase` em coordenadas do mundo (ex.: o Rect2 de um Zona_* do hub).
func definir_zona(fase: int, rect_mundo: Rect2) -> void:
	_zonas_mundo[fase] = rect_mundo
	_enviar_zonas()


## Define a cor da zona na hora: 0 = cinza, 1 = colorida.
func definir_t(fase: int, valor: float) -> void:
	if _tweens[fase]:
		_tweens[fase].kill()
	_t[fase] = clampf(valor, 0.0, 1.0)
	_enviar_t()


func valor_t(fase: int) -> float:
	return _t[fase]


## Anima a zona de cinza para colorida. Use com await para esperar o fim.
func animar_zona(fase: int, duracao: float = 1.5) -> void:
	if _tweens[fase]:
		_tweens[fase].kill()
	var aplicar := func(v: float) -> void:
		_t[fase] = v
		_enviar_t()
	var tw := create_tween()
	_tweens[fase] = tw
	tw.tween_method(aplicar, _t[fase], 1.0, duracao).set_trans(Tween.TRANS_SINE)
	await tw.finished


## Cor de tudo que fica fora das 4 zonas (0 = cinza, 1 = colorido).
func definir_t_geral(valor: float) -> void:
	_t_geral = clampf(valor, 0.0, 1.0)
	_material().set_shader_parameter("t_geral", _t_geral)


func valor_t_geral() -> float:
	return _t_geral


func _material() -> ShaderMaterial:
	return efeito.material as ShaderMaterial


func _enviar_t() -> void:
	_material().set_shader_parameter("t_zonas", PackedFloat32Array(_t))


func _enviar_zonas() -> void:
	var tela := get_viewport().get_visible_rect().size
	var xf := get_viewport().get_canvas_transform()
	var zonas: Array[Vector4] = []
	for r in _zonas_mundo:
		if r.size == Vector2.ZERO:
			zonas.append(Vector4.ZERO)
			continue
		var a := xf * r.position
		var b := xf * r.end
		var ini := a.min(b)
		var fim := a.max(b)
		zonas.append(Vector4(ini.x, ini.y, fim.x - ini.x, fim.y - ini.y))
	_material().set_shader_parameter("zonas", zonas)
	_material().set_shader_parameter("tamanho_tela", tela)
