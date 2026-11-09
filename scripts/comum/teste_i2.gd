extends CenaJogavel
## Teste do card I2: 6 moradores em ordem, com um diálogo falso de uma fala.
## Só o morador com (!) responde; os outros dizem "Ainda não é a minha vez" e o ECO
## sugere quem procurar. Concluir libera o seguinte. Z zera o progresso.

@export var info: Label


func _ready() -> void:
	super._ready()
	AvaliadorConversa.ao_reiniciar = func() -> void:
		print(">> (a fase seria reiniciada agora)")


func _process(_delta: float) -> void:
	var proximo := "sequência concluída!"
	if GameState.moradores_concluidos < GameState.MORADORES.size():
		proximo = Morador.nome_de(GameState.MORADORES[GameState.moradores_concluidos])
	info.text = "Concluídos: %d/6   ·   Vez de: %s   ·   E: conversar   ·   Z: zerar" % [
		GameState.moradores_concluidos, proximo]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Z:
		GameState.reiniciar()
		get_tree().call_group("moradores", "atualizar_indicador")
		print("Progresso zerado.")


func _exit_tree() -> void:
	# limpa a função guardada na variável static do avaliador; senão a Godot quebra ao fechar
	AvaliadorConversa.ao_reiniciar = Callable()
