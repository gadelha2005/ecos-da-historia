extends CenaJogavel
## Teste do card K3. Teclas 1 a 4: dá a chave da época e encaixa na porta (animação).
## E na porta: "Faltam N chaves." ou, com as 4, abre e vai para o final.
## R recarrega a cena (as fechaduras já encaixadas aparecem cheias, sem animar). Z zera tudo.

@export var porta: PortaSaida


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			var fase: int = event.keycode - KEY_1
			GameState.dar_chave(fase)
			porta.encaixar(fase)
		KEY_R:
			SceneManager.trocar_cena(scene_file_path, "Spawn_Inicio")
		KEY_Z:
			GameState.reiniciar()
			SceneManager.trocar_cena(scene_file_path, "Spawn_Inicio")
