extends Node

const TOTAL_FASES: int = 4
const FASE_1904: int = 0
const FASE_1973: int = 1
const FASE_1979: int = 2
const FASE_1982: int = 3

# Fase 1904: moradores na ordem em que precisam ser visitados.
const MORADORES: Array[String] = [
	"inacia", "dona_maria", "ze_tonico", "seu_anselmo", "seu_quintino", "dona_cotinha"
]

var nome_jogador: String = ""
var aparencia: int = 0
var chaves: Array[bool] = [false, false, false, false]  # 1904, 1973, 1979, 1982
var tentativas: Array[int] = [0, 0, 0, 0]
var pontuacao: Array[float] = [0.0, 0.0, 0.0, 0.0]

# Fase 1904
var moradores_concluidos: int = 0  # quantos já foram concluídos, sempre em ordem
var provas: Array[String] = []     # ids das provas coletadas
var dicas: Dictionary = {}         # morador_id -> dica do ECO (String)


func tem_chave(fase: int) -> bool:
	return chaves[fase]


func dar_chave(fase: int) -> void:
	chaves[fase] = true


func total_chaves() -> int:
	return chaves.count(true)


func portal_liberado(fase: int) -> bool:
	return fase == 0 or chaves[fase - 1]  # o portal só abre com a chave anterior


func morador_liberado(id: String) -> bool:
	var i := MORADORES.find(id)
	return i != -1 and i <= moradores_concluidos


func concluir_morador(id: String) -> void:
	if MORADORES.find(id) == moradores_concluidos:
		moradores_concluidos += 1


func tem_prova(id: String) -> bool:
	return provas.has(id)


func dar_prova(id: String) -> void:
	if not provas.has(id):
		provas.append(id)


func guardar_dica(morador_id: String, texto: String) -> void:
	dicas[morador_id] = texto


# Reinício da fase 1904: zera as conversas, mantém provas e dicas.
func reiniciar_fase_1904() -> void:
	moradores_concluidos = 0
	tentativas[FASE_1904] += 1


func reiniciar() -> void:
	nome_jogador = ""
	aparencia = 0
	moradores_concluidos = 0
	provas.clear()
	dicas.clear()
	for i in TOTAL_FASES:
		chaves[i] = false
		tentativas[i] = 0
		pontuacao[i] = 0.0
