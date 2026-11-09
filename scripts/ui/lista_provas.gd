class_name ListaProvas
extends CanvasLayer
## [I4] Mini lista de provas no canto da tela. Lê GameState.provas.
## As provas chamam atualizar() pelo grupo "lista_provas" quando são coletadas.

@onready var titulo: Label = %Titulo
@onready var itens: Label = %Itens


func _ready() -> void:
	add_to_group("lista_provas")
	atualizar()


func atualizar() -> void:
	var total := Prova.IDS.size()
	var achadas := 0
	var linhas: Array[String] = []
	for id in Prova.IDS:
		if GameState.tem_prova(id):
			achadas += 1
			linhas.append("• " + Prova.nome_de(id))
		else:
			linhas.append("• ???")
	titulo.text = "Provas (%d/%d)" % [achadas, total]
	itens.text = "\n".join(linhas)
