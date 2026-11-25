extends Node
## Teste da volta da fase 1973: simula que o Catalisador já passou das fases 1 e 2
## (Chave da Saúde encaixada, Mostra de Cultura aprovada e Chave da Cultura na mão) e entra
## no hub pelo portal de 1973. No hub, o HubEventos faz a sequência: a chave encaixa na
## segunda fechadura, a zona da Cultura ganha cor (agora são duas zonas coloridas), o slot
## do HUD pisca e o terceiro portal (1979) acende.
## Abra esta cena e aperte F6.

const CENA_HUB: String = "res://scenes/hub/hub.tscn"


func _ready() -> void:
	GameState.reiniciar()
	GameState.nome_jogador = "Catalisador"
	GameState.intro_vista = true  # pula a intro do ECO: só a volta
	GameState.moradores_concluidos = GameState.MORADORES.size()
	GameState.dar_chave(GameState.FASE_1904)
	GameState.encaixar_chave(GameState.FASE_1904)  # a primeira já estava na porta
	GameState.npcs_concluidos[GameState.FASE_1973] = GameState.SEQUENCIA[GameState.FASE_1973].size()
	GameState.dar_chave(GameState.FASE_1973)  # chave pega, ainda não encaixada
	SceneManager.trocar_cena.call_deferred(CENA_HUB, "Spawn_Portal1973")
