extends CenaJogavel
## Teste do card I6: NPCs andando com AStarGrid2D.
## - Clique no mapa: o enfermeiro vai até lá contornando paredes, casas e árvores.
## - O médico segue o Catalisador (ande com as setas/WASD).
## A linha amarela mostra o caminho calculado pelo A*.

const TILE_PAREDE: Vector2i = Vector2i(1, 0)  # tile com colisão do tileset do hub
const TAMANHO: Vector2i = Vector2i(30, 17)

@export var obstaculos: TileMapLayer
@export var medico: Seguidor
@export var enfermeiro: Seguidor
@export var linha_caminho: Line2D
@export var marcador: Node2D


func _ready() -> void:
	super._ready()
	jogador.definir_limites(Rect2i(Vector2i.ZERO, TAMANHO * 16))
	_montar_paredes()
	enfermeiro.caminho_calculado.connect(_mostrar_caminho)
	enfermeiro.chegou.connect(func(): marcador.visible = false)
	medico.seguir(jogador)


func _montar_paredes() -> void:
	# borda do mapa
	for x in TAMANHO.x:
		obstaculos.set_cell(Vector2i(x, 0), 0, TILE_PAREDE)
		obstaculos.set_cell(Vector2i(x, TAMANHO.y - 1), 0, TILE_PAREDE)
	for y in TAMANHO.y:
		obstaculos.set_cell(Vector2i(0, y), 0, TILE_PAREDE)
		obstaculos.set_cell(Vector2i(TAMANHO.x - 1, y), 0, TILE_PAREDE)
	# muros em "U" e "L" para obrigar o caminho a dar a volta
	for y in range(3, 12):
		obstaculos.set_cell(Vector2i(9, y), 0, TILE_PAREDE)
	for x in range(9, 16):
		obstaculos.set_cell(Vector2i(x, 11), 0, TILE_PAREDE)
	for y in range(5, 15):
		obstaculos.set_cell(Vector2i(20, y), 0, TILE_PAREDE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var destino := get_global_mouse_position()
		marcador.global_position = destino
		marcador.visible = true
		enfermeiro.ir_para(destino)


func _process(_delta: float) -> void:
	# a linha acompanha o enfermeiro enquanto ele anda
	if enfermeiro.esta_andando():
		var pontos := PackedVector2Array([enfermeiro.global_position])
		pontos.append_array(enfermeiro.caminho)
		linha_caminho.points = pontos
	else:
		linha_caminho.points = PackedVector2Array()


func _mostrar_caminho(pontos: PackedVector2Array) -> void:
	print("Caminho do enfermeiro: %d pontos" % pontos.size())
