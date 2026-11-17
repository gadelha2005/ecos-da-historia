class_name Morador
extends StaticBody2D
## [I2] Morador da fase 1904. Só conversa na sua vez (GameState.morador_liberado).
## A ordem é GameState.MORADORES: Inácia → Dona Maria das Dores → Zé Tonico →
## Seu Anselmo → Seu Quintino → Dona Cotinha.
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
}

@export_enum("inacia", "dona_maria", "ze_tonico", "seu_anselmo", "seu_quintino", "dona_cotinha") var morador_id: String = "inacia"
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
	var caminho := "res://assets/sprites/fase1904/morador_%s.tres" % morador_id
	if not ResourceLoader.exists(caminho):
		return  # continua com o sprite provisório
	sprite.sprite_frames = load(caminho)
	sprite.modulate = Color.WHITE
	sprite.play("idle_baixo")


## A vez deste morador: liberado e ainda não concluído.
func e_a_vez() -> bool:
	return GameState.morador_liberado(morador_id) and not ja_concluido()


func ja_concluido() -> bool:
	return GameState.MORADORES.find(morador_id) < GameState.moradores_concluidos


func atualizar_indicador() -> void:
	indicador.visible = e_a_vez()


func interagir(jogador: Player) -> void:
	if _conversando:
		return
	_conversando = true
	jogador.pode_mover = false

	if ja_concluido():
		await _mostrar(["Obrigado pela conversa. Já decidi."], nome_de(morador_id))
	elif not GameState.morador_liberado(morador_id):
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
	var aprovado := AvaliadorConversa.avaliar(morador_id, dialogo, resultado)
	get_tree().call_group("moradores", "atualizar_indicador")
	conversa_terminou.emit(morador_id, aprovado)


func _proximo_da_fila() -> String:
	var i := clampi(GameState.moradores_concluidos, 0, GameState.MORADORES.size() - 1)
	return GameState.MORADORES[i]


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
