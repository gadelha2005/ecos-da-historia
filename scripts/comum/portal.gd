class_name Portal
extends Area2D
## [D3 + K2] Portal das épocas. Três estados visuais:
##   TRANCADO  -> cinza e parado
##   ATIVO     -> gira e ondula com a cor da época (shader portal_distorcao)
##   CONCLUIDO -> chave da época já pega: brilho fraco, girando devagar e bloqueado
##                (a fase já passada não pode ser jogada de novo)
## No hub, o portal da próxima época só "acende" quando a chave anterior é encaixada
## na porta (o HubEventos do K8 chama acender()); a interação continua seguindo
## GameState.portal_liberado. Portais de volta (sempre_aberto) ficam sempre ativos.

signal estado_mudou(estado: int)

enum Estado { TRANCADO, ATIVO, CONCLUIDO }

## Cores das épocas (as mesmas da arte das chaves do K9): 1904, 1973, 1979, 1982.
const CORES: Array[Color] = [
	Color(0.85, 0.2, 0.2),    # 1904 Saúde: vermelho
	Color(0.82, 0.2, 0.7),    # 1973 Cultura: magenta
	Color(0.2, 0.65, 0.27),   # 1979 Meio ambiente: verde
	Color(0.95, 0.75, 0.2),   # 1982 Educação: dourado
]
const COR_TRANCADO := Color(0.42, 0.42, 0.45)

@export_range(0, 3) var fase: int = 0
@export_file("*.tscn") var cena_destino: String = ""
@export var spawn_destino: String = ""
@export var sempre_aberto: bool = false   # usado nos portais de volta
## Cor dos portais de volta (sempre_aberto).
@export var cor_volta: Color = Color(0.55, 0.8, 1.0)

var estado: Estado = Estado.TRANCADO
var _tween: Tween

@onready var sprite: Sprite2D = $Sprite
@onready var material_portal: ShaderMaterial = sprite.material


func _ready() -> void:
	sprite.material = material_portal.duplicate()  # cada portal com seus próprios parâmetros
	material_portal = sprite.material
	atualizar_estado()


## Lê o GameState e mostra o estado certo, sem animação.
func atualizar_estado() -> void:
	if sempre_aberto:
		_aplicar(Estado.ATIVO)
	elif GameState.tem_chave(fase):
		_aplicar(Estado.CONCLUIDO)
	elif _aceso_no_hub():
		_aplicar(Estado.ATIVO)
	else:
		_aplicar(Estado.TRANCADO)


## Animação de trancado para ativo (usada na volta ao hub). Use com await.
func acender() -> void:
	if estado == Estado.ATIVO:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(sprite, "scale", Vector2(0.7, 0.7), 0.15)
	_tween.tween_property(sprite, "modulate", Color(2, 2, 2), 0.1)
	_tween.tween_callback(_aplicar.bind(Estado.ATIVO))
	_tween.tween_property(sprite, "scale", Vector2(1.35, 1.35), 0.2).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(sprite, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_method(_definir_intensidade, 0.0, 1.0, 0.8)
	await _tween.finished


## Fala do portal de uma época que já foi concluída (chave pega): não deixa entrar de novo.
const FALA_CONCLUIDO: Array[String] = [
	"Este eco já foi recuperado. A chave desta época está com você.",
	"Siga para o próximo portal aceso.",
]


func interagir(jogador: Player) -> void:
	jogador.pode_mover = false
	if not sempre_aberto and GameState.tem_chave(fase):
		await _mostrar(FALA_CONCLUIDO)
		jogador.pode_mover = true
	elif sempre_aberto or GameState.portal_liberado(fase):
		if not _ir_para(cena_destino, spawn_destino):
			jogador.pode_mover = true  # a cena ainda não existe: não deixa o jogador travado
	else:
		await _mostrar(["Ainda trancado."])
		jogador.pode_mover = true


func cor() -> Color:
	return cor_volta if sempre_aberto else CORES[fase]


## Visual "aceso": liberado e, depois da primeira época, só quando a chave anterior
## já foi encaixada na porta (assim o K8 pode acendê-lo com animação na volta ao hub).
func _aceso_no_hub() -> bool:
	if not GameState.portal_liberado(fase):
		return false
	return fase == 0 or GameState.chaves_encaixadas[fase - 1]


func _aplicar(novo: Estado) -> void:
	estado = novo
	match novo:
		Estado.TRANCADO:
			sprite.modulate = COR_TRANCADO
			_definir_intensidade(0.0)
			material_portal.set_shader_parameter("brilho", 0.8)
		Estado.ATIVO:
			sprite.modulate = cor()
			_definir_intensidade(1.0)
			material_portal.set_shader_parameter("brilho", 1.25)
		Estado.CONCLUIDO:
			sprite.modulate = Color(cor(), 0.75)
			_definir_intensidade(0.25)
			material_portal.set_shader_parameter("brilho", 0.8)
	estado_mudou.emit(novo)


func _definir_intensidade(valor: float) -> void:
	material_portal.set_shader_parameter("intensidade", valor)


func _ir_para(caminho: String, spawn: String = "") -> bool:
	if ResourceLoader.exists(caminho):
		SceneManager.trocar_cena(caminho, spawn)
		return true
	print("Ainda não existe: ", caminho)
	return false


func _mostrar(linhas: Array[String]) -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.mostrar(linhas)
	else:
		print("\n".join(linhas))
