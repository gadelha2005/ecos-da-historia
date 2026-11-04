extends Area2D

@export_range(0, 3) var fase: int = 0
@export_file("*.tscn") var cena_destino: String = ""
@export var spawn_destino: String = ""
@export var sempre_aberto: bool = false   # usado nos portais de volta


func interagir(jogador: Player) -> void:
	jogador.pode_mover = false
	if sempre_aberto or GameState.portal_liberado(fase):
		if not _ir_para(cena_destino, spawn_destino):
			jogador.pode_mover = true  # a cena ainda não existe: não deixa o jogador travado
	else:
		await _mostrar(["Ainda trancado."])
		jogador.pode_mover = true


func _ir_para(caminho: String, spawn: String = "") -> bool:
	if ResourceLoader.exists(caminho):
		SceneManager.trocar_cena(caminho, spawn)
		return true
	print("Ainda não existe: ", caminho)
	return false


func _mostrar(linhas: Array[String]) -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.mostrar(linhas)
	else:
		print("\n".join(linhas))
