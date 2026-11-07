extends Node

@onready var hud: HudDialogo = $HudDialogo

var tensao: int = 0
var confianca: int = 50


func _ready() -> void:
	hud.tensao_estourou.connect(func() -> void: print("TENSÃO ESTOUROU"))
	hud.definir_tensao(tensao)
	hud.definir_confianca(confianca)
	print("Seta ↑/↓: tensão +10/-10 | Seta →/←: confiança +10/-10")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		tensao = clampi(tensao + 10, 0, 100)
		hud.definir_tensao(tensao)
	elif event.is_action_pressed("ui_down"):
		tensao = clampi(tensao - 10, 0, 100)
		hud.definir_tensao(tensao)
	elif event.is_action_pressed("ui_right"):
		confianca = clampi(confianca + 10, 0, 100)
		hud.definir_confianca(confianca)
	elif event.is_action_pressed("ui_left"):
		confianca = clampi(confianca - 10, 0, 100)
		hud.definir_confianca(confianca)
