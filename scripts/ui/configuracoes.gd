class_name TelaConfiguracoes
extends Control
## [F5] Tela de configurações mínimas: volume geral e tela cheia.
## É aberta por cima do menu inicial (F1) e do menu de pausa (F4).
## Muda na hora e salva sozinha. Fecha com "Voltar" ou Esc.

signal fechada

@onready var slider_volume: HSlider = %SliderVolume
@onready var valor_volume: Label = %ValorVolume
@onready var botao_tela_cheia: Button = %BotaoTelaCheia
@onready var botao_voltar: Button = %BotaoVoltar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	slider_volume.value = Config.volume
	botao_tela_cheia.set_pressed_no_signal(Config.tela_cheia)
	_atualizar_tela_cheia(Config.tela_cheia)
	_atualizar_rotulo(Config.volume)

	slider_volume.value_changed.connect(_on_volume_mudou)
	botao_tela_cheia.toggled.connect(_on_tela_cheia)
	botao_voltar.pressed.connect(fechar)
	slider_volume.grab_focus()


func fechar() -> void:
	Config.salvar()
	fechada.emit()
	queue_free()


func _on_volume_mudou(valor: float) -> void:
	Config.definir_volume(int(valor))
	_atualizar_rotulo(int(valor))


func _on_tela_cheia(ligada: bool) -> void:
	Config.definir_tela_cheia(ligada)
	_atualizar_tela_cheia(ligada)


func _atualizar_tela_cheia(ligada: bool) -> void:
	botao_tela_cheia.text = "Ligada" if ligada else "Desligada"


func _atualizar_rotulo(valor: int) -> void:
	valor_volume.text = "%d%%" % valor


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausar") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()
