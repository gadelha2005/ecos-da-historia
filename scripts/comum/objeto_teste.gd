extends Area2D

@export_multiline var mensagem: String = "Olá! Eu sou um objeto de teste."
@export_file("*.tscn") var cena_destino: String = ""
@export var spawn_destino: String = ""


func interagir(jogador: Player) -> void:
	jogador.pode_mover = false
	if cena_destino != "":
		SceneManager.trocar_cena(cena_destino, spawn_destino)
		return
	print(mensagem)
	await get_tree().create_timer(1.0).timeout
	jogador.pode_mover = true
