class_name PlantaMostra
extends CanvasLayer
## [M5] Planta final da Mostra de 1973 (N2.5).
## O jogador divide 10 pontos de espaço entre os 5 grupos com os botões + e −.
## A satisfação de cada grupo = satisfação das conversas (GameState.satisfacao_grupos)
## + bônus pelo espaço recebido (bonus_por_espaco, que cresce cada vez menos).
## Regras em data/fases/mostra_1973.json. Uso:
##   var planta: PlantaMostra = preload("res://scenes/ui/planta_mostra.tscn").instantiate()
##   add_child(planta)
##   var r: Dictionary = await planta.montar()   # {"aprovado", "c", "motivo", "dica"}

signal confirmada(resultado: Dictionary)

const CAMINHO_REGRAS: String = "res://data/fases/mostra_1973.json"

var regras: Dictionary = {}
var espacos: Dictionary = {}

var _rotulos_espaco: Dictionary = {}
var _rotulos_satisfacao: Dictionary = {}
var _barras: Dictionary = {}
var _rotulo_livres: Label
var _rotulo_c: Label
var _rotulo_aviso: Label
var _botao_confirmar: Button


static func carregar_regras() -> Dictionary:
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_REGRAS))
	if typeof(dados) != TYPE_DICTIONARY:
		push_error("Regras inválidas em " + CAMINHO_REGRAS)
		return {}
	return dados


## Satisfação final de um grupo com `espaco` pontos.
static func satisfacao_final(base: int, espaco: int, r: Dictionary) -> int:
	var bonus: Array = r.get("bonus_por_espaco", [0])
	return clampi(base + int(bonus[clampi(espaco, 0, bonus.size() - 1)]), 0, 100)


## Avalia um plano. espacos e satisfacoes: grupo -> int. Devolve {"aprovado", "c", "motivo", "finais"}.
static func avaliar(espacos_plano: Dictionary, satisfacoes: Dictionary, r: Dictionary) -> Dictionary:
	var grupos: Array = r.get("grupos", [])
	var finais := {}
	var soma := 0
	var com_espaco := 0
	var minima := 100
	var usados := 0
	for g in grupos:
		var esp := int(espacos_plano.get(g, 0))
		usados += esp
		if esp > 0:
			com_espaco += 1
		var f := satisfacao_final(int(satisfacoes.get(g, GameState.SATISFACAO_INICIAL)), esp, r)
		finais[g] = f
		soma += f
		minima = mini(minima, f)
	var c := float(soma) / maxf(1.0, grupos.size())
	var motivo := ""
	if usados < int(r.get("pontos_total", 10)):
		motivo = "pontos_sobrando"
	elif com_espaco < int(r.get("min_grupos_com_espaco", 4)):
		motivo = "concentrada"
	elif minima < int(r.get("satisfacao_minima", 40)):
		motivo = "insatisfeito"
	elif c < float(r.get("c_minimo", 70)):
		motivo = "nota_baixa"
	return {"aprovado": motivo == "", "c": c, "motivo": motivo, "finais": finais}


func _ready() -> void:
	layer = 80
	regras = carregar_regras()
	for g in regras.get("grupos", []):
		espacos[g] = 0
	_montar_tela()
	_atualizar()


## Mostra a planta e espera o jogador confirmar um plano com todos os pontos usados.
func montar() -> Dictionary:
	_botao_confirmar.grab_focus()
	var resultado: Dictionary = await confirmada
	return resultado


func pontos_livres() -> int:
	var usados := 0
	for g in espacos:
		usados += int(espacos[g])
	return int(regras.get("pontos_total", 10)) - usados


func mudar(grupo: String, delta: int) -> void:
	var novo := int(espacos[grupo]) + delta
	if novo < 0 or (delta > 0 and pontos_livres() <= 0):
		return
	espacos[grupo] = novo
	_atualizar()


## Usado pelo botão e pelos testes.
func confirmar() -> void:
	if pontos_livres() > 0:
		_rotulo_aviso.text = str(regras.get("dicas", {}).get("pontos_sobrando", ""))
		return
	var r := avaliar(espacos, GameState.satisfacao_grupos, regras)
	r["dica"] = str(regras.get("dicas", {}).get(r["motivo"], ""))
	for g in espacos:
		GameState.espaco_grupos[g] = espacos[g]
	GameState.pontuacao[GameState.FASE_1973] = r["c"]
	confirmada.emit(r)
	queue_free()


func _atualizar() -> void:
	var r := avaliar(espacos, GameState.satisfacao_grupos, regras)
	for g in espacos:
		_rotulos_espaco[g].text = str(espacos[g])
		var f: int = r["finais"][g]
		_rotulos_satisfacao[g].text = "%s %d" % [_rosto(f), f]
		_barras[g].value = f
		_barras[g].modulate = _cor(f)
	_rotulo_livres.text = "Pontos de espaço livres: %d" % pontos_livres()
	_rotulo_c.text = "Mostra representa: %d%%" % roundi(r["c"])
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


# --- Tela montada por código (cores de serigrafia: magenta, ciano e amarelo sobre bege) ---

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
	painel.custom_minimum_size = Vector2(1200, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.93, 0.88, 0.76)
	estilo.border_color = Color(0.85, 0.15, 0.5)
	estilo.set_border_width_all(8)
	estilo.set_content_margin_all(40)
	painel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(painel)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 18)
	painel.add_child(coluna)

	coluna.add_child(_rotulo("Planta da Mostra de Cultura · 1973", 48, Color(0.75, 0.1, 0.45)))
	coluna.add_child(_rotulo("Divida o espaço entre os grupos. Ninguém pode ficar de fora nem muito insatisfeito.", 28, Color(0.2, 0.2, 0.25)))

	var nomes: Dictionary = regras.get("nomes", {})
	for g in regras.get("grupos", []):
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 20)
		var nome := _rotulo(str(nomes.get(g, g)), 34, Color(0.15, 0.15, 0.2))
		nome.custom_minimum_size.x = 340
		linha.add_child(nome)
		linha.add_child(_botao("−", mudar.bind(g, -1)))
		var esp := _rotulo("0", 40, Color(0.1, 0.45, 0.7))
		esp.custom_minimum_size.x = 70
		esp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		linha.add_child(esp)
		_rotulos_espaco[g] = esp
		linha.add_child(_botao("+", mudar.bind(g, 1)))
		var barra := ProgressBar.new()
		barra.max_value = 100
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(320, 30)
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha.add_child(barra)
		_barras[g] = barra
		var sat := _rotulo("", 34, Color(0.15, 0.15, 0.2))
		sat.custom_minimum_size.x = 140
		linha.add_child(sat)
		_rotulos_satisfacao[g] = sat
		coluna.add_child(linha)

	_rotulo_livres = _rotulo("", 32, Color(0.1, 0.45, 0.7))
	coluna.add_child(_rotulo_livres)
	_rotulo_c = _rotulo("", 32, Color(0.75, 0.1, 0.45))
	coluna.add_child(_rotulo_c)
	_rotulo_aviso = _rotulo("", 26, Color(0.7, 0.2, 0.1))
	_rotulo_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(_rotulo_aviso)
	_botao_confirmar = _botao("Confirmar plano", confirmar)
	coluna.add_child(_botao_confirmar)


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if tamanho < 30 else TextServer.AUTOWRAP_OFF
	return l


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", 34)
	b.custom_minimum_size = Vector2(70, 60)
	b.pressed.connect(acao)
	return b
