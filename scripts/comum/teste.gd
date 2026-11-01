extends Node2D

const ACOES: Array[String] = [
	"mover_cima", "mover_baixo", "mover_esquerda", "mover_direita",
	"interagir", "cancelar", "pausar",
	"escolha_1", "escolha_2", "escolha_3", "escolha_4",
]

func _unhandled_input(event: InputEvent) -> void:
	for acao in ACOES:
		if event.is_action_pressed(acao):
			print(acao)
