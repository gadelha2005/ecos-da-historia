class_name MesaAcordo
extends CanvasLayer
## [L6] Mesa de acordo de 1979 (N3.6), sob a árvore grande.
## O jogador escolhe de 2 a 4 propostas. Cada proposta mexe na confiança dos dois lados
## (GameState.confianca_lado, que veio das conversas) e algumas esquentam a mesa (tensão).
## O acordo vale só se OS DOIS lados aceitarem: c = min(comunidade, empreendimento) (maximin),
## e c precisa ficar >= confianca_minima com a tensão abaixo de 100.
## Regras em data/fases/acordo_1979.json. Uso:
##   var mesa: MesaAcordo = preload("res://scenes/ui/mesa_acordo.tscn").instantiate()
##   add_child(mesa)
##   var r: Dictionary = await mesa.montar()   # {"aprovado", "c", "motivo", "dica", "finais", "tensao"}

signal confirmada(resultado: Dictionary)

const CAMINHO_REGRAS: String = "res://data/fases/acordo_1979.json"
const LADOS: Array[String] = ["comunidade", "empreendimento"]
const NOMES_LADOS: Dictionary = {"comunidade": "Comunidade", "empreendimento": "Empreendimento"}

var regras: Dictionary = {}
## ids das propostas marcadas, na ordem em que foram marcadas.
var escolhidas: Array[String] = []

var _caixas: Dictionary = {}
var _barras: Dictionary = {}
var _rotulos_lado: Dictionary = {}
var _barra_tensao: ProgressBar
var _rotulo_tensao: Label
var _rotulo_c: Label
var _rotulo_aviso: Label
var _botao_confirmar: Button


static func carregar_regras() -> Dictionary:
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_REGRAS))
	if typeof(dados) != TYPE_DICTIONARY:
		push_error("Regras inválidas em " + CAMINHO_REGRAS)
		return {}
	return dados


static func proposta(id: String, r: Dictionary) -> Dictionary:
	for p in r.get("propostas", []):
		if p["id"] == id:
			return p
	return {}


## Avalia um acordo. confianca: lado -> int (das conversas). Devolve
## {"aprovado", "c", "motivo", "finais", "tensao"}.
static func avaliar(ids: Array, confianca: Dictionary, tensao_base: int, r: Dictionary) -> Dictionary:
	var finais := {}
	for lado in LADOS:
		finais[lado] = int(confianca.get(lado, 0))
	var tensao := tensao_base
	for id in ids:
		var p := proposta(id, r)
		for lado in LADOS:
			finais[lado] += int(p.get(lado, 0))
		tensao += int(p.get("tensao", 0))
	for lado in LADOS:
		finais[lado] = clampi(finais[lado], 0, 100)
	tensao = clampi(tensao, 0, 100)
	var c: int = mini(finais["comunidade"], finais["empreendimento"])
	var motivo := ""
	if ids.size() < int(r.get("min_propostas", 2)):
		motivo = "poucas"
	elif tensao >= 100:
		motivo = "tensao"
	elif c < int(r.get("confianca_minima", 70)):
		motivo = "comunidade" if finais["comunidade"] <= finais["empreendimento"] else "empreendimento"
	return {"aprovado": motivo == "", "c": c, "motivo": motivo, "finais": finais, "tensao": tensao}


func _ready() -> void:
	layer = 80
	regras = carregar_regras()
	_montar_tela()
	_atualizar()


func montar() -> Dictionary:
	_botao_confirmar.grab_focus()
	var resultado: Dictionary = await confirmada
	return resultado


## Marca ou desmarca uma proposta (usado pelos botões e pelos testes).
func alternar(id: String) -> void:
	if id in escolhidas:
		escolhidas.erase(id)
	elif escolhidas.size() < int(regras.get("max_propostas", 4)):
		escolhidas.append(id)
	_atualizar()


func confirmar() -> void:
	var r := avaliar(escolhidas, GameState.confianca_lado, GameState.tensao_fase, regras)
	if r["motivo"] == "poucas":
		_rotulo_aviso.text = str(regras.get("dicas", {}).get("poucas", ""))
		return
	r["dica"] = str(regras.get("dicas", {}).get(r["motivo"], ""))
	GameState.pontuacao[GameState.FASE_1979] = r["c"]
	confirmada.emit(r)
	queue_free()


func _atualizar() -> void:
	var r := avaliar(escolhidas, GameState.confianca_lado, GameState.tensao_fase, regras)
	var maximo := int(regras.get("max_propostas", 4))
	for id in _caixas:
		var caixa: CheckButton = _caixas[id]
		caixa.set_pressed_no_signal(id in escolhidas)
		caixa.disabled = not (id in escolhidas) and escolhidas.size() >= maximo
	for lado in LADOS:
		var v: int = r["finais"][lado]
		_barras[lado].value = v
		_barras[lado].modulate = _cor(v)
		_rotulos_lado[lado].text = "%s %d" % [_rosto(v), v]
	_barra_tensao.value = r["tensao"]
	_rotulo_tensao.text = "Tensão na mesa: %d" % r["tensao"]
	_rotulo_c.text = "Propostas: %d de %d · o lado menos satisfeito está em %d (precisa de %d)" % [
		escolhidas.size(), maximo, r["c"], int(regras.get("confianca_minima", 70))]
	_rotulo_aviso.text = ""


func _rosto(valor: int) -> String:
	if valor >= 70:
		return ":)"
	if valor >= 40:
		return ":|"
	return ":("


func _cor(valor: int) -> Color:
	if valor >= 70:
		return Color(0.45, 0.85, 0.45)
	if valor >= 40:
		return Color(0.95, 0.8, 0.3)
	return Color(0.95, 0.35, 0.35)


# --- Tela montada por código (tons de mata: verde, madeira e papel) ---

func _montar_tela() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.7)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists("res://scenes/ui/tema_ui.tres"):
		centro.theme = load("res://scenes/ui/tema_ui.tres")
	add_child(centro)

	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(1300, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.92, 0.89, 0.78)
	estilo.border_color = Color(0.2, 0.5, 0.22)
	estilo.set_border_width_all(8)
	estilo.set_content_margin_all(36)
	painel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(painel)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)

	coluna.add_child(_rotulo("Mesa de acordo · 1979", 46, Color(0.15, 0.42, 0.18)))
	coluna.add_child(_rotulo("Escolha de 2 a 4 propostas. O acordo só vale se os dois lados aceitarem.", 26, Color(0.2, 0.2, 0.2)))

	for p in regras.get("propostas", []):
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 16)
		var caixa := CheckButton.new()
		caixa.text = str(p["texto"])
		caixa.add_theme_font_size_override("font_size", 28)
		for estado in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
			caixa.add_theme_color_override(estado, Color(0.15, 0.15, 0.15))
		caixa.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.45))
		caixa.custom_minimum_size.x = 760
		caixa.toggled.connect(func(_v: bool) -> void: alternar(str(p["id"])))
		linha.add_child(caixa)
		var efeito := _rotulo(_efeito(p), 24, Color(0.35, 0.3, 0.25))
		efeito.autowrap_mode = TextServer.AUTOWRAP_OFF
		efeito.custom_minimum_size.x = 420
		linha.add_child(efeito)
		coluna.add_child(linha)
		_caixas[str(p["id"])] = caixa

	for lado in LADOS:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 20)
		var nome := _rotulo(NOMES_LADOS[lado], 32, Color(0.15, 0.15, 0.15))
		nome.custom_minimum_size.x = 300
		linha.add_child(nome)
		var barra := ProgressBar.new()
		barra.max_value = 100
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(560, 30)
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha.add_child(barra)
		_barras[lado] = barra
		var valor := _rotulo("", 32, Color(0.15, 0.15, 0.15))
		linha.add_child(valor)
		_rotulos_lado[lado] = valor
		coluna.add_child(linha)

	var linha_t := HBoxContainer.new()
	linha_t.add_theme_constant_override("separation", 20)
	_rotulo_tensao = _rotulo("", 30, Color(0.7, 0.15, 0.1))
	_rotulo_tensao.custom_minimum_size.x = 300
	linha_t.add_child(_rotulo_tensao)
	_barra_tensao = ProgressBar.new()
	_barra_tensao.max_value = 100
	_barra_tensao.show_percentage = false
	_barra_tensao.custom_minimum_size = Vector2(560, 24)
	_barra_tensao.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_barra_tensao.modulate = Color(0.9, 0.3, 0.2)
	linha_t.add_child(_barra_tensao)
	coluna.add_child(linha_t)

	_rotulo_c = _rotulo("", 26, Color(0.15, 0.42, 0.18))
	coluna.add_child(_rotulo_c)
	_rotulo_aviso = _rotulo("", 26, Color(0.7, 0.2, 0.1))
	coluna.add_child(_rotulo_aviso)
	_botao_confirmar = Button.new()
	_botao_confirmar.text = "Levar o acordo à mesa"
	_botao_confirmar.add_theme_font_size_override("font_size", 32)
	_botao_confirmar.custom_minimum_size = Vector2(0, 60)
	_botao_confirmar.pressed.connect(confirmar)
	coluna.add_child(_botao_confirmar)


func _efeito(p: Dictionary) -> String:
	var partes: Array[String] = []
	for lado in LADOS:
		var v := int(p.get(lado, 0))
		partes.append("%s %s%d" % ["Com." if lado == "comunidade" else "Emp.", "+" if v >= 0 else "", v])
	if int(p.get("tensao", 0)) > 0:
		partes.append("tensão +%d" % int(p["tensao"]))
	return "  ".join(partes)


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if tamanho < 30 else TextServer.AUTOWRAP_OFF
	return l
