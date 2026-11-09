extends Node
## Cena de teste do card H1 (menu de escolhas 2x2).
## Teclas 1-4 escolhem direto; setas/mouse + interagir também funcionam.

@onready var menu: MenuEscolhas = $MenuEscolhas


func _ready() -> void:
	var opcoes: Array[Dictionary] = [
		{"tipo": "empatia", "texto": "Entendo seu medo. Muita gente perdeu alguém.", "habilitada": true},
		{"tipo": "fato", "texto": "A vacina reduziu os casos de varíola na cidade.", "habilitada": true},
		{"tipo": "autoridade", "texto": "O Dr. Oswaldo Cruz garante que é seguro.", "habilitada": true},
		{"tipo": "provas", "texto": "Olhe este relato de quem foi curado.", "habilitada": false},
	]
	var curto: Array[Dictionary] = [opcoes[0], opcoes[1]]

	var rodada := 0
	while true:
		var escolhidas: Array[Dictionary] = opcoes if rodada % 2 == 0 else curto
		var indice: int = await menu.escolher("Como você responde?", escolhidas)
		print("Rodada %d: escolheu o índice %d" % [rodada, indice])
		rodada += 1
