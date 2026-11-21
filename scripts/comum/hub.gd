extends CenaJogavel
## Hub: laboratório de Computação da Unifor em 2026.
## [D2] blockout · [K12] liga o filtro de cor às 4 zonas (os portais, a porta, o HUD,
## o terminal e o HubEventos ficam montados no hub.tscn).

const LIMITES_MAPA: Rect2i = Rect2i(0, 0, 480, 288)  # 30 x 18 tiles de 16 px
## Na mesma ordem das fases: 0 = 1904 Saúde, 1 = 1973 Cultura, 2 = 1979 Natureza, 3 = 1982 Educação.
const ZONAS: Array[String] = ["Zonas/Zona_Saude", "Zonas/Zona_Cultura", "Zonas/Zona_Natureza", "Zonas/Zona_Educacao"]

@export var filtro_cor: FiltroCor


func _ready() -> void:
	super._ready()
	jogador.definir_limites(LIMITES_MAPA)
	if filtro_cor:
		for fase in ZONAS.size():
			var zona := get_node(ZONAS[fase]) as ColorRect
			filtro_cor.definir_zona(fase, Rect2(zona.global_position, zona.size))
