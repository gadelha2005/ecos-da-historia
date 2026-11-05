class_name NoDialogo
extends Resource

@export var id: String = ""
@export_multiline var fala: String = ""
@export var opcoes: Array[OpcaoDialogo] = []
@export var final: bool = false      # nó de saída da conversa
