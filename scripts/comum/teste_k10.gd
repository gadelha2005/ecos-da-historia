extends Node2D
## Teste do card K10: objetos coloridos das zonas do laboratório dentro do hub.
## Coloca a maca, o armário de remédios e a cruz na Zona_Saude, e os quadros e o mural na
## Zona_Cultura. Se o filtro de cor do K1 existir (scenes/hub/filtro_cor.tscn), tudo começa
## cinza e cada zona ganha cor em sequência (teclas 1-4 também animam; 0 volta ao cinza).

const HUB: String = "res://scenes/hub/hub.tscn"
const FILTRO_K1: String = "res://scenes/hub/filtro_cor.tscn"
const PASTA: String = "res://assets/sprites/hub/zonas/"
## nome do arquivo -> posição no hub (ponto de apoio no chão / na parede)
const OBJETOS: Dictionary = {
	"saude_armario_remedios": Vector2(48, 72),
	"saude_cruz_parede": Vector2(120, 40),
	"saude_maca": Vector2(104, 120),
	"saude_maca#2": Vector2(200, 120),
	"cultura_quadro_retrato": Vector2(360, 40),
	"cultura_quadro_paisagem": Vector2(396, 40),
	"cultura_mural": Vector2(488, 56),
	"cultura_quadro_abstrato": Vector2(576, 40),
}

var _filtro: Node = null


func _ready() -> void:
	var hub: Node2D = load(HUB).instantiate()
	add_child(hub)
	for chave in OBJETOS:
		var sprite := Sprite2D.new()
		sprite.texture = load(PASTA + String(chave).get_slice("#", 0) + ".png")
		sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
		sprite.position = OBJETOS[chave]
		hub.add_child(sprite)

	var camera := Camera2D.new()  # mostra o hub inteiro (640x384)
	camera.position = Vector2(320, 192)
	camera.zoom = Vector2(2.8, 2.8)
	add_child(camera)
	camera.make_current()

	if ResourceLoader.exists(FILTRO_K1):
		_filtro = load(FILTRO_K1).instantiate()
		_filtro.ler_game_state = false
		add_child(_filtro)
		var zonas := hub.get_node("Zonas")
		for fase in 4:
			var r: ColorRect = zonas.get_child(fase)
			_filtro.definir_zona(fase, Rect2(r.global_position, r.size))
		_demonstrar()
	else:
		print("K1 ainda não está no projeto: mostrando só a arte colorida.")


func _demonstrar() -> void:
	while is_inside_tree():
		await get_tree().create_timer(1.0).timeout
		for fase in 4:
			await _filtro.animar_zona(fase, 1.2)
		await get_tree().create_timer(1.5).timeout
		for fase in 4:
			_filtro.definir_t(fase, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if _filtro == null or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		_filtro.animar_zona(event.keycode - KEY_1)
	elif event.keycode == KEY_0:
		for fase in 4:
			_filtro.definir_t(fase, 0.0)
