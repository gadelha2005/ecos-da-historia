extends Node
## Teste do card I3a (e I3b/I3c): valida e joga os diálogos dos 6 moradores da fase 1904.
## 1) Passa cada JSON pelo validador do H5 (órfãos, ciclo, S_min e S_max).
## 2) Joga as conversas em sequência e avalia cada uma com o H6 (nota >= 70 e tensão abaixo do limite).
## AUTOMATICO = true escolhe sozinho a opção de maior peso (dá para rodar com --headless);
## false = você escolhe pelo menu (ou teclas 1 a 4).

# Mesma ordem de GameState.MORADORES.
const MORADORES: Array[String] = [
	"inacia", "dona_maria", "ze_tonico", "seu_anselmo", "seu_quintino", "dona_cotinha"
]
const COM_PROVAS: bool = true  # false = as opções "Provas" ficam indisponíveis
const AUTOMATICO: bool = true

var _pesos: Dictionary = {}  # texto da opção -> peso (só no modo automático)

@onready var hud: HudDialogo = $HudDialogo


func _ready() -> void:
	DialogoManager.tensao_mudou.connect(hud.definir_tensao)
	DialogoManager.confianca_mudou.connect(hud.definir_confianca)
	hud.tensao_estourou.connect(func() -> void: print("TENSÃO ESTOUROU"))
	AvaliadorConversa.ao_reiniciar = func() -> void:
		print(">> (a fase seria reiniciada agora)")

	GameState.reiniciar()
	if COM_PROVAS:
		for id in Prova.IDS:
			GameState.dar_prova(id)

	print("== Validação dos grafos ==")
	for id in MORADORES:
		var d := DialogoLoader.carregar(_caminho(id))
		if d == null:
			continue
		var v := ValidadorGrafo.analisar(d)
		print("%s -> ok: %s | S_min: %d | S_max: %d | dica: %s" % [
			id, v["ok"], v["s_min"], v["s_max"], "sim" if d.dica != "" else "NÃO"])
		for p in v["problemas"]:
			print("  PROBLEMA: ", p)

	if AUTOMATICO:
		DialogoManager.mostrar_fala = func(texto: String) -> void:
			print("  [fala] ", texto)
		DialogoManager.escolher = _escolher_melhor

	for id in MORADORES:
		print("== Conversa: %s ==" % Morador.nome_de(id))
		_guardar_pesos(id)
		var r: Dictionary = await DialogoManager.iniciar(_caminho(id))
		var aprovado := AvaliadorConversa.avaliar(id, _caminho(id), r)
		print("Aprovado: %s | Concluídos: %d | Dica guardada: %s" % [
			aprovado, GameState.moradores_concluidos, GameState.dicas.get(id, "(nenhuma)")])

	print("== Fim do teste I3a: %d/%d concluídos ==" % [GameState.moradores_concluidos, MORADORES.size()])
	if DisplayServer.get_name() == "headless":
		get_tree().quit()


# Modo automático: escolhe a opção habilitada de maior peso.
func _escolher_melhor(_pergunta: String, opcoes: Array[Dictionary]) -> int:
	var melhor := -1
	for i in opcoes.size():
		if not opcoes[i]["habilitada"]:
			continue
		if melhor == -1 or _pesos.get(opcoes[i]["texto"], 0) > _pesos.get(opcoes[melhor]["texto"], 0):
			melhor = i
	print("  [escolha] (%s) %s" % [opcoes[melhor]["tipo"], opcoes[melhor]["texto"]])
	return melhor


func _guardar_pesos(id: String) -> void:
	_pesos.clear()
	var d := DialogoLoader.carregar(_caminho(id))
	if d == null:
		return
	for no_id in d.nos:
		for op in d.nos[no_id].opcoes:
			_pesos[op.texto] = op.peso


func _caminho(id: String) -> String:
	return "res://data/dialogos/%s.json" % id


func _exit_tree() -> void:
	# limpa a função guardada na variável static do avaliador; senão a Godot quebra ao fechar
	AvaliadorConversa.ao_reiniciar = Callable()
	DialogoManager.mostrar_fala = DialogoManager._mostrar_fala_padrao
	DialogoManager.escolher = DialogoManager._escolher_padrao
