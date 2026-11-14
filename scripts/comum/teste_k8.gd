extends Node
## Teste do K8. Teclas: 1 a 4 = pegar a chave da fase, V = rodar a sequência,
## I = esquecer a intro, R = reiniciar tudo e recarregar.

const HUB: PackedScene = preload("res://scenes/hub/hub.tscn")

var hub: CenaJogavel
var eventos: HubEventos

@onready var rotulo: Label = $Interface/Rotulo


func _ready() -> void:
	hub = HUB.instantiate() as CenaJogavel
	add_child(hub)
	eventos = HubEventos.new()
	eventos.auto_iniciar = false
	eventos.jogador = hub.jogador
	eventos.posicao_porta = hub.get_node("Posicoes/Posicao_PortaSaida")
	hub.add_child(eventos)

	assert(eventos._linhas("intro").size() > 0, "intro tem falas")
	assert(eventos._linhas("volta", 0).size() > 0, "volta da fase 0 tem falas")
	assert(eventos._linhas("volta", 9).is_empty(), "fase inexistente não tem falas")
	print("K8: aperte 1-4 (chave), V (sequência), I (intro de novo), R (reiniciar).")


func _process(_delta: float) -> void:
	rotulo.text = "intro_vista=%s  chaves=%s\nencaixadas=%s  pendente=%d  ocupado=%s\n[1-4] chave  [V] rodar  [I] intro  [R] reiniciar" % [
		GameState.intro_vista, GameState.chaves, GameState.chaves_encaixadas,
		GameState.chave_pendente(), eventos.esta_ocupado()]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			GameState.dar_chave(event.keycode - KEY_1)
		KEY_V:
			eventos.verificar()
		KEY_I:
			GameState.intro_vista = false
		KEY_R:
			GameState.reiniciar()
			get_tree().reload_current_scene()
