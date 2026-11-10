class_name CameraBezier
extends RefCounted
## [K7] Movimento de câmera em arco (curva de Bézier quadrática).
## Uso (dentro de uma função com await):
##   await CameraBezier.mover_para(camera, porta.global_position, 1.5)
##   await CameraBezier.voltar_ao_jogador(camera, 1.5)
## Durante o trajeto a suavização e os limites da câmera ficam desligados e voltam ao
## normal no fim. Se o alvo estiver perto da borda do mapa, a câmera pode se ajustar
## aos limites quando eles voltam. O jogador deve estar travado (pode_mover = false).

const SEM_LIMITE: int = 10000000


# B(t) = (1-t)² p0 + 2(1-t)t p1 + t² p2, com t de 0 a 1.
static func bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2


# Leva a câmera até `alvo` (posição global) em `duracao` segundos, fazendo um arco para cima.
# `arco` é a altura do arco como fração da distância percorrida.
static func mover_para(camera: Camera2D, alvo: Vector2, duracao: float, arco: float = 0.25) -> void:
	var inicio := camera.global_position
	var controle := (inicio + alvo) * 0.5 + Vector2(0.0, -inicio.distance_to(alvo) * arco)

	var suave := camera.position_smoothing_enabled
	var limites := [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom]
	camera.position_smoothing_enabled = false
	camera.limit_left = -SEM_LIMITE
	camera.limit_top = -SEM_LIMITE
	camera.limit_right = SEM_LIMITE
	camera.limit_bottom = SEM_LIMITE

	var tween := camera.create_tween()
	tween.tween_method(
		func(t: float) -> void: camera.global_position = bezier(inicio, controle, alvo, t),
		0.0, 1.0, duracao
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	camera.global_position = alvo
	camera.limit_left = limites[0]
	camera.limit_top = limites[1]
	camera.limit_right = limites[2]
	camera.limit_bottom = limites[3]
	camera.position_smoothing_enabled = suave


# Traz a câmera de volta para o jogador (o pai da câmera) e a deixa encaixada nele de novo.
static func voltar_ao_jogador(camera: Camera2D, duracao: float, arco: float = 0.25) -> void:
	var jogador := camera.get_parent() as Node2D
	await mover_para(camera, jogador.global_position, duracao, arco)
	camera.position = Vector2.ZERO
