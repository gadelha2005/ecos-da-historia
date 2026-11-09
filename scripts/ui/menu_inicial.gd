class_name MenuInicial
extends Control
## [F1] Menu inicial: primeira tela do jogo.
## Jogar -> tela "Quem é o Catalisador?" (F2) se ela já existir; senão vai direto pro hub.
## Configurações -> abre a tela do F5 por cima do menu quando ela existir.

const CENA_CATALISADOR: String = "res://scenes/ui/quem_e_catalisador.tscn"  # F2
const CENA_CONFIGURACOES: String = "res://scenes/ui/configuracoes.tscn"      # F5
const CENA_HUB: String = "res://scenes/hub/hub.tscn"

@onready var botao_jogar: Button = %BotaoJogar
@onready var botao_configuracoes: Button = %BotaoConfiguracoes
@onready var botao_sair: Button = %BotaoSair


func _ready() -> void:
	get_tree().paused = false
	botao_jogar.pressed.connect(_on_jogar)
	botao_configuracoes.pressed.connect(_on_configuracoes)
	botao_sair.pressed.connect(_on_sair)

	if not ResourceLoader.exists(CENA_CONFIGURACOES):
		botao_configuracoes.disabled = true
		botao_configuracoes.tooltip_text = "Em breve"

	# Sair não faz sentido na versão web
	botao_sair.visible = not OS.has_feature("web")

	# permite navegar só pelo teclado (setas + Enter/Espaço)
	botao_jogar.grab_focus()


func _on_jogar() -> void:
	_travar_botoes()
	GameState.reiniciar()
	if ResourceLoader.exists(CENA_CATALISADOR):
		SceneManager.trocar_cena(CENA_CATALISADOR)
	else:
		SceneManager.trocar_cena(CENA_HUB)


func _on_configuracoes() -> void:
	var cena: PackedScene = load(CENA_CONFIGURACOES)
	var tela := cena.instantiate()
	add_child(tela)
	if tela.has_signal("fechada"):
		tela.fechada.connect(botao_configuracoes.grab_focus)


func _on_sair() -> void:
	get_tree().quit()


func _travar_botoes() -> void:
	# evita clicar duas vezes durante o fade
	for botao in [botao_jogar, botao_configuracoes, botao_sair]:
		botao.disabled = true
