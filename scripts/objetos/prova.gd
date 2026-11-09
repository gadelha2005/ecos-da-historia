class_name Prova
extends Area2D
## [I4] Prova coletável da trilha (fase 1904).
## Ao interagir, registra em GameState (dar_prova) e some. Se o jogador já tem a prova
## (por exemplo, depois de reiniciar a fase), ela nem aparece: as provas não se perdem.

signal coletada(prova_id: String)

## Ordem e nomes das 4 provas da fase 1904 (ids usados no "exige_prova" dos diálogos).
const IDS: Array[String] = ["relato_curado", "noticia_jornal", "folheto_campanha", "depoimento_medico"]
const NOMES: Dictionary = {
	"relato_curado": "Relato de alguém curado",
	"noticia_jornal": "Notícia de jornal",
	"folheto_campanha": "Folheto da campanha",
	"depoimento_medico": "Depoimento de médico",
}

@export_enum("relato_curado", "noticia_jornal", "folheto_campanha", "depoimento_medico") var prova_id: String = "relato_curado"

var _tempo: float = 0.0
@onready var visual: Node2D = get_node_or_null("Visual")


static func nome_de(id: String) -> String:
	return NOMES.get(id, id)


func _ready() -> void:
	if GameState.tem_prova(prova_id):
		queue_free()


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
