extends CenaJogavel
## Hub: laboratório de Computação da Unifor em 2026 (blockout do D2).

const LIMITES_MAPA: Rect2i = Rect2i(0, 0, 640, 384)  # 40 x 24 tiles de 16 px


func _ready() -> void:
	super._ready()
	jogador.definir_limites(LIMITES_MAPA)
