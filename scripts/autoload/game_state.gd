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

## [L0] Ordem das conversas de cada fase (a 1982 é livre, por isso fica vazia).
const SEQUENCIA: Dictionary = {
	FASE_1904: MORADORES,
	FASE_1973: ["rendeira", "cordelista", "diretor_teatro", "pintor", "patrocinador"],
	FASE_1979: ["dona_rita", "engenheiro", "seu_raimundo", "investidor", "jovem", "operario"],
	FASE_1982: [],
}

## [L0] 1973: grupo da Mostra que cada defensor representa.
const GRUPO_1973: Dictionary = {
	"rendeira": "renda", "cordelista": "cordel", "diretor_teatro": "teatro",
	"pintor": "pintura", "patrocinador": "patrocinador",
}
const SATISFACAO_INICIAL: int = 50
const TEMPO_1982: int = 24

var nome_jogador: String = ""
var aparencia: int = 0
var chaves: Array[bool] = [false, false, false, false]  # 1904, 1973, 1979, 1982
var tentativas: Array[int] = [0, 0, 0, 0]
var pontuacao: Array[float] = [0.0, 0.0, 0.0, 0.0]
var chaves_encaixadas: Array[bool] = [false, false, false, false]  # chave já colocada na porta (animação feita)
var intro_vista: bool = false  # a intro do ECO no hub já foi mostrada

## [L0] Quantas conversas de cada fase já foram concluídas (sempre na ordem de SEQUENCIA).
var npcs_concluidos: Array[int] = [0, 0, 0, 0]

# Fase 1904 (atalho para npcs_concluidos[FASE_1904], usado desde o I2)
var moradores_concluidos: int:
	get:
		return npcs_concluidos[FASE_1904]
	set(valor):
		npcs_concluidos[FASE_1904] = valor
var provas: Array[String] = []     # ids das provas coletadas (1904 sem prefixo; demais com "1973_", "1979_"...)
var dicas: Dictionary = {}         # npc_id -> dica do ECO (String)

# Fase 1973: espaço (0 a 10 pontos) e satisfação (0 a 100) de cada grupo da Mostra
var espaco_grupos: Dictionary = {}
var satisfacao_grupos: Dictionary = {}

# Fase 1979: confiança de cada lado e tensão da fase
var confianca_lado: Dictionary = {"comunidade": 0, "empreendimento": 0}
var tensao_fase: int = 0

# Fase 1982: relógio e itens
var tempo_restante: int = TEMPO_1982
var itens_escola: Array[String] = []
var itens_troca: Array[String] = []


func _init() -> void:
	_zerar_1973()


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
	return npc_liberado(FASE_1904, id)


func concluir_morador(id: String) -> void:
	concluir_npc(FASE_1904, id)


func tem_prova(id: String) -> bool:
	return provas.has(id)


func dar_prova(id: String) -> void:
	if not provas.has(id):
		provas.append(id)


func guardar_dica(morador_id: String, texto: String) -> void:
	dicas[morador_id] = texto


# Reinício da fase 1904: zera as conversas, mantém provas e dicas.
func reiniciar_fase_1904() -> void:
	reiniciar_fase(FASE_1904)


# --- [L0] Base compartilhada das fases ---

func npc_liberado(fase: int, id: String) -> bool:
	var i: int = SEQUENCIA[fase].find(id)
	return i != -1 and i <= npcs_concluidos[fase]


func npc_concluido(fase: int, id: String) -> bool:
	var i: int = SEQUENCIA[fase].find(id)
	return i != -1 and i < npcs_concluidos[fase]


func concluir_npc(fase: int, id: String) -> void:
	if SEQUENCIA[fase].find(id) == npcs_concluidos[fase]:
		npcs_concluidos[fase] += 1


func todos_concluidos(fase: int) -> bool:
	return npcs_concluidos[fase] >= SEQUENCIA[fase].size()


## Volta a fase ao começo: zera as conversas e o estado próprio dela. Provas e dicas ficam.
func reiniciar_fase(fase: int) -> void:
	npcs_concluidos[fase] = 0
	tentativas[fase] += 1
	match fase:
		FASE_1973:
			_zerar_1973()
		FASE_1979:
			confianca_lado = {"comunidade": 0, "empreendimento": 0}
			tensao_fase = 0
		FASE_1982:
			tempo_restante = TEMPO_1982
			itens_escola.clear()
			itens_troca.clear()


## 1973: soma o que uma conversa mudou na satisfação dos grupos (ex.: {"renda": 20}).
func somar_satisfacao(mudancas: Dictionary) -> void:
	for grupo in mudancas:
		var atual: int = satisfacao_grupos.get(grupo, SATISFACAO_INICIAL)
		satisfacao_grupos[grupo] = clampi(atual + int(mudancas[grupo]), 0, 100)


func _zerar_1973() -> void:
	espaco_grupos.clear()
	satisfacao_grupos.clear()
	for grupo in GRUPO_1973.values():
		espaco_grupos[grupo] = 0
		satisfacao_grupos[grupo] = SATISFACAO_INICIAL


func reiniciar() -> void:
	nome_jogador = ""
	aparencia = 0
	for i in TOTAL_FASES:
		reiniciar_fase(i)
	provas.clear()
	dicas.clear()
	intro_vista = false
	for i in TOTAL_FASES:
		chaves[i] = false
		chaves_encaixadas[i] = false
		tentativas[i] = 0
		pontuacao[i] = 0.0
