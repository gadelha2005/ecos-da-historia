extends CenaJogavel
## Teste do card I7: o mundo em sépia com grão; a Label de UI continua nítida.
## T liga/desliga o filtro para comparar. O FPS aparece no canto.

@export var filtro: FiltroAntigo
@export var info: Label


func _process(_delta: float) -> void:
	info.text = "UI nítida (fora do filtro)   ·   FPS: %d   ·   Filtro: %s   ·   T liga/desliga" % [
		Engine.get_frames_per_second(), "ligado" if filtro.ativo else "desligado"]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		filtro.ativo = not filtro.ativo
