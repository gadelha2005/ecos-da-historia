extends Node


func _ready() -> void:
	for nome in ["exemplo", "teste_orfao", "teste_ciclo"]:
		var d := DialogoLoader.carregar("res://data/dialogos/%s.json" % nome)
		if d == null:
			continue
		var r := ValidadorGrafo.analisar(d)
		print("== %s ==" % nome)
		print("ok: %s | S_min: %d | S_max: %d" % [r.ok, r.s_min, r.s_max])
		print("ordem: ", r.ordem)
		for p in r.problemas:
			print("  PROBLEMA: ", p)

	var e := ValidadorGrafo.analisar(DialogoLoader.carregar("res://data/dialogos/exemplo.json"))
	for s in [0, 3, 5, 6, 7]:
		print("S=%d -> nota %.1f" % [s, ValidadorGrafo.nota(s, e.s_min, e.s_max)])
