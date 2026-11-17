class_name CardSaber
extends CanvasLayer
## [I8] Card "Você sabia?": curiosidade histórica no fim de cada fase.
## Uso:
##   var card: CardSaber = preload("res://scenes/ui/card_saber.tscn").instantiate()
##   add_child(card)
##   await card.mostrar({"titulo": "...", "subtitulo": "...", "texto": "..."}, icone)
## Fecha com o botão Continuar, Interagir (E/Espaço/Enter) ou Esc.

signal fechado

@onready var fundo: ColorRect = %Fundo
@onready var painel: PanelContainer = %Painel
@onready var icone: TextureRect = %Icone
@onready var rotulo_chave: Label = %RotuloChave
@onready var titulo: Label = %Titulo
@onready var subtitulo: Label = %Subtitulo
@onready var texto: Label = %Texto
@onready var botao_continuar: Button = %BotaoContinuar

var _aberto: bool = false


func _ready() -> void:
	botao_continuar.pressed.connect(fechar)


## Mostra o card e só retorna quando o jogador fechar.
## `chave`: texto opcional mostrado acima do título (ex.: "Você recebeu a Chave da Saúde!").
func mostrar(dados: Dictionary, imagem: Texture2D = null, chave: String = "") -> void:
	titulo.text = str(dados.get("titulo", "Você sabia?"))
	subtitulo.text = str(dados.get("subtitulo", ""))
	subtitulo.visible = subtitulo.text != ""
	texto.text = str(dados.get("texto", ""))
	icone.texture = imagem
	icone.visible = imagem != null
	rotulo_chave.text = chave
	rotulo_chave.visible = chave != ""

	_aberto = true
	_animar_entrada()
	botao_continuar.grab_focus()
	await fechado


func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	var tween := create_tween()
	tween.tween_property(painel, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(fundo, "modulate:a", 0.0, 0.2)
	await tween.finished
	fechado.emit()
	queue_free()


func _animar_entrada() -> void:
	fundo.modulate.a = 0.0
	painel.modulate.a = 0.0
	painel.pivot_offset = painel.size / 2.0
	painel.scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(fundo, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(painel, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(painel, "scale", Vector2.ONE, 0.35)


func _input(event: InputEvent) -> void:
	if not _aberto:
		return
	if event.is_action_pressed("interagir") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()
