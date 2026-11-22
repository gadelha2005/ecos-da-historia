class_name Prova
extends Area2D
## [I4] Prova coletável da trilha (fase 1904). [M4] Também as amostras de 1973 (ids com "1973_").
## Ao interagir, registra em GameState (dar_prova) e some. Se o jogador já tem a prova
## (por exemplo, depois de reiniciar a fase), ela nem aparece: as provas não se perdem.

signal coletada(prova_id: String)

## Ordem e nomes das 4 provas da fase 1904 (ids usados no "exige_prova" dos diálogos).
const IDS: Array[String] = ["relato_curado", "noticia_jornal", "folheto_campanha", "depoimento_medico"]
## [M4] Amostras da fase 1973 (N2.3).
const IDS_1973: Array[String] = ["1973_renda", "1973_cordel", "1973_mascara", "1973_tela"]
const NOMES: Dictionary = {
	"relato_curado": "Relato de alguém curado",
	"noticia_jornal": "Notícia de jornal",
	"folheto_campanha": "Folheto da campanha",
	"depoimento_medico": "Depoimento de médico",
	"1973_renda": "Renda de bilro",
	"1973_cordel": "Folheto de cordel",
	"1973_mascara": "Máscara de teatro",
	"1973_tela": "Tela a óleo",
}
## Cor provisória de cada amostra de 1973 (até a arte do M7).
const CORES: Dictionary = {
	"1973_renda": Color(0.97, 0.97, 0.92),
	"1973_cordel": Color(0.85, 0.75, 0.5),
	"1973_mascara": Color(0.95, 0.3, 0.6),
	"1973_tela": Color(0.3, 0.7, 0.9),
}

@export_enum("relato_curado", "noticia_jornal", "folheto_campanha", "depoimento_medico", "1973_renda", "1973_cordel", "1973_mascara", "1973_tela") var prova_id: String = "relato_curado"

var _tempo: float = 0.0
@onready var visual: Node2D = get_node_or_null("Visual")


static func nome_de(id: String) -> String:
	return NOMES.get(id, id)


## Ids das provas de uma fase (0 = 1904, 1 = 1973).
static func ids_da_fase(fase: int) -> Array[String]:
	return IDS_1973 if fase == GameState.FASE_1973 else IDS


func _ready() -> void:
	if GameState.tem_prova(prova_id):
		queue_free()
		return
	var papel := get_node_or_null("Visual/Papel") as ColorRect
	if papel and CORES.has(prova_id):
		papel.color = CORES[prova_id]


func _process(delta: float) -> void:
	_tempo += delta
	if visual:
		visual.position.y = round(sin(_tempo * 3.0) * 1.5)  # flutua de leve para chamar atenção


func interagir(jogador: Player) -> void:
	GameState.dar_prova(prova_id)
	coletada.emit(prova_id)
	get_tree().call_group("lista_provas", "atualizar")
	hide()
	set_deferred("monitorable", false)
	jogador.pode_mover = false
	await _mostrar(["Você pegou: %s." % nome_de(prova_id)])
	if is_instance_valid(jogador):
		jogador.pode_mover = true
	queue_free()


func _mostrar(linhas: Array[String]) -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.mostrar(linhas)
	else:
		print("\n".join(linhas))
