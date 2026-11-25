class_name ListaProvas
extends CanvasLayer
## [I4] Mini lista de provas no canto da tela. Lê GameState.provas.
## As provas chamam atualizar() pelo grupo "lista_provas" quando são coletadas.

## Fase cujas provas a lista mostra (0 = 1904, 1 = 1973).
@export_enum("1904", "1973", "1979") var fase: int = 0

@onready var titulo: Label = %Titulo
@onready var itens: Label = %Itens


func _ready() -> void:
	add_to_group("lista_provas")
	atualizar()


func atualizar() -> void:
	var ids := Prova.ids_da_fase(fase)
	var total := ids.size()
	var achadas := 0
	var linhas: Array[String] = []
	for id in ids:
		if GameState.tem_prova(id):
			achadas += 1
			var lado: String = Prova.LADO.get(id, "")
			linhas.append("• " + Prova.nome_de(id) + (" (ajuda: %s)" % lado if lado != "" else ""))
		else:
			linhas.append("• ???")
	titulo.text = "%s (%d/%d)" % ["Amostras" if fase == GameState.FASE_1973 else "Provas", achadas, total]
	itens.text = "\n".join(linhas)
