class_name Morador
extends StaticBody2D
## [I2] Morador de uma fase. Só conversa na sua vez (GameState.npc_liberado).
## A ordem vem de GameState.SEQUENCIA[fase]. 1904: Inácia → Dona Maria das Dores →
## Zé Tonico → Seu Anselmo → Seu Quintino → Dona Cotinha. [L0] 1973: rendeira →
## cordelista → diretor de teatro → pintor → patrocinador.
## O corpo (StaticBody2D, camada 1) bloqueia o jogador; a área filha "Interacao"
## (camada 2, grupo interagivel) é o que o Player detecta (C4 procura Area2D).

signal conversa_terminou(morador_id: String, aprovado: bool)

const NOMES: Dictionary = {
	"inacia": "Inácia",
	"dona_maria": "Dona Maria das Dores",
	"ze_tonico": "Zé Tonico",
	"seu_anselmo": "Seu Anselmo",
	"seu_quintino": "Seu Quintino",
	"dona_cotinha": "Dona Cotinha",
	"comissao": "Comissão da Mostra",
	"rendeira": "Dona Socorro, rendeira",
	"cordelista": "Seu Firmino, cordelista",
	"diretor_teatro": "Lúcia, diretora de teatro",
	"pintor": "Professor Aurélio, pintor",
	"patrocinador": "Dr. Valdemar, patrocinador",
}

## Fala do morador quando a tensão estoura (chega a 100).
const FALA_TENSAO: String = "Chega! Não quero mais conversa!"

## Pasta da arte de cada fase (assets/sprites/<pasta>/morador_<id>.tres).
const PASTA_ARTE: Array[String] = ["fase1904", "fase1973", "fase1979", "fase1982"]

## Fase deste morador (0 = 1904, 1 = 1973...). Define a ordem das conversas.
@export_enum("1904", "1973", "1979", "1982") var fase: int = 0
## Id do morador (precisa estar em GameState.SEQUENCIA[fase]).
@export var morador_id: String = "inacia"
## Caminho do JSON do diálogo deste morador (data/dialogos/<id>.json).
@export_file("*.json") var dialogo: String = ""
## Mostra o nome acima da cabeça (útil em testes).
@export var mostrar_nome: bool = false
## Tom do sprite provisório (até a arte dos moradores do J1 entrar).
@export var cor_placeholder: Color = Color.WHITE

var _conversando: bool = false
var _tempo: float = 0.0

@onready var indicador: Label = $Indicador
@onready var rotulo_nome: Label = $Nome
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


static func nome_de(id: String) -> String:
	return NOMES.get(id, id)


func _ready() -> void:
	add_to_group("moradores")
	rotulo_nome.text = nome_de(morador_id)
	rotulo_nome.visible = mostrar_nome
	sprite.modulate = cor_placeholder
	_carregar_arte()
	atualizar_indicador()


func _process(delta: float) -> void:
	if indicador.visible:
		_tempo += delta
		indicador.position.y = -56.0 + round(sin(_tempo * 4.0) * 1.5)


## [J1] Usa a arte do morador (assets/sprites/fase1904/morador_<id>.tres) quando ela existe.
func _carregar_arte() -> void:
	var caminho := "res://assets/sprites/%s/morador_%s.tres" % [PASTA_ARTE[fase], morador_id]
	if not ResourceLoader.exists(caminho):
		return  # continua com o sprite provisório
	sprite.sprite_frames = load(caminho)
	sprite.modulate = Color.WHITE
	sprite.play("idle_baixo")


## A vez deste morador: liberado e ainda não concluído.
func e_a_vez() -> bool:
	return GameState.npc_liberado(fase, morador_id) and not ja_concluido()


func ja_concluido() -> bool:
	return GameState.npc_concluido(fase, morador_id)


func atualizar_indicador() -> void:
	indicador.visible = e_a_vez()


func interagir(jogador: Player) -> void:
	if _conversando:
		return
	_conversando = true
	jogador.pode_mover = false

	if ja_concluido():
		await _mostrar(["Obrigado pela conversa. Já decidi."], nome_de(morador_id))
	elif not GameState.npc_liberado(fase, morador_id):
		await _mostrar(["Ainda não é a minha vez."], nome_de(morador_id))
		await _eco(["Procure %s primeiro." % nome_de(_proximo_da_fila())])
	else:
		await _conversar()

	_conversando = false
	if is_instance_valid(jogador):
		jogador.pode_mover = true


func _conversar() -> void:
	if not ResourceLoader.exists(dialogo):
		print("Ainda não existe: ", dialogo)
		return
	var resultado: Dictionary = await DialogoManager.iniciar(dialogo)
	if resultado.get("falhou", false) and DialogoManager.tensao >= DialogoManager.LIMITE_TENSAO:
		await _tensao_estourou()
	var aprovado := AvaliadorConversa.avaliar(morador_id, dialogo, resultado, fase)
	get_tree().call_group("moradores", "atualizar_indicador")
	conversa_terminou.emit(morador_id, aprovado)


## A tensão chegou ao máximo: o morador encerra a conversa irritado e o ECO explica.
func _tensao_estourou() -> void:
	await _mostrar([FALA_TENSAO], nome_de(morador_id))
	await _eco(["A tensão chegou ao limite e a conversa acabou. Respostas autoritárias irritam as pessoas."])


func _proximo_da_fila() -> String:
	var fila: Array = GameState.SEQUENCIA[fase]
	var i := clampi(GameState.npcs_concluidos[fase], 0, fila.size() - 1)
	return fila[i]


func _mostrar(linhas: Array[String], falante: String = "") -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.mostrar(linhas, falante)
	else:
		print(("%s: " % falante if falante != "" else "") + "\n".join(linhas))


func _eco(linhas: Array[String]) -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.eco(linhas)
	else:
		print("ECO: " + "\n".join(linhas))
