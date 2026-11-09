class_name MenuEscolhas
extends CanvasLayer
## Menu de escolhas 2x2 (card H1).
## Uso: var indice: int = await menu.escolher("Pergunta?", opcoes)
## Cada opção é um Dictionary: {"tipo": "empatia"|"fato"|"autoridade"|"provas", "texto": String, "habilitada": bool}

signal escolheu(indice: int)

const COR_TIPO := {
	"empatia": Color(0.85, 0.25, 0.25),
	"fato": Color(0.25, 0.5, 0.9),
	"autoridade": Color(0.95, 0.6, 0.15),
	"provas": Color(0.3, 0.75, 0.4),
}

const NOME_TIPO := {
	"empatia": "Empatia",
	"fato": "Fato",
	"autoridade": "Autoridade",
	"provas": "Provas",
}

const COR_FUNDO := Color(0.08, 0.07, 0.06, 0.92)
const COR_FOCO := Color(1, 0.9, 0.5)

@onready var pergunta_label: Label = %Pergunta

var botoes: Array[Button] = []
var _opcoes: Array[Dictionary] = []
var _aberto := false


func _ready() -> void:
	botoes.assign([%Botao1, %Botao2, %Botao3, %Botao4])
	for i in botoes.size():
		botoes[i].pressed.connect(_escolher.bind(i))
	hide()


func escolher(pergunta: String, opcoes: Array[Dictionary]) -> int:
	_opcoes = opcoes
	pergunta_label.text = pergunta
	for i in botoes.size():
		if i < opcoes.size():
			_configurar_botao(botoes[i], i, opcoes[i])
		else:
			botoes[i].hide()
	show()
	_aberto = true
	for botao in botoes:
		if botao.visible and not botao.disabled:
			botao.grab_focus()
			break
	var indice: int = await escolheu
	_aberto = false
	hide()
	return indice


func _configurar_botao(botao: Button, i: int, opcao: Dictionary) -> void:
	var tipo := str(opcao.get("tipo", "empatia")).to_lower()
	var habilitada := bool(opcao.get("habilitada", true))
	var texto := str(opcao.get("texto", ""))
	var cor: Color = COR_TIPO.get(tipo, COR_TIPO["empatia"])
	var rotulo: String = NOME_TIPO.get(tipo, tipo.capitalize())
	if not habilitada and tipo == "provas":
		rotulo += " (sem prova)"

	botao.show()
	botao.text = "%d · %s\n%s" % [i + 1, rotulo, texto]
	botao.disabled = not habilitada

	for estado in ["normal", "hover", "pressed"]:
		botao.add_theme_stylebox_override(estado, _criar_estilo(cor))
	botao.add_theme_stylebox_override("disabled", _criar_estilo(cor.darkened(0.6)))

	var foco := StyleBoxFlat.new()
	foco.draw_center = false
	foco.set_border_width_all(6)
	foco.border_color = COR_FOCO
	botao.add_theme_stylebox_override("focus", foco)


func _criar_estilo(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_FUNDO
	estilo.border_color = cor
	estilo.border_width_left = 4
	estilo.border_width_right = 4
	estilo.border_width_bottom = 4
	estilo.border_width_top = 14
	estilo.content_margin_left = 20
	estilo.content_margin_right = 20
	estilo.content_margin_top = 18
	estilo.content_margin_bottom = 10
	return estilo


func _escolher(i: int) -> void:
	if not _aberto:
		return
	if i >= _opcoes.size():
		return
	if not bool(_opcoes[i].get("habilitada", true)):
		return
	escolheu.emit(i)


func _input(event: InputEvent) -> void:
	if not _aberto:
		return
	for i in 4:
		if event.is_action_pressed("escolha_%d" % (i + 1)):
			get_viewport().set_input_as_handled()
			_escolher(i)
			return
	if event.is_action_pressed("interagir"):
		var indice := botoes.find(get_viewport().gui_get_focus_owner())
		if indice != -1:
			get_viewport().set_input_as_handled()
			_escolher(indice)
