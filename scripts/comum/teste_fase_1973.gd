extends Node
## Atalho para jogar a fase 1973 sem passar pela 1904 (rode com F6).
## Já dá e encaixa a Chave da Saúde e entra direto na fase_1973 real.
## Ao terminar a 1973, volta ao hub normalmente com a Chave da Cultura.

const CENA_FASE: String = "res://scenes/fases/fase_1973.tscn"


func _ready() -> void:
	GameState.reiniciar()
	GameState.nome_jogador = "Catalisador"
	GameState.intro_vista = true
	GameState.moradores_concluidos = GameState.MORADORES.size()
	GameState.dar_chave(GameState.FASE_1904)
	GameState.encaixar_chave(GameState.FASE_1904)
	SceneManager.trocar_cena.call_deferred(CENA_FASE, "Spawn_Inicio")
