class_name OpcaoDialogo
extends Resource

enum Tipo { EMPATIA, FATO, AUTORIDADE, PROVAS }

@export var texto: String = ""
@export var tipo: Tipo = Tipo.EMPATIA
@export var peso: int = 0            # pontos que a opção soma na nota S
@export var tensao_delta: int = 0    # quanto a tensão sobe (+) ou desce (-)
@export var destino: String = ""     # id do próximo nó; vazio = termina
@export var exige_prova: String = "" # id da prova necessária (vazio = nenhuma)
