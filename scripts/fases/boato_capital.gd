class_name BoatoCapital
extends Node
## Evento "boato da capital" da fase 1904: chega na metade do dia e aumenta a tensão.
## Agenda a si mesmo na AgendaEventos indicada. O que ainda não existe (HUD do H4,
## caixa de texto do F3, diálogo coletivo do H3) é chamado de forma segura.

signal boato_disparou(tensao_extra: float)

@export var agenda: AgendaEventos
## Duração do dia da fase, em segundos. O boato chega na metade.
@export var duracao_dia: float = 240.0
## Quanto a tensão sobe quando o boato chega (0–100).
@export var tensao_extra: float = 20.0
## Id do diálogo coletivo opcional (data/dialogos/<id>.json). Vazio = sem diálogo.
@export var dialogo_coletivo: String = ""

const FALA_ECO: Array[String] = [
	"ECO: Chegou um boato da capital!",
	"ECO: Dizem que a vacina faz mal. O povoado está mais desconfiado agora.",
]

var disparado: bool = false


func _ready() -> void:
	if agenda == null:
		push_warning("BoatoCapital sem agenda: o boato não será agendado.")
		return
	agenda.agendar(duracao_dia / 2.0, "boato_capital", disparar)


func disparar() -> void:
	if disparado:
		return
	disparado = true
	boato_disparou.emit(tensao_extra)  # o H4 (barras de tensão / vinheta) escuta este sinal
	await _mostrar(FALA_ECO)
	_abrir_dialogo_coletivo()


func _abrir_dialogo_coletivo() -> void:
	if dialogo_coletivo == "":
		return
	var gerente := get_node_or_null("/root/DialogoManager")
	if gerente and gerente.has_method("iniciar"):
		gerente.iniciar(dialogo_coletivo)
	else:
		print("Ainda não existe: DialogoManager (diálogo coletivo '%s')" % dialogo_coletivo)


func _mostrar(linhas: Array[String]) -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.mostrar(linhas)
	else:
		print("\n".join(linhas))
