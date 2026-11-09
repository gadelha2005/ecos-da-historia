extends CenaJogavel
## Teste do card I4. Pegue as provas (E). R reinicia a fase (reiniciar_fase_1904 + recarrega a cena):
## as provas pegas não voltam a aparecer e a lista continua igual. Z zera tudo (GameState.reiniciar).


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_R:
		GameState.reiniciar_fase_1904()
		print("Fase reiniciada. Provas no GameState: ", GameState.provas)
		SceneManager.trocar_cena(scene_file_path, "Spawn_Inicio")
	elif event.keycode == KEY_Z:
		GameState.reiniciar()
		print("GameState zerado.")
		SceneManager.trocar_cena(scene_file_path, "Spawn_Inicio")
