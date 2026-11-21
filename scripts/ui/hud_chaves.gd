class_name HudChaves
extends CanvasLayer
## HUD do hub (K4): 4 slots de chave (ícone + ano) e o medidor de cor.
## Acessibilidade (GDD 6): cada estado tem texto e forma, nunca só cor.
##   - slot vazio: silhueta escura da chave + "1904" + "--"
##   - slot cheio: chave colorida + "1904" + "OK"
##   - medidor: "Cor: 25%" + barra + "Chaves: 1/4"
## API: atualizar(), await piscar_slot(fase). Escuta GameState.chave_recebida.
## O medidor muda com GameState.encaixar_chave(), que não tem sinal:
## quem encaixar chama atualizar() (piscar_slot() já chama).

const ANOS: Array[String] = ["1904", "1973", "1979", "1982"]
const ICONES: Array[Texture2D] = [
	preload("res://assets/sprites/hub/chaves/chave_saude.png"),     # 1904
	preload("res://assets/sprites/hub/chaves/chave_cultura.png"),   # 1973
	preload("res://assets/sprites/hub/chaves/chave_ambiente.png"),  # 1979
	preload("res://assets/sprites/hub/chaves/chave_educacao.png"),  # 1982
]
const TAMANHO_ICONE: Vector2 = Vector2(64, 64)  # 16x16 em escala 4, igual à câmera
const COR_VAZIO: Color = Color(0.05, 0.05, 0.08, 0.75)  # silhueta escura (forma da chave, sem cor)
const COR_BORDA: Color = Color(0.33, 0.38, 0.5)
const COR_BORDA_DESTAQUE: Color = Color(0.95, 0.75, 0.3)  # dourado do tema_ui
const COR_BARRA: Color = Color(0.95, 0.75, 0.3)

@onready var linha_slots: HBoxContainer = %Slots
@onready var rotulo_cor: Label = %RotuloCor
@onready var barra_cor: ProgressBar = %BarraCor
@onready var rotulo_chaves: Label = %RotuloChaves

var _slots: Array[PanelContainer] = []
var _icones: Array[TextureRect] = []
var _estados: Array[Label] = []
var _tween_barra: Tween


func _ready() -> void:
	_montar_slots()
	barra_cor.min_value = 0
	barra_cor.max_value = 100
	barra_cor.show_percentage = false
	_estilizar_barra()
	GameState.chave_recebida.connect(_on_chave_recebida)
	atualizar(false)


## Lê o GameState e redesenha slots e medidor. animar=false pula o tween da barra.
func atualizar(animar: bool = true) -> void:
	for fase in GameState.TOTAL_FASES:
		var cheia := GameState.tem_chave(fase)
		_icones[fase].modulate = Color.WHITE if cheia else COR_VAZIO
		_estados[fase].text = "OK" if cheia else "--"
		_slots[fase].tooltip_text = "%s: %s" % [ANOS[fase], "chave obtida" if cheia else "sem chave"]
	var pct := porcentagem_cor()
	rotulo_cor.text = "Cor: %d%%" % pct
	rotulo_chaves.text = "Chaves: %d/%d" % [GameState.total_chaves(), GameState.TOTAL_FASES]
	if _tween_barra != null and _tween_barra.is_valid():
		_tween_barra.kill()
	if animar and is_inside_tree():
		_tween_barra = create_tween()
		_tween_barra.tween_property(barra_cor, "value", float(pct), 0.4)
	else:
		barra_cor.value = pct


## Média de GameState.cor_zona das 4 fases, de 0 a 100.
func porcentagem_cor() -> int:
	var soma := 0.0
	for fase in GameState.TOTAL_FASES:
		soma += GameState.cor_zona(fase)
	return roundi(soma / GameState.TOTAL_FASES * 100.0)


## Pisca o slot da fase (borda dourada + pulo de escala). Usar com await.
func piscar_slot(fase: int) -> void:
	if fase < 0 or fase >= _slots.size():
		return
	atualizar()
	var slot := _slots[fase]
	slot.pivot_offset = slot.size / 2.0
	_definir_borda(slot, COR_BORDA_DESTAQUE)
	var tw := create_tween()
	for i in 3:
		tw.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(slot, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	_definir_borda(slot, COR_BORDA)


func _on_chave_recebida(_fase: int) -> void:
	atualizar()


func _montar_slots() -> void:
	for fase in GameState.TOTAL_FASES:
		var slot := PanelContainer.new()
		slot.name = "Slot%d" % fase
		slot.add_theme_stylebox_override("panel", _caixa(COR_BORDA))
		var coluna := VBoxContainer.new()
		coluna.alignment = BoxContainer.ALIGNMENT_CENTER
		coluna.add_theme_constant_override("separation", 2)
		slot.add_child(coluna)

		var icone := TextureRect.new()
		icone.texture = ICONES[fase]
		icone.custom_minimum_size = TAMANHO_ICONE
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		coluna.add_child(icone)

		var ano := Label.new()
		ano.text = ANOS[fase]
		ano.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ano.add_theme_font_size_override("font_size", 24)
		coluna.add_child(ano)

		var estado := Label.new()
		estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		estado.add_theme_font_size_override("font_size", 20)
		coluna.add_child(estado)

		linha_slots.add_child(slot)
		_slots.append(slot)
		_icones.append(icone)
		_estados.append(estado)


func _caixa(borda: Color) -> StyleBoxFlat:
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = Color(0.11, 0.13, 0.19, 0.85)
	caixa.set_border_width_all(3)
	caixa.border_color = borda
	caixa.set_content_margin_all(8)
	return caixa


func _definir_borda(slot: PanelContainer, cor: Color) -> void:
	var caixa := slot.get_theme_stylebox("panel") as StyleBoxFlat
	caixa.border_color = cor


func _estilizar_barra() -> void:
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0, 0, 0, 0.5)
	fundo.set_border_width_all(2)
	fundo.border_color = COR_BORDA
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = COR_BARRA
	barra_cor.add_theme_stylebox_override("background", fundo)
	barra_cor.add_theme_stylebox_override("fill", cheio)
