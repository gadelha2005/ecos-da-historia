extends Node2D
## Teste do card K9: as 4 chaves e as fechaduras no zoom 4 (filtro Nearest do projeto).
## Linha de cima: chaves (16x16). Embaixo: uma porta 32x48 como a do K3, com as fechaduras (8x8)
## nas mesmas posições; a cada 1 s uma chave "entra" e a fechadura troca para a versão cheia.

const PASTA: String = "res://assets/sprites/hub/chaves/"
const ZONAS: Array[String] = ["saude", "cultura", "ambiente", "educacao"]

var _fechaduras: Array[Sprite2D] = []
var _proxima: int = 0


func _ready() -> void:
	var camera := Camera2D.new()
	camera.zoom = Vector2(4, 4)
	camera.position = Vector2(0, 8)
	add_child(camera)

	var fundo := ColorRect.new()
	fundo.color = Color(0.86, 0.84, 0.78)
	fundo.position = Vector2(-160, -100)
	fundo.size = Vector2(320, 200)
	add_child(fundo)

	for i in ZONAS.size():
		var chave := Sprite2D.new()
		chave.texture = load(PASTA + "chave_%s.png" % ZONAS[i])
		chave.position = Vector2(-60 + i * 40, -30)
		add_child(chave)

	var porta := ColorRect.new()  # mesma medida da porta do K3
	porta.color = Color(0.45, 0.33, 0.22)
	porta.position = Vector2(-16, 0)
	porta.size = Vector2(32, 48)
	add_child(porta)
	for i in 4:
		var f := Sprite2D.new()
		f.texture = load(PASTA + "fechadura_vazia.png")
		f.position = Vector2(-12 + i * 8, 20)  # posições do K3 (Fechaduras em y -20 da porta)
		add_child(f)
		_fechaduras.append(f)

	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_encaixar_proxima)
	add_child(timer)


func _encaixar_proxima() -> void:
	if _proxima >= 4:
		for f in _fechaduras:
			f.texture = load(PASTA + "fechadura_vazia.png")
		_proxima = 0
		return
	_fechaduras[_proxima].texture = load(PASTA + "fechadura_%s.png" % ZONAS[_proxima])
	_proxima += 1
