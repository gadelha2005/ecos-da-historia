extends CanvasLayer
## [F3] Caixa de texto simples (autoload "Mensagem").
## Uso:  await Mensagem.mostrar(["Linha 1", "Linha 2"])
##       await Mensagem.mostrar(["Oi!"], "Dona Maria")   # com nome de quem fala
##       await Mensagem.eco(["Catalisador, o portal está instável."])
## O texto aparece letra por letra. Interagir (E / Espaço / Enter) ou clique:
## 1º toque completa a linha, 2º toque passa para a próxima.
## A função só termina quando o jogador fecha a última linha.

signal terminou
signal _avancar

const NOME_ECO: String = "ECO"
const LETRAS_POR_SEGUNDO: float = 45.0

@onready var caixa: PanelContainer = %Caixa
@onready var nome_falante: Label = %NomeFalante
@onready var texto: Label = %Texto
@onready var dica: Label = %Dica

var _ativo: bool = false
var _tween_texto: Tween
var _tween_dica: Tween


func _ready() -> void:
	caixa.hide()


func esta_aberta() -> bool:
	return _ativo


func eco(linhas: Array) -> void:
	await mostrar(linhas, NOME_ECO)


func mostrar(linhas: Array, falante: String = "") -> void:
	while _ativo:  # se já tem mensagem na tela, espera ela acabar (fila)
		await terminou
	_ativo = true

	nome_falante.text = falante
	nome_falante.visible = falante != ""
	caixa.show()
	for linha in linhas:
		_escrever(str(linha))
		await _avancar
	caixa.hide()

	_ativo = false
	terminou.emit()


func _escrever(linha: String) -> void:
	texto.text = linha
	texto.visible_ratio = 0.0
	_mostrar_dica(false)
	if _tween_texto != null and _tween_texto.is_valid():
		_tween_texto.kill()
	var duracao := maxf(linha.length() / LETRAS_POR_SEGUNDO, 0.05)
	_tween_texto = create_tween()
	_tween_texto.tween_property(texto, "visible_ratio", 1.0, duracao)
	_tween_texto.finished.connect(_mostrar_dica.bind(true))


func _escrevendo() -> bool:
	return _tween_texto != null and _tween_texto.is_running()


func _completar_linha() -> void:
	_tween_texto.kill()
	texto.visible_ratio = 1.0
	_mostrar_dica(true)


func _mostrar_dica(visivel: bool) -> void:
	if _tween_dica != null and _tween_dica.is_valid():
		_tween_dica.kill()
	dica.visible = visivel
	if visivel:  # pisca devagar para chamar atenção
		dica.modulate.a = 1.0
		_tween_dica = create_tween().set_loops()
		_tween_dica.tween_property(dica, "modulate:a", 0.3, 0.5)
		_tween_dica.tween_property(dica, "modulate:a", 1.0, 0.5)


func _input(event: InputEvent) -> void:
	if not _ativo:
		return
	var clicou: bool = event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT
	if not (event.is_action_pressed("interagir") or clicou):
		return
	# consome o toque para o jogador não interagir de novo com o mesmo objeto
	get_viewport().set_input_as_handled()
	if _escrevendo():
		_completar_linha()
	else:
		_avancar.emit()
