extends CenaJogavel
## Fase 1979: a disputa de terras na mata ao lado da Unifor (Capítulo 3 da Narrativa).
## [L1] mapa · [L10] montagem: professor de Direito (mediador), 6 conversas alternando
## comunidade e empreendimento (L3/L4), provas (L5), confiança dos dois lados (L2),
## tensão que passa de uma conversa para a outra, máquinas ligando (L7),
## mesa de acordo (L6) e fim com a Chave do Meio Ambiente (L9).

const LIMITES_MAPA: Rect2i = Rect2i(0, 0, 640, 400)
const CENA_MESA: String = "res://scenes/ui/mesa_acordo.tscn"
const CENA_FASE: String = "res://scenes/fases/fase_1979.tscn"

const FALA_INTRO: Array[String] = [
	"O portal verde nos trouxe para a mata ao lado da Unifor, em 1979.",
	"Árvores altas, uma lagoa pequena... e uma cerca nova cortando o terreno. Do outro lado, uma placa de loteamento.",
]
const FALA_JOVEM: String = "As máquinas chegaram! Elas estão do outro lado da cerca!"
const FALA_INTRO_2: Array[String] = [
	"A disputa de terras está prestes a virar confronto. Procure o professor de Direito, embaixo da árvore grande.",
	"Junte as provas pelo mapa: cada uma pesa para um lado. E cuidado: aqui a tensão passa de uma conversa para a outra.",
]
const FALA_ROMPEU: String = "As máquinas voltaram a ligar e a negociação rompeu. Ninguém quer mais sentar à mesa."

static var _intro_mostrada: bool = false
static var _dica_reinicio: String = ""

@export var hud: HudDialogo
@export var professor: Comissao
@export var fim: FimFase1979
@export var maquinas: MaquinasLigando

var _rompendo: bool = false


func _ready() -> void:
	super._ready()
	jogador.definir_limites(LIMITES_MAPA)

	DialogoManager.tensao_inicial = GameState.tensao_fase
	DialogoManager.tensao_mudou.connect(_on_tensao_mudou)
	DialogoManager.confianca_mudou.connect(hud.definir_confianca)
	hud.definir_tensao(GameState.tensao_fase)
	professor.planta_pedida.connect(_abrir_mesa)
	maquinas.maquinas_ligaram.connect(hud.definir_tensao)
	maquinas.negociacao_rompeu.connect(_romper.bind(""))

	_ligar_moradores.call_deferred()
	_abertura.call_deferred()


## A tensão da conversa vira a tensão da fase e é o ponto de partida da próxima conversa.
func _on_tensao_mudou(valor: int) -> void:
	GameState.tensao_fase = valor
	DialogoManager.tensao_inicial = valor
	hud.definir_tensao(valor)


func _ligar_moradores() -> void:
	for morador in get_tree().get_nodes_in_group("moradores"):
		if morador != professor:
			morador.conversa_terminou.connect(_on_conversa_terminou)


func _abertura() -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem == null:
		return
	jogador.pode_mover = false
	if not _intro_mostrada:
		_intro_mostrada = true
		await mensagem.eco(FALA_INTRO)
		await mensagem.mostrar([FALA_JOVEM], Morador.nome_de("jovem"))
		await mensagem.eco(FALA_INTRO_2)
	elif _dica_reinicio != "":
		await mensagem.eco(["Vamos tentar de novo, com o que aprendemos sobre os dois lados.", _dica_reinicio])
		_dica_reinicio = ""
	if is_instance_valid(jogador):
		jogador.pode_mover = true


func _on_conversa_terminou(morador_id: String, aprovado: bool) -> void:
	if aprovado:
		maquinas.adiar()
		return
	var dica: String = str(GameState.dicas.get(morador_id, ""))
	_dica_reinicio = "Sobre %s: %s" % [Morador.nome_de(morador_id), dica] if dica != "" else ""


## [L6] Todos foram ouvidos: o professor chama os dois lados para a mesa.
func _abrir_mesa() -> void:
	jogador.pode_mover = false
	maquinas.ativa = false
	var mesa: MesaAcordo = load(CENA_MESA).instantiate()
	add_child(mesa)
	var resultado: Dictionary = await mesa.montar()
	GameState.tensao_fase = int(resultado.get("tensao", GameState.tensao_fase))
	hud.definir_tensao(GameState.tensao_fase)
	if resultado["aprovado"]:
		fim.concluir()
		return
	_romper(str(resultado.get("dica", "")))


## [N3.R] A negociação rompe: tensão no máximo ou um lado saiu insatisfeito da mesa.
func _romper(dica: String) -> void:
	if _rompendo:
		return
	_rompendo = true
	jogador.pode_mover = false
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.mostrar([FALA_ROMPEU], Morador.nome_de("professor"))
	_dica_reinicio = dica if dica != "" else "Respostas autoritárias e o barulho das máquinas esquentam tudo. Converse com calma e alterne os lados."
	GameState.reiniciar_fase(GameState.FASE_1979)
	SceneManager.trocar_cena(CENA_FASE, "Spawn_Inicio")


func _exit_tree() -> void:
	DialogoManager.tensao_inicial = 0
