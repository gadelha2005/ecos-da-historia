extends CenaJogavel
## Fase 1973: a primeira Mostra de Cultura no campus recém-criado da Unifor.
## [M1] mapa · [M9] montagem: comissão, 5 defensores em ordem (M2/M3), amostras (M4),
## planta da Mostra (M5) e fim com a Chave da Cultura (M8).

const LIMITES_MAPA: Rect2i = Rect2i(0, 0, 640, 400)
const CENA_PLANTA: String = "res://scenes/ui/planta_mostra.tscn"
const CENA_FASE: String = "res://scenes/fases/fase_1973.tscn"

const FALA_INTRO: Array[String] = [
	"Estamos de novo no terreno da Unifor, agora em 1973. A universidade acaba de nascer: prédios novos e obra por todo lado.",
	"Olhe o cartaz no pátio: vai acontecer a primeira Mostra de Cultura da universidade.",
	"Fale primeiro com a comissão da Mostra, perto do cartaz. O (!) mostra quem quer falar com você.",
	"Pelo campus há amostras de cultura. Elas liberam respostas novas nas conversas.",
]

## Mostra a intro do ECO só na primeira entrada (sobrevive ao reinício da cena).
static var _intro_mostrada: bool = false
## Dica que o ECO repete depois de um reinício (conversa reprovada ou planta recusada).
static var _dica_reinicio: String = ""

@export var hud: HudDialogo
@export var comissao: Comissao
@export var fim: FimFase1973


func _ready() -> void:
	super._ready()
	jogador.definir_limites(LIMITES_MAPA)

	DialogoManager.tensao_inicial = 0
	DialogoManager.tensao_mudou.connect(hud.definir_tensao)
	DialogoManager.confianca_mudou.connect(hud.definir_confianca)
	comissao.planta_pedida.connect(_abrir_planta)

	_ligar_moradores.call_deferred()
	_abertura.call_deferred()


func _ligar_moradores() -> void:
	for morador in get_tree().get_nodes_in_group("moradores"):
		if morador != comissao:
			morador.conversa_terminou.connect(_on_conversa_terminou)


func _abertura() -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem == null:
		return
	jogador.pode_mover = false
	if not _intro_mostrada:
		_intro_mostrada = true
		await mensagem.eco(FALA_INTRO)
	elif _dica_reinicio != "":
		await mensagem.eco(["Vamos tentar de novo.", _dica_reinicio])
		_dica_reinicio = ""
	if is_instance_valid(jogador):
		jogador.pode_mover = true


func _on_conversa_terminou(morador_id: String, aprovado: bool) -> void:
	if not aprovado:
		var dica: String = str(GameState.dicas.get(morador_id, ""))
		_dica_reinicio = "Sobre %s: %s" % [Morador.nome_de(morador_id), dica] if dica != "" else ""


## [M5] A comissão pede a planta final. Sucesso → fim (M8); senão reinício N2.R.
func _abrir_planta() -> void:
	jogador.pode_mover = false
	var planta: PlantaMostra = load(CENA_PLANTA).instantiate()
	add_child(planta)
	var resultado: Dictionary = await planta.montar()
	if resultado["aprovado"]:
		fim.concluir()
		return

	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.mostrar(["Assim a Mostra fica pobre. Vamos refazer o plano desde o começo do dia."], "Comissão da Mostra")
	_dica_reinicio = str(resultado.get("dica", ""))
	GameState.reiniciar_fase(GameState.FASE_1973)
	SceneManager.trocar_cena(CENA_FASE, "Spawn_Inicio")


func _exit_tree() -> void:
	DialogoManager.tensao_inicial = 0
