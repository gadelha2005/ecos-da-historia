extends Node


func _ready() -> void:
	var d := DialogoLoader.carregar("res://data/dialogos/exemplo.json")
	if d == null:
		return
	print("Início: ", d.inicio, " | nós: ", d.nos.size())
	for id in d.nos:
		var no: NoDialogo = d.nos[id]
		print("[%s] %s%s" % [id, no.fala, "  (FINAL)" if no.final else ""])
		for o in no.opcoes:
			print("    -> %s | %s | peso %d | tensão %d | vai para '%s'" % [
				o.texto, OpcaoDialogo.Tipo.keys()[o.tipo], o.peso, o.tensao_delta, o.destino])
