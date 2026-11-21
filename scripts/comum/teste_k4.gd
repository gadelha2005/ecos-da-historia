extends Node
## Teste do K4. Teclas: 1 a 4 = dar a chave da fase, E = encaixar a próxima
## chave pendente (e piscar o slot), R = reiniciar tudo.
## Rodando headless (--headless), faz a checagem sozinho e fecha.

@onready var hud: HudChaves = $HudChaves
@onready var rotulo: Label = $Interface/Rotulo


func _ready() -> void:
	GameState.reiniciar()
	hud.atualizar(false)
	if DisplayServer.get_name() == "headless":
		await _teste_automatico()
		return
	print("K4: aperte 1-4 (dar chave), E (encaixar e piscar), R (reiniciar).")


func _process(_delta: float) -> void:
	rotulo.text = "chaves=%s\nencaixadas=%s  cor=%d%%\n[1-4] dar chave  [E] encaixar  [R] reiniciar" % [
		GameState.chaves, GameState.chaves_encaixadas, hud.porcentagem_cor()]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			GameState.dar_chave(event.keycode - KEY_1)
		KEY_E:
			var fase := GameState.chave_pendente()
			if fase != -1:
				GameState.encaixar_chave(fase)
				await hud.piscar_slot(fase)
		KEY_R:
			GameState.reiniciar()
			hud.atualizar()


func _teste_automatico() -> void:
	var ok := true
	ok = _checar(hud.rotulo_cor.text == "Cor: 0%", "começa em 0%") and ok
	ok = _checar(hud._estados[0].text == "--", "slot 1904 começa vazio") and ok
	var esperado := [25, 50, 75, 100]
	for fase in GameState.TOTAL_FASES:
		GameState.dar_chave(fase)  # emite chave_recebida -> atualizar()
		ok = _checar(hud._estados[fase].text == "OK", "slot %s cheio" % HudChaves.ANOS[fase]) and ok
		ok = _checar(hud.rotulo_cor.text == "Cor: %d%%" % (fase * 25), "medidor parado antes de encaixar") and ok
		GameState.encaixar_chave(fase)
		await hud.piscar_slot(fase)
		ok = _checar(hud.rotulo_cor.text == "Cor: %d%%" % esperado[fase], "medidor em %d%%" % esperado[fase]) and ok
		ok = _checar(is_equal_approx(hud.barra_cor.value, esperado[fase]), "barra em %d" % esperado[fase]) and ok
		ok = _checar(hud._slots[fase].scale == Vector2.ONE, "slot voltou ao tamanho") and ok
	ok = _checar(hud.rotulo_chaves.text == "Chaves: 4/4", "contador 4/4") and ok
	print("K4: %s" % ("APROVADO" if ok else "REPROVADO"))
	get_tree().quit(0 if ok else 1)


func _checar(cond: bool, descricao: String) -> bool:
	print("  [%s] %s" % ["ok" if cond else "FALHOU", descricao])
	return cond
