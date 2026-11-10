extends Node
signal chave_recebida(fase: int)

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
var chaves_encaixadas: Array[bool] = [false, false, false, false]  # chave já colocada na porta (animação feita)
var intro_vista: bool = false  # a intro do ECO no hub já foi mostrada

# Fase 1904
var moradores_concluidos: int = 0  # quantos já foram concluídos, sempre em ordem
var provas: Array[String] = []     # ids das provas coletadas
var dicas: Dictionary = {}         # morador_id -> dica do ECO (String)


func tem_chave(fase: int) -> bool:
	return chaves[fase]


func dar_chave(fase: int) -> void:
	var nova := not chaves[fase]
	chaves[fase] = true
	if nova:
		chave_recebida.emit(fase)


func total_chaves() -> int:
	return chaves.count(true)


func portal_liberado(fase: int) -> bool:
	return fase == 0 or chaves[fase - 1]  # o portal só abre com a chave anterior

# Primeira fase com chave já pega e ainda não encaixada na porta, ou -1.
func chave_pendente() -> int:
	for i in TOTAL_FASES:
		if chaves[i] and not chaves_encaixadas[i]:
			return i
	return -1


func encaixar_chave(fase: int) -> void:
	chaves_encaixadas[fase] = true


# 0.0 = zona cinza, 1.0 = zona colorida (usada pelo shader do K1 e pelo HUD do K4).
func cor_zona(fase: int) -> float:
	return 1.0 if chaves_encaixadas[fase] else 0.0

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
	intro_vista = false
	for i in TOTAL_FASES:
		chaves[i] = false
		chaves_encaixadas[i] = false
		tentativas[i] = 0
		pontuacao[i] = 0.0
