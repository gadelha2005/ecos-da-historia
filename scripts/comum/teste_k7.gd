extends Node2D
## Teste do K7: aperte E (interagir) para a câmera ir até o Alvo em arco e voltar.

@onready var jogador: Player = $Player
@onready var alvo: Marker2D = $Alvo
@onready var camera: Camera2D = $Player/Camera2D

var _ocupado: bool = false


func _ready() -> void:
	var a := Vector2(0, 0)
	var c := Vector2(5, 10)
	var b := Vector2(10, 0)
	assert(CameraBezier.bezier(a, c, b, 0.0) == a, "t=0 começa em p0")
	assert(CameraBezier.bezier(a, c, b, 1.0) == b, "t=1 termina em p2")
	assert(CameraBezier.bezier(a, c, b, 0.5).is_equal_approx(Vector2(5, 5)), "t=0.5 passa por (5,5)")
	print("K7: matemática OK. Aperte E para a câmera ir até o alvo e voltar.")


func _unhandled_input(event: InputEvent) -> void:
	if _ocupado or not event.is_action_pressed("interagir"):
		return
	_ocupado = true
	jogador.pode_mover = false
	await CameraBezier.mover_para(camera, alvo.global_position, 1.5)
	await get_tree().create_timer(0.6).timeout
	await CameraBezier.voltar_ao_jogador(camera, 1.5)
	jogador.pode_mover = true
	_ocupado = false
	print("K7: voltou ao jogador.")
