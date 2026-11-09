extends CenaJogavel
## Fase 1904 (card I1): mato, trilha e povoado de casas de taipa.
## Tiles e cajueiro ainda são placeholders 16x16; a arte final vem no J1.

const LIMITES_MAPA: Rect2i = Rect2i(0, 0, 960, 640)  # 60 x 40 tiles de 16 px


func _ready() -> void:
	super._ready()
	jogador.definir_limites(LIMITES_MAPA)
