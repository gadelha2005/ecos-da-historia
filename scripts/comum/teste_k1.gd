extends CenaJogavel
## Teste do card K1. Tudo começa em cinza. Teclas 1 a 4 animam a cor da zona
## correspondente; 0 volta tudo para cinza; G liga/desliga a cor fora das zonas.
## Ande com o Player: as zonas ficam no lugar quando a câmera se move.

@export var filtro: FiltroCor
@export var zonas: Node2D
@export var info: Label


func _ready() -> void:
	super._ready()
	for fase in 4:
		var r: ColorRect = zonas.get_child(fase)
		filtro.definir_zona(fase, Rect2(r.global_position, r.size))


func _process(_delta: float) -> void:
	info.text = "Cor das zonas: %.2f  %.2f  %.2f  %.2f   ·   FPS: %d\n1-4: colorir zona   ·   0: tudo cinza   ·   G: cor fora das zonas" % [
		filtro.valor_t(0), filtro.valor_t(1), filtro.valor_t(2), filtro.valor_t(3), Engine.get_frames_per_second()]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			filtro.animar_zona(event.keycode - KEY_1)
		KEY_0:
			for fase in 4:
				filtro.definir_t(fase, 0.0)
		KEY_G:
			filtro.definir_t_geral(0.0 if filtro.valor_t_geral() > 0.5 else 1.0)
