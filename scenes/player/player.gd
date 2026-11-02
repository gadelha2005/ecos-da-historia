class_name Player
extends CharacterBody2D

@export var velocidade: float = 64.0

var pode_mover: bool = true
var direcao_olhando: Vector2 = Vector2.DOWN


func _physics_process(_delta: float) -> void:
	if pode_mover:
		var direcao := _ler_direcao()
		if direcao != Vector2.ZERO:
			direcao_olhando = direcao
		velocity = direcao * velocidade
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _ler_direcao() -> Vector2:
	var x := Input.get_axis("mover_esquerda", "mover_direita")
	var y := Input.get_axis("mover_cima", "mover_baixo")
	if x != 0.0 and y != 0.0:
		# duas teclas ao mesmo tempo: segue na direção em que já estava indo
		return Vector2(x, 0.0) if direcao_olhando.x != 0.0 else Vector2(0.0, y)
	return Vector2(x, y)
