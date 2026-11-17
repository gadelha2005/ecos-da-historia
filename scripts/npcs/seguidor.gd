class_name Seguidor
extends CharacterBody2D
## [I6] NPC que anda sozinho pelo mapa (médico e enfermeiro da brigada).
## Usa AStarGrid2D numa grade de 16x16. Os obstáculos vêm do mapa: toda célula onde existe
## um corpo de colisão na camada 1 (tiles com colisão, casas, árvores, moradores) fica sólida.
##
## Uso:
##   seguidor.ir_para(destino)        # vai até um ponto (ex.: a posição de um morador)
##   seguidor.seguir(jogador)         # vai atrás de um nó, mantendo distância
##   seguidor.parar()
## Se o destino estiver dentro de um obstáculo (ex.: o próprio morador), ele para na
## célula livre mais próxima.

signal chegou
signal caminho_calculado(pontos: PackedVector2Array)

const TAMANHO_CELULA: int = 16

## Área do mapa (em pixels) onde a grade é montada. Vazia = usa a área de `mapa`.
@export var area: Rect2i = Rect2i()
## Mapa de onde tirar a área automaticamente (opcional).
@export var mapa: TileMapLayer
## Camadas de física que contam como obstáculo.
@export_flags_2d_physics var camadas_obstaculo: int = 1
@export var velocidade: float = 56.0
## Distância que mantém de quem está seguindo.
@export var distancia_seguir: float = 24.0
## Visual do NPC (ex.: assets/sprites/fase1904/brigada_medico.tres do J1).
@export var frames: SpriteFrames

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var astar: AStarGrid2D = AStarGrid2D.new()
var caminho: PackedVector2Array = PackedVector2Array()
var direcao_olhando: Vector2 = Vector2.DOWN

var _pronto: bool = false
var _destino_pendente: Variant = null
var _alvo: Node2D = null
var _ultima_celula_alvo: Vector2i = Vector2i(-99999, -99999)
var _tempo_repath: float = 0.0


func _ready() -> void:
	if frames:
		sprite.sprite_frames = frames
	# os corpos de colisão do mapa só existem no espaço de física depois de um quadro
	await get_tree().physics_frame
	await get_tree().physics_frame
	atualizar_grade()
	_pronto = true
	if _destino_pendente != null:
		ir_para(_destino_pendente)


## Monta (ou remonta) a grade a partir dos obstáculos que estão no mapa agora.
func atualizar_grade() -> void:
	var regiao := _regiao_em_celulas()
	astar.region = regiao
	astar.cell_size = Vector2(TAMANHO_CELULA, TAMANHO_CELULA)
	astar.offset = Vector2(TAMANHO_CELULA, TAMANHO_CELULA) / 2.0  # pontos no centro da célula
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()

	var espaco := get_world_2d().direct_space_state
	var forma := RectangleShape2D.new()
	forma.size = Vector2(TAMANHO_CELULA - 4, TAMANHO_CELULA - 4)
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.collision_mask = camadas_obstaculo
	consulta.exclude = [get_rid()]
	for y in range(regiao.position.y, regiao.end.y):
		for x in range(regiao.position.x, regiao.end.x):
			var celula := Vector2i(x, y)
			consulta.transform = Transform2D(0.0, _centro(celula))
			for colisao in espaco.intersect_shape(consulta, 4):
				if _conta_como_obstaculo(colisao["collider"]):
					astar.set_point_solid(celula)
					break


## Calcula o caminho até `destino` (posição global) e começa a andar.
func ir_para(destino: Vector2) -> void:
	_alvo = null
	_ir(destino)


## Vai atrás de `alvo` (ex.: o jogador) até chamar parar() ou ir_para().
func seguir(alvo: Node2D) -> void:
	_alvo = alvo
	_ultima_celula_alvo = Vector2i(-99999, -99999)
	_tempo_repath = 0.0


func parar() -> void:
	_alvo = null
	caminho = PackedVector2Array()
	velocity = Vector2.ZERO


func esta_andando() -> bool:
	return not caminho.is_empty()


func celula_de(posicao: Vector2) -> Vector2i:
	return Vector2i((posicao / TAMANHO_CELULA).floor())


func _ir(destino: Vector2) -> void:
	if not _pronto:
		_destino_pendente = destino
		return
	_destino_pendente = null
	var inicio := _celula_livre_perto(celula_de(global_position))
	var fim := celula_de(destino)
	if not astar.is_in_boundsv(inicio) or not astar.is_in_boundsv(fim):
		push_warning("Seguidor: destino fora do mapa " + str(destino))
		return
	# allow_partial_path: se o destino for sólido/inalcançável, chega o mais perto possível
	caminho = astar.get_point_path(inicio, fim, true)
	if not caminho.is_empty() and caminho[0].distance_to(global_position) < TAMANHO_CELULA:
		caminho.remove_at(0)  # já está na primeira célula
	caminho_calculado.emit(caminho)


func _physics_process(delta: float) -> void:
	if _alvo != null and is_instance_valid(_alvo) and _pronto:
		_atualizar_seguir(delta)

	if caminho.is_empty():
		velocity = Vector2.ZERO
	else:
		var proximo := caminho[0]
		var falta := proximo - global_position
		if falta.length() <= velocidade * delta + 0.5:
			global_position = proximo
			caminho.remove_at(0)
			velocity = Vector2.ZERO
			if caminho.is_empty() and _alvo == null:
				chegou.emit()
		else:
			velocity = falta.normalized() * velocidade
			direcao_olhando = _direcao_principal(falta)
	move_and_slide()
	_atualizar_animacao()


func _atualizar_seguir(delta: float) -> void:
	var perto := global_position.distance_to(_alvo.global_position) <= distancia_seguir
	if perto:
		caminho = PackedVector2Array()
		return
	_tempo_repath -= delta
	var celula_alvo := celula_de(_alvo.global_position)
	if _tempo_repath <= 0.0 and (celula_alvo != _ultima_celula_alvo or caminho.is_empty()):
		_tempo_repath = 0.3
		_ultima_celula_alvo = celula_alvo
		_ir(_alvo.global_position)


func _celula_livre_perto(celula: Vector2i) -> Vector2i:
	if not astar.is_in_boundsv(celula) or not astar.is_point_solid(celula):
		return celula
	for raio in range(1, 4):
		for dy in range(-raio, raio + 1):
			for dx in range(-raio, raio + 1):
				var c := celula + Vector2i(dx, dy)
				if astar.is_in_boundsv(c) and not astar.is_point_solid(c):
					return c
	return celula


func _conta_como_obstaculo(corpo: Object) -> bool:
	if corpo == null or corpo == self:
		return false
	if corpo is Node and ((corpo as Node).is_in_group("jogador") or corpo is Seguidor):
		return false  # quem anda não vira parede
	return true


func _regiao_em_celulas() -> Rect2i:
	if area.has_area():
		return Rect2i(area.position / TAMANHO_CELULA, area.size / TAMANHO_CELULA)
	if mapa:
		return mapa.get_used_rect()
	push_warning("Seguidor sem área nem mapa: usando 40x24 células.")
	return Rect2i(0, 0, 40, 24)


func _centro(celula: Vector2i) -> Vector2:
	return Vector2(celula * TAMANHO_CELULA) + Vector2(TAMANHO_CELULA, TAMANHO_CELULA) / 2.0


func _direcao_principal(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2(signf(v.x), 0.0)
	return Vector2(0.0, signf(v.y))


func _atualizar_animacao() -> void:
	if sprite.sprite_frames == null:
		return
	var prefixo := "andar_" if velocity != Vector2.ZERO else "idle_"
	var sufixo := "baixo"
	sprite.flip_h = false
	if direcao_olhando.y < 0.0:
		sufixo = "cima"
	elif direcao_olhando.x != 0.0:
		sufixo = "lado"
		sprite.flip_h = direcao_olhando.x < 0.0
	var nome := prefixo + sufixo
	if not sprite.sprite_frames.has_animation(nome):
		nome = prefixo + "baixo" if sprite.sprite_frames.has_animation(prefixo + "baixo") else "idle"
	if sprite.animation != nome:
		sprite.play(nome)
