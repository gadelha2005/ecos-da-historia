extends CanvasLayer
## [F4] Menu de pausa (autoload "MenuPausa").
## Esc pausa/despausa, mas só dentro das cenas jogáveis (hub e fases),
## nunca no menu inicial nem na tela do Catalisador.

const CENA_MENU_INICIAL: String = "res://scenes/ui/menu_inicial.tscn"   # F1
const CENA_CONFIGURACOES: String = "res://scenes/ui/configuracoes.tscn" # F5

@onready var tela: Control = %Tela
@onready var botao_continuar: Button = %BotaoContinuar
@onready var botao_configuracoes: Button = %BotaoConfiguracoes
@onready var botao_menu: Button = %BotaoMenu

var _configuracoes: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tela.hide()
	botao_continuar.pressed.connect(fechar)
	botao_configuracoes.pressed.connect(_on_configuracoes)
	botao_menu.pressed.connect(_on_voltar_menu)
	if not ResourceLoader.exists(CENA_CONFIGURACOES):
		botao_configuracoes.disabled = true
		botao_configuracoes.tooltip_text = "Em breve"


func esta_aberto() -> bool:
	return tela.visible


func abrir() -> void:
	get_tree().paused = true
	tela.show()
	botao_continuar.grab_focus()


func fechar() -> void:
	if _configuracoes != null:
		_configuracoes.fechar()
	tela.hide()
	get_tree().paused = false


func _pode_pausar() -> bool:
	return get_tree().current_scene is CenaJogavel


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pausar"):
		return
	if _configuracoes != null:
		return  # a tela de configurações fecha sozinha com Esc
	if esta_aberto():
		get_viewport().set_input_as_handled()
		fechar()
	elif _pode_pausar():
		get_viewport().set_input_as_handled()
		abrir()


func _on_configuracoes() -> void:
	_configuracoes = load(CENA_CONFIGURACOES).instantiate()
	tela.add_child(_configuracoes)
	_configuracoes.fechada.connect(_on_configuracoes_fechada)


func _on_configuracoes_fechada() -> void:
	_configuracoes = null
	botao_configuracoes.grab_focus()


func _on_voltar_menu() -> void:
	fechar()  # despausa antes, senão o fade da troca de cena fica congelado
	SceneManager.trocar_cena(CENA_MENU_INICIAL)
