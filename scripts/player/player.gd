class_name Player
extends CharacterBody2D

@export var velocidade: float = 64.0
@onready var area_interacao: Area2D = $Interacao
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
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

func _process(_delta: float) -> void:
	_atualizar_animacao()
	# a área de interação fica sempre na frente do jogador
	area_interacao.position = direcao_olhando * 10.0 + Vector2(0.0, -6.0)


func _unhandled_input(event: InputEvent) -> void:
	if pode_mover and event.is_action_pressed("interagir"):
		_interagir()


func _interagir() -> void:
	var mais_perto: Area2D = null
	var menor_distancia := INF
	for alvo in area_interacao.get_overlapping_areas():
		if not alvo.is_in_group("interagivel") or not alvo.has_method("interagir"):
			continue
		var distancia := global_position.distance_to(alvo.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			mais_perto = alvo
	if mais_perto:
		mais_perto.interagir(self)
		
func _atualizar_animacao() -> void:
	var prefixo := "andar_" if velocity != Vector2.ZERO else "idle_"
	var sufixo := "baixo"
	if direcao_olhando.y < 0.0:
		sufixo = "cima"
		sprite.flip_h = false
	elif direcao_olhando.y > 0.0:
		sufixo = "baixo"
		sprite.flip_h = false
	else:
		sufixo = "lado"
		sprite.flip_h = direcao_olhando.x < 0.0
	var nome := prefixo + sufixo
	if not sprite.sprite_frames.has_animation(nome):
		nome = prefixo + "baixo"
	sprite.play(nome)
