extends CanvasLayer

signal troca_concluida

const DURACAO_FADE: float = 0.3

@onready var fade: ColorRect = $Fade

var spawn_destino: String = ""
var _trocando: bool = false


func _ready() -> void:
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func trocar_cena(caminho: String, spawn: String = "") -> void:
	if _trocando:
		return
	_trocando = true
	spawn_destino = spawn
	await _animar_fade(1.0)
	get_tree().change_scene_to_file(caminho)
	await get_tree().process_frame
	await get_tree().process_frame
	await _animar_fade(0.0)
	_trocando = false
	troca_concluida.emit()


func _animar_fade(alvo: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", alvo, DURACAO_FADE)
	await tween.finished
