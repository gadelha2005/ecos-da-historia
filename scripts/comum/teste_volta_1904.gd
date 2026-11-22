extends Node
## Teste da volta da fase 1904: simula que o Catalisador acabou de passar da fase 1
## (6 moradores convencidos e a Chave da Saúde na mão) e entra no hub pelo portal de 1904.
## No hub, o HubEventos faz a sequência: a câmera vai até a porta, a chave encaixa na
## primeira fechadura, a zona da Saúde ganha cor, o slot do HUD pisca e o portal de 1973 acende.
## Abra esta cena e aperte F6.

const CENA_HUB: String = "res://scenes/hub/hub.tscn"


func _ready() -> void:
	GameState.reiniciar()
	GameState.nome_jogador = "Catalisador"
	GameState.intro_vista = true  # pula a intro do ECO: só a volta
	GameState.moradores_concluidos = GameState.MORADORES.size()
	GameState.dar_chave(GameState.FASE_1904)  # chave pega, ainda não encaixada
	SceneManager.trocar_cena.call_deferred(CENA_HUB, "Spawn_Portal1904")
