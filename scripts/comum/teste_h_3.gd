extends Node

const COM_PROVA: bool = true  # troque para true para liberar a opção "Provas"

@onready var hud: HudDialogo = $HudDialogo


func _ready() -> void:
	DialogoManager.tensao_mudou.connect(hud.definir_tensao)
	DialogoManager.confianca_mudou.connect(hud.definir_confianca)
	hud.tensao_estourou.connect(func() -> void: print("TENSÃO ESTOUROU"))
	if COM_PROVA:
		GameState.dar_prova("relato_curado")

	print("== exemplo (teclas 1 a 4 escolhem) ==")
	var r: Dictionary = await DialogoManager.iniciar("res://data/dialogos/exemplo.json")
	print("Resultado: ", r)
	var d := DialogoLoader.carregar("res://data/dialogos/exemplo.json")
	var v := ValidadorGrafo.analisar(d)
	print("Nota: %.1f (S=%d, S_min=%d, S_max=%d)" % [
		ValidadorGrafo.nota(r["pontos"], v["s_min"], v["s_max"]), r["pontos"], v["s_min"], v["s_max"]])

	print("== teste_tensao ==")
	var r2: Dictionary = await DialogoManager.iniciar("res://data/dialogos/teste_tensao.json")
	print("Resultado: ", r2)
