extends CenaJogavel
## Teste do card J1: vitrine da arte da fase 1904.
## Monta um povoado de exemplo com os tiles (grama, areia com borda, terra batida, taipa),
## os 15 objetos, os 6 moradores e a brigada (alternando as direções a cada 1,5 s).
## Ande com o Catalisador para comparar o tamanho e o estilo.
##
## Atlas do tileset_1904.tres (coluna, linha) — a linha 0 segue o placeholder do I1:
##   (0,0)(6,0) areia · (1,0)(7,0) grama · (2,0)(5,2) terra batida · (3,0) mato denso
##   (4,0)(6,2) parede de taipa · (5,0) telhado de palha  (mato, taipa e telhado têm colisão)
##   borda grama/areia: (0,1) NO · (1,1) N · (2,1) NE · (0,2) O · (1,2) areia · (2,2) L
##                      (5,1) SO · (6,1) S · (7,1) SE · cantos internos (3,1)(4,1)(3,2)(4,2)

const SPRITES: String = "res://assets/sprites/fase1904/"
const OBJETOS: String = "res://assets/sprites/fase1904/objetos/"
const PERSONAGENS: Array[String] = [
	"morador_inacia", "morador_dona_maria", "morador_ze_tonico", "morador_seu_anselmo",
	"morador_seu_quintino", "morador_dona_cotinha", "brigada_medico", "brigada_enfermeiro",
]
const ANIMACOES: Array[String] = ["idle_baixo", "andar_baixo", "andar_lado", "andar_cima"]
const TAMANHO_MAPA: Vector2i = Vector2i(30, 17)  # em tiles de 16 px
const CLAREIRA: Rect2i = Rect2i(2, 1, 26, 14)    # areia cercada de grama

@export var chao: TileMapLayer

var _sprites: Array[AnimatedSprite2D] = []
var _tempo: float = 0.0
var _rnd := RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	jogador.definir_limites(Rect2i(Vector2i.ZERO, TAMANHO_MAPA * 16))
	_rnd.seed = 1904
	_pintar_chao()
	# casas, poço e carroça na parte de cima; vegetação nas bordas
	_colocar("casa_taipa_porta", Vector2(80, 96))
	_colocar("casa_taipa_janela", Vector2(160, 96))
	_colocar("poco", Vector2(232, 92))
	_colocar("carroca", Vector2(296, 92))
	_colocar("cerca", Vector2(352, 88))
	_colocar("barril", Vector2(388, 92))
	_colocar("caixote", Vector2(404, 92))
	_colocar("cajueiro_grande", Vector2(440, 100))
	_colocar("coqueiro_alto", Vector2(16, 120))
	_colocar("coqueiro_baixo", Vector2(464, 200))
	_colocar("cajueiro_pequeno", Vector2(40, 262))
	_colocar("moita", Vector2(200, 250))
	_colocar("arbusto_flores", Vector2(216, 252))
	_colocar("pedra", Vector2(330, 250))
	_colocar("tronco_caido", Vector2(380, 252))
	for i in PERSONAGENS.size():
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = load(SPRITES + PERSONAGENS[i] + ".tres")
		sprite.offset = Vector2(0, -16)
		sprite.position = Vector2(72 + i * 46, 150)
		sprite.play("idle_baixo")
		add_child(sprite)
		_sprites.append(sprite)


func _process(delta: float) -> void:
	_tempo += delta
	var anim := ANIMACOES[int(_tempo / 1.5) % ANIMACOES.size()]
	for sprite in _sprites:
		if sprite.animation != anim:
			sprite.play(anim)


func _pintar_chao() -> void:
	var x0 := CLAREIRA.position.x
	var y0 := CLAREIRA.position.y
	var x1 := CLAREIRA.end.x - 1
	var y1 := CLAREIRA.end.y - 1
	for y in TAMANHO_MAPA.y:
		for x in TAMANHO_MAPA.x:
			var tile := Vector2i(1 if _rnd.randf() < 0.6 else 7, 0)  # grama
			if CLAREIRA.has_point(Vector2i(x, y)):
				tile = _tile_clareira(x, y, x0, y0, x1, y1)
			chao.set_cell(Vector2i(x, y), 0, tile)
	# trilha de terra batida atravessando a clareira
	for x in range(x0 + 1, x1):
		chao.set_cell(Vector2i(x, 11), 0, Vector2i(2, 0) if _rnd.randf() < 0.6 else Vector2i(5, 2))
	# pedaço de muro de taipa
	for x in range(20, 24):
		chao.set_cell(Vector2i(x, 13), 0, Vector2i(6, 2) if x == 22 else Vector2i(4, 0))


func _tile_clareira(x: int, y: int, x0: int, y0: int, x1: int, y1: int) -> Vector2i:
	var cima := y == y0
	var baixo := y == y1
	var esq := x == x0
	var dir := x == x1
	if cima and esq: return Vector2i(0, 1)
	if cima and dir: return Vector2i(2, 1)
	if baixo and esq: return Vector2i(5, 1)
	if baixo and dir: return Vector2i(7, 1)
	if cima: return Vector2i(1, 1)
	if baixo: return Vector2i(6, 1)
	if esq: return Vector2i(0, 2)
	if dir: return Vector2i(2, 2)
	return Vector2i(1, 2) if _rnd.randf() < 0.7 else Vector2i(0 if _rnd.randf() < 0.5 else 6, 0)


func _colocar(nome: String, base: Vector2) -> void:
	# `base` é o ponto do chão (pé do objeto), igual aos personagens
	var sprite := Sprite2D.new()
	sprite.texture = load(OBJETOS + nome + ".png")
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	sprite.position = base
	add_child(sprite)
