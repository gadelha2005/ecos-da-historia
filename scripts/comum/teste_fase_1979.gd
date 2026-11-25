extends Node
## Atalho para jogar a fase 1979 sem passar pelas anteriores (rode com F6).
## Já dá e encaixa as chaves da Saúde e da Cultura e entra direto na fase_1979 real.
## Ao terminar a 1979, volta ao hub normalmente com a Chave do Meio Ambiente.

const CENA_FASE: String = "res://scenes/fases/fase_1979.tscn"


func _ready() -> void:
	GameState.reiniciar()
	GameState.nome_jogador = "Catalisador"
	GameState.intro_vista = true
	GameState.moradores_concluidos = GameState.MORADORES.size()
	for fase in [GameState.FASE_1904, GameState.FASE_1973]:
		GameState.dar_chave(fase)
		GameState.encaixar_chave(fase)
	GameState.npcs_concluidos[GameState.FASE_1973] = GameState.SEQUENCIA[GameState.FASE_1973].size()
	SceneManager.trocar_cena.call_deferred(CENA_FASE, "Spawn_Inicio")
