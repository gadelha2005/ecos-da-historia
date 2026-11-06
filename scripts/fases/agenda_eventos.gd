class_name AgendaEventos
extends Node
## Agenda de eventos da fase: fila de prioridade (min-heap) ordenada pelo tempo do evento.
## O heap é implementado à mão sobre um Array (não é um array ordenado):
## o pai do índice i fica em (i - 1) / 2 e os filhos em 2i + 1 e 2i + 2.
## Inserir e remover o topo custam O(log n); olhar o topo custa O(1).

signal evento_disparado(nome: String, tempo: float)

## De quanto em quanto tempo (segundos) o relógio da fase confere o topo da fila.
@export var intervalo_relogio: float = 0.1
## Começa a contar o tempo sozinho ao entrar na cena.
@export var iniciar_sozinho: bool = true

## Tempo decorrido da fase, em segundos. Para enquanto o jogo está pausado.
var tempo_atual: float = 0.0

var _heap: Array[Dictionary] = []
var _contador: int = 0  # desempata eventos com o mesmo tempo: o agendado primeiro sai primeiro
var _relogio: Timer

const FOLGA: float = 0.0001  # tolerância de arredondamento ao somar os intervalos do relógio


func _ready() -> void:
	_relogio = Timer.new()
	_relogio.name = "Relogio"
	_relogio.wait_time = intervalo_relogio
	_relogio.timeout.connect(_on_relogio_timeout)
	add_child(_relogio)
	if iniciar_sozinho:
		iniciar()


func iniciar() -> void:
	_relogio.start()


func parar() -> void:
	_relogio.stop()


## Agenda `acao` para rodar quando o relógio da fase chegar em `tempo` (segundos).
func agendar(tempo: float, nome: String, acao: Callable = Callable()) -> void:
	_heap.append({"tempo": tempo, "ordem": _contador, "nome": nome, "acao": acao})
	_contador += 1
	_subir(_heap.size() - 1)


## Remove e devolve o evento de menor tempo. Devolve {} se a fila estiver vazia.
func remover_topo() -> Dictionary:
	if _heap.is_empty():
		return {}
	var topo: Dictionary = _heap[0]
	var ultimo: Dictionary = _heap.pop_back()
	if not _heap.is_empty():
		_heap[0] = ultimo
		_descer(0)
	return topo


## Olha o evento de menor tempo sem remover. Devolve {} se a fila estiver vazia.
func ver_topo() -> Dictionary:
	return {} if _heap.is_empty() else _heap[0]


func tamanho() -> int:
	return _heap.size()


func esta_vazia() -> bool:
	return _heap.is_empty()


## Avança o relógio e dispara, em ordem, todos os eventos cujo tempo já chegou.
func avancar(delta: float) -> void:
	tempo_atual += delta
	while not _heap.is_empty() and _heap[0]["tempo"] <= tempo_atual + FOLGA:
		var evento := remover_topo()
		evento_disparado.emit(evento["nome"], evento["tempo"])
		var acao: Callable = evento["acao"]
		if acao.is_valid():
			acao.call()


func _on_relogio_timeout() -> void:
	avancar(_relogio.wait_time)


# ---------- operações do heap ----------

func _menor(a: int, b: int) -> bool:
	var ea: Dictionary = _heap[a]
	var eb: Dictionary = _heap[b]
	if ea["tempo"] != eb["tempo"]:
		return ea["tempo"] < eb["tempo"]
	return ea["ordem"] < eb["ordem"]


func _trocar(a: int, b: int) -> void:
	var temp: Dictionary = _heap[a]
	_heap[a] = _heap[b]
	_heap[b] = temp


func _subir(i: int) -> void:
	while i > 0:
		var pai := (i - 1) / 2
		if not _menor(i, pai):
			return
		_trocar(i, pai)
		i = pai


func _descer(i: int) -> void:
	var n := _heap.size()
	while true:
		var esquerda := 2 * i + 1
		var direita := 2 * i + 2
		var menor := i
		if esquerda < n and _menor(esquerda, menor):
			menor = esquerda
		if direita < n and _menor(direita, menor):
			menor = direita
		if menor == i:
			return
		_trocar(i, menor)
		i = menor
