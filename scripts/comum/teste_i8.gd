extends CenaJogavel
## Teste do card I8: fim da fase 1904.
## Aperte C (ou clique em "Concluir fase") para simular os 6 moradores aprovados e chamar
## FimFase1904.concluir(): fechamento → chave → card "Você sabia?" → volta ao hub (Spawn_Portal1904).

@export var fim: FimFase1904
@export var painel: Label
@export var botao: Button


func _ready() -> void:
	super._ready()
	botao.pressed.connect(_concluir)


func _process(_delta: float) -> void:
	painel.text = "Teste I8 · Fim da fase 1904\nAperte C ou clique no botão\n\nMoradores concluídos: %d / %d\nChave da Saúde: %s\nChave pendente para a porta: %s\nPortal 1973 liberado: %s" % [
		GameState.moradores_concluidos, GameState.MORADORES.size(),
		"SIM" if GameState.tem_chave(GameState.FASE_1904) else "não",
		"SIM" if GameState.chave_pendente() == GameState.FASE_1904 else "não",
		"SIM" if GameState.portal_liberado(GameState.FASE_1973) else "não"]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		_concluir()


func _concluir() -> void:
	botao.disabled = true
	GameState.moradores_concluidos = GameState.MORADORES.size()  # simula os 6 aprovados
	fim.concluir()
