class_name CenaJogavel
extends Node2D

@export var jogador: Player
@export var spawn_padrao: String = "Spawn_Inicio"


func _ready() -> void:
	var nome := SceneManager.spawn_destino
	if nome == "":
		nome = spawn_padrao
	_posicionar_jogador(nome)
	SceneManager.spawn_destino = ""


func _posicionar_jogador(nome: String) -> void:
	for marcador in get_tree().get_nodes_in_group("spawn"):
		if marcador.name == nome:
			jogador.global_position = marcador.global_position
			return
	push_warning("Spawn não encontrado: " + nome)
