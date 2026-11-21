extends CenaJogavel
## Teste do card K2: os 4 portais do hub. Começa só o de 1904 ativo.
## Teclas 1 a 4: dá a chave da época, "encaixa" na porta e acende o portal seguinte
## (como o HubEventos do K8 faz na volta ao hub). Interagir num trancado: "Ainda trancado."
## R recarrega (estados lidos do GameState, sem animação). Z zera.

@export var portais: Array[Portal] = []


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			var fase: int = event.keycode - KEY_1
			if not GameState.portal_liberado(fase):
				print("A época %d ainda está trancada." % fase)
				return
			GameState.dar_chave(fase)
			GameState.encaixar_chave(fase)
			portais[fase].atualizar_estado()
			if fase + 1 < portais.size():
				await portais[fase + 1].acender()
		KEY_R:
			SceneManager.trocar_cena(scene_file_path, "Spawn_Inicio")
		KEY_Z:
			GameState.reiniciar()
			SceneManager.trocar_cena(scene_file_path, "Spawn_Inicio")
