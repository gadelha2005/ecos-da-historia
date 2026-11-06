extends CenaJogavel
## Teste do card I5: fila de prioridade e boato da capital.
## 1) Ao abrir, testa o heap com eventos fora de ordem e imprime a sequência na aba Saída.
## 2) Agenda eventos de teste fora de ordem na agenda da cena e mostra cada disparo.
## 3) O boato chega na metade do dia (8 s neste teste) e aumenta a tensão.

@export var agenda: AgendaEventos
@export var boato: BoatoCapital
@export var painel: Label
@export var vinheta: ColorRect

var tensao: float = 10.0
var _log: Array[String] = []


func _ready() -> void:
	super._ready()
	_testar_heap()
	# agendados fora de ordem: devem disparar A, B, C
	agenda.agendar(6.0, "evento C", _anotar.bind("evento C"))
	agenda.agendar(2.0, "evento A", _anotar.bind("evento A"))
	agenda.agendar(4.0, "evento B", _anotar.bind("evento B"))
	agenda.evento_disparado.connect(_on_evento_disparado)
	boato.boato_disparou.connect(_on_boato_disparou)


func _process(_delta: float) -> void:
	painel.text = "Tempo: %.1f s   ·   Tensão: %d / 100   ·   Eventos na fila: %d\n%s" % [
		agenda.tempo_atual, int(tensao), agenda.tamanho(), "\n".join(_log)]


func _testar_heap() -> void:
	var heap := AgendaEventos.new()  # fora da árvore: só a estrutura, sem relógio
	var tempos: Array[float] = [5.0, 1.0, 3.0, 1.0, 4.0, 2.0, 0.5]
	for i in tempos.size():
		heap.agendar(tempos[i], "e%d(%.1f)" % [i, tempos[i]])
	var saida: Array[String] = []
	while not heap.esta_vazia():
		saida.append(heap.remover_topo()["nome"])
	print("Heap, agendados: ", tempos)
	print("Heap, saída:     ", " → ".join(saida))

	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 200:
		heap.agendar(rng.randf_range(0.0, 100.0), "aleatorio_%d" % i)
	var anterior := -1.0
	var em_ordem := true
	while not heap.esta_vazia():
		var t: float = heap.remover_topo()["tempo"]
		em_ordem = em_ordem and t >= anterior
		anterior = t
	print("Heap, 200 eventos aleatórios: ", "OK, saíram em ordem" if em_ordem else "ERRO, fora de ordem")
	heap.free()


func _anotar(nome: String) -> void:
	_log.append("%.1f s: %s" % [agenda.tempo_atual, nome])


func _on_evento_disparado(nome: String, tempo: float) -> void:
	print("Disparou: %s (agendado para %.1f s)" % [nome, tempo])


func _on_boato_disparou(extra: float) -> void:
	tensao = minf(tensao + extra, 100.0)
	_log.append("%.1f s: BOATO DA CAPITAL, tensão +%d" % [agenda.tempo_atual, int(extra)])
	print("Tensão agora: %d" % int(tensao))
	var tween := create_tween()
	tween.tween_property(vinheta, "color:a", clampf(tensao / 100.0, 0.0, 0.6), 0.8)
