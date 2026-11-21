extends CenaJogavel
## Fase 1904: mato, trilha e povoado de casas de taipa.
## [I1] mapa · [I9] montagem: liga na cena real o que os cards I2 a I8 fizeram
## (moradores, brigada, provas, boato, filtro sépia, HUD de tensão e fim da fase).

const LIMITES_MAPA: Rect2i = Rect2i(0, 0, 960, 640)  # 60 x 40 tiles de 16 px

const FALA_INTRO: Array[String] = [
	"Este é o lugar onde um dia vai existir a Unifor. Em 1904, é só mato: cajueiros, areia e uma trilha.",
	"Ali adiante fica um povoado. A brigada de vacinação chegou, e o povo está desconfiado.",
	"Converse com os moradores na ordem. O (!) mostra quem quer falar com você.",
	"Pegue as provas pela trilha: elas liberam respostas novas nas conversas.",
]

## Mostra a intro do ECO só na primeira entrada (sobrevive ao reinício da cena).
static var _intro_mostrada: bool = false
## Morador que reprovou por último, para o ECO repetir a dica no reinício (H6).
static var _ultimo_reprovado: String = ""

@export var hud: HudDialogo
@export var boato: BoatoCapital
@export var medico: Seguidor
@export var enfermeiro: Seguidor


func _ready() -> void:
	super._ready()
	jogador.definir_limites(LIMITES_MAPA)

	DialogoManager.tensao_inicial = 0
	DialogoManager.tensao_mudou.connect(hud.definir_tensao)
	DialogoManager.confianca_mudou.connect(hud.definir_confianca)
	boato.boato_disparou.connect(_on_boato)

	_ligar_moradores.call_deferred()
	_abertura.call_deferred()


func _exit_tree() -> void:
	DialogoManager.tensao_inicial = 0


func _ligar_moradores() -> void:
	for morador in get_tree().get_nodes_in_group("moradores"):
		morador.conversa_terminou.connect(_on_conversa_terminou)
	medico.seguir(jogador)
	_mandar_enfermeiro()


func _abertura() -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem == null:
		return
	jogador.pode_mover = false
	if not _intro_mostrada:
		_intro_mostrada = true
		await mensagem.eco(FALA_INTRO)
	elif _ultimo_reprovado != "" and GameState.dicas.has(_ultimo_reprovado):
		await mensagem.eco([
			"Vamos tentar de novo. Sobre %s:" % Morador.nome_de(_ultimo_reprovado),
			str(GameState.dicas[_ultimo_reprovado]),
		])
	if is_instance_valid(jogador):
		jogador.pode_mover = true


## A brigada vai até o morador da vez (o enfermeiro anda na frente com A*).
func _mandar_enfermeiro() -> void:
	if GameState.moradores_concluidos >= GameState.MORADORES.size():
		enfermeiro.parar()
		return
	var id: String = GameState.MORADORES[GameState.moradores_concluidos]
	for morador in get_tree().get_nodes_in_group("moradores"):
		if morador.morador_id == id:
			enfermeiro.ir_para(morador.global_position + Vector2(0, 24))
			return


func _on_conversa_terminou(morador_id: String, aprovado: bool) -> void:
	if aprovado:
		_ultimo_reprovado = ""
		_mandar_enfermeiro()
	else:
		_ultimo_reprovado = morador_id


## [I5] O boato deixa o povoado mais desconfiado: as próximas conversas começam com tensão.
func _on_boato(extra: float) -> void:
	DialogoManager.tensao_inicial = int(extra)
	hud.definir_tensao(int(extra))
