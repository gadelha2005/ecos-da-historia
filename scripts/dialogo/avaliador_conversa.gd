class_name AvaliadorConversa
extends RefCounted

const NOTA_MINIMA: float = 70.0
const DICA_PADRAO: String = "Ouça a objeção com calma antes de responder. Tente outro caminho."

# Os testes trocam isto para não recarregar a cena de verdade.
static var ao_reiniciar: Callable = Callable()


# resultado = o Dictionary que o DialogoManager.iniciar() devolve.
# Devolve true se a conversa foi aprovada.
static func avaliar(morador_id: String, caminho: String, resultado: Dictionary) -> bool:
	var dialogo := DialogoLoader.carregar(caminho)
	if dialogo == null:
		return false

	var analise := ValidadorGrafo.analisar(dialogo)
	if not analise["ok"]:
		push_error("Diálogo '%s' inválido: %s" % [caminho, analise["problemas"]])
		return false

	var nota := ValidadorGrafo.nota(int(resultado["pontos"]), analise["s_min"], analise["s_max"])
	var aprovado: bool = (not resultado["falhou"]) and nota >= NOTA_MINIMA
	print("[%s] S=%d nota=%.1f falhou=%s -> %s" % [
		morador_id, resultado["pontos"], nota, resultado["falhou"], "APROVADO" if aprovado else "REPROVADO"])

	if aprovado:
		GameState.concluir_morador(morador_id)
		return true

	var dica := dialogo.dica if dialogo.dica != "" else DICA_PADRAO
	GameState.guardar_dica(morador_id, dica)
	GameState.reiniciar_fase_1904()
	_reiniciar_cena()
	return false


static func _reiniciar_cena() -> void:
	if ao_reiniciar.is_valid():
		ao_reiniciar.call()
		return
	var arvore := Engine.get_main_loop() as SceneTree
	SceneManager.trocar_cena(arvore.current_scene.scene_file_path, "Spawn_Inicio")
