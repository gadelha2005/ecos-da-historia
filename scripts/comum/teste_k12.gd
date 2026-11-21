extends Node
## Teste do card K12: o hub montado de verdade.
## Do hub: só o portal de 1904 está ativo, os outros respondem "trancado"; o de 1904 leva à
## fase_1904. Na volta com a chave, a porta encaixa, a zona da saúde ganha cor e o portal
## de 1973 acende. Roda com --headless (fecha sozinho e imprime APROVADO/REPROVADO).

const CENA_HUB: String = "res://scenes/hub/hub.tscn"
const CENA_FASE: String = "res://scenes/fases/fase_1904.tscn"

var _ok: bool = true
var _tempo: float = 0.0


func _ready() -> void:
	if get_tree().current_scene == self:
		set_process(false)
		var executor: Node = (get_script() as GDScript).new()
		executor.name = "ExecutorK12"
		get_tree().root.add_child.call_deferred(executor)
		return
	_rodar.call_deferred()


func _process(delta: float) -> void:
	_tempo += delta
	if Mensagem.esta_aberta():
		Mensagem._avancar.emit()
	if _tempo > 90.0:
		_fim("tempo esgotado")


func _rodar() -> void:
	GameState.reiniciar()
	GameState.nome_jogador = "Teste"
	SceneManager.trocar_cena(CENA_HUB, "Spawn_Inicio")
	await _esperar_cena(CENA_HUB)
	var hub := get_tree().current_scene
	var eventos: HubEventos = hub.get_node("HubEventos")
	await get_tree().create_timer(1.0).timeout
	while eventos.esta_ocupado():
		await get_tree().process_frame
	_checar(GameState.intro_vista, "intro do ECO no hub")

	var portais: Array = hub.get_node("Portais").get_children()
	_checar(portais.size() == 4, "4 portais no hub")
	_checar(portais[0].estado == Portal.Estado.ATIVO, "portal 1904 ativo")
	for i in range(1, 4):
		_checar(portais[i].estado == Portal.Estado.TRANCADO, "portal %d trancado" % i)
	_checar(hub.has_node("Porta") and hub.has_node("HudChaves") and hub.has_node("FiltroCor") and hub.has_node("TerminalTutorial"), "porta, HUD, filtro e terminal no hub")

	# portal trancado não leva a lugar nenhum
	portais[1].interagir(hub.jogador)
	await get_tree().create_timer(0.5).timeout
	_checar(get_tree().current_scene == hub, "portal 1973 trancado não troca de cena")

	# portal de 1904 leva à fase
	hub.jogador.pode_mover = true
	portais[0].interagir(hub.jogador)
	await _esperar_cena(CENA_FASE)
	_checar(true, "portal 1904 levou à fase 1904")

	# volta ao hub com a chave (como o fim da fase faz)
	await get_tree().create_timer(0.5).timeout
	GameState.dar_chave(GameState.FASE_1904)
	SceneManager.trocar_cena(CENA_HUB, "Spawn_Portal1904")
	await _esperar_cena(CENA_HUB)
	hub = get_tree().current_scene
	eventos = hub.get_node("HubEventos")
	await get_tree().create_timer(1.0).timeout
	while eventos.esta_ocupado():
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	_checar(GameState.chaves_encaixadas[0], "chave de 1904 encaixada na porta")
	_checar(GameState.cor_zona(0) >= 1.0, "zona da saúde colorida")
	_checar(hub.get_node("Portais/Portal1973").estado == Portal.Estado.ATIVO, "portal 1973 aceso")
	_checar(hub.get_node("Portais/Portal1904").estado == Portal.Estado.CONCLUIDO, "portal 1904 concluído")
	_fim("")


func _esperar_cena(caminho: String) -> void:
	while get_tree().current_scene == null or get_tree().current_scene.scene_file_path != caminho:
		await get_tree().process_frame


func _checar(cond: bool, descricao: String) -> void:
	print("  [%s] %s" % ["ok" if cond else "FALHOU", descricao])
	_ok = _ok and cond


func _fim(motivo: String) -> void:
	set_process(false)
	print("K12: %s %s" % ["APROVADO" if _ok and motivo == "" else "REPROVADO", motivo])
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
