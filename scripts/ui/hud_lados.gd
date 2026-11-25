class_name HudLados
extends CanvasLayer
## [L2] Duas barras no canto de baixo à esquerda: confiança da comunidade e do empreendimento (1979).
## Escuta DialogoManager.confianca_lado_mudou e lê GameState.confianca_lado ao entrar.

const LADOS: Array[String] = ["comunidade", "empreendimento"]
const NOMES: Dictionary = {"comunidade": "Comunidade", "empreendimento": "Empreendimento"}
const CORES: Dictionary = {"comunidade": Color(0.35, 0.75, 0.35), "empreendimento": Color(0.95, 0.75, 0.2)}

var _barras: Dictionary = {}
var _numeros: Dictionary = {}


func _ready() -> void:
	layer = 20
	_montar()
	for lado in LADOS:
		definir(lado, int(GameState.confianca_lado.get(lado, 0)))
	DialogoManager.confianca_lado_mudou.connect(definir)


func definir(lado: String, valor: int) -> void:
	if not _barras.has(lado):
		return
	var tw := create_tween()
	tw.tween_property(_barras[lado], "value", float(clampi(valor, 0, 100)), 0.3)
	_numeros[lado].text = str(valor)


func _montar() -> void:
	var painel := PanelContainer.new()
	painel.anchor_top = 1.0
	painel.anchor_bottom = 1.0
	painel.offset_left = 24
	painel.offset_top = -150
	painel.offset_bottom = -24
	painel.offset_right = 560
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.12, 0.08, 0.75)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(14)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	painel.add_child(coluna)
	for lado in LADOS:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 12)
		var nome := Label.new()
		nome.text = NOMES[lado]
		nome.custom_minimum_size.x = 210
		nome.add_theme_font_size_override("font_size", 26)
		linha.add_child(nome)
		var barra := ProgressBar.new()
		barra.max_value = 100
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(220, 24)
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var cheio := StyleBoxFlat.new()
		cheio.bg_color = CORES[lado]
		barra.add_theme_stylebox_override("fill", cheio)
		linha.add_child(barra)
		var numero := Label.new()
		numero.text = "0"
		numero.add_theme_font_size_override("font_size", 26)
		linha.add_child(numero)
		coluna.add_child(linha)
		_barras[lado] = barra
		_numeros[lado] = numero
