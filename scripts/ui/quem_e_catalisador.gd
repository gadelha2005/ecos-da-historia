class_name QuemECatalisador
extends Control
## [F2] Tela "Quem é o Catalisador?": apresenta o protagonista e pede nome e aparência.
## Salva em GameState.nome_jogador e GameState.aparencia e segue para o hub.

const CAMINHO_TEXTOS: String = "res://data/textos/quem_e_catalisador.json"
const CENA_HUB: String = "res://scenes/hub/hub.tscn"
const TAMANHO_MAX_NOME: int = 16
# Cor aplicada no sprite para cada aparência (mesma ordem de "aparencias" no JSON).
# Provisório: quando a arte final tiver variações, troca-se a cor por sprites diferentes.
const CORES_APARENCIA: Array[Color] = [
	Color(1, 1, 1),
	Color(1.0, 0.8, 0.55),
	Color(0.6, 0.85, 1.0),
]

@onready var titulo: Label = %Titulo
@onready var texto: Label = %Texto
@onready var pergunta_nome: Label = %PerguntaNome
@onready var campo_nome: LineEdit = %CampoNome
@onready var pergunta_aparencia: Label = %PerguntaAparencia
@onready var previa: TextureRect = %Previa
@onready var nome_aparencia: Label = %NomeAparencia
@onready var botao_anterior: Button = %BotaoAnterior
@onready var botao_proxima: Button = %BotaoProxima
@onready var botao_confirmar: Button = %BotaoConfirmar

var _nomes_aparencia: Array = ["Original"]
var _aparencia: int = 0


func _ready() -> void:
	_carregar_textos()
	campo_nome.max_length = TAMANHO_MAX_NOME
	campo_nome.text = GameState.nome_jogador
	_aparencia = clampi(GameState.aparencia, 0, _total_aparencias() - 1)

	campo_nome.text_changed.connect(_on_nome_mudou)
	campo_nome.text_submitted.connect(_on_nome_enviado)
	botao_anterior.pressed.connect(_trocar_aparencia.bind(-1))
	botao_proxima.pressed.connect(_trocar_aparencia.bind(1))
	botao_confirmar.pressed.connect(_on_confirmar)

	_atualizar_aparencia()
	_on_nome_mudou(campo_nome.text)
	campo_nome.grab_focus()


func _carregar_textos() -> void:
	if not FileAccess.file_exists(CAMINHO_TEXTOS):
		push_error("Textos não encontrados: " + CAMINHO_TEXTOS)
		return
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_TEXTOS))
	if typeof(dados) != TYPE_DICTIONARY:
		push_error("JSON inválido em " + CAMINHO_TEXTOS)
		return
	titulo.text = str(dados.get("titulo", titulo.text))
	texto.text = str(dados.get("texto", texto.text))
	pergunta_nome.text = str(dados.get("pergunta_nome", pergunta_nome.text))
	campo_nome.placeholder_text = str(dados.get("placeholder_nome", campo_nome.placeholder_text))
	pergunta_aparencia.text = str(dados.get("pergunta_aparencia", pergunta_aparencia.text))
	botao_confirmar.text = str(dados.get("botao_confirmar", botao_confirmar.text))
	var lista: Variant = dados.get("aparencias", [])
	if typeof(lista) == TYPE_ARRAY and not lista.is_empty():
		_nomes_aparencia = lista


func _total_aparencias() -> int:
	return mini(_nomes_aparencia.size(), CORES_APARENCIA.size())


func _trocar_aparencia(passo: int) -> void:
	_aparencia = posmod(_aparencia + passo, _total_aparencias())
	_atualizar_aparencia()


func _atualizar_aparencia() -> void:
	previa.modulate = CORES_APARENCIA[_aparencia]
	nome_aparencia.text = str(_nomes_aparencia[_aparencia])


func _nome_limpo() -> String:
	return campo_nome.text.strip_edges()


func _on_nome_mudou(_novo: String) -> void:
	botao_confirmar.disabled = _nome_limpo() == ""


func _on_nome_enviado(_texto: String) -> void:
	if not botao_confirmar.disabled:
		_on_confirmar()


func _unhandled_input(event: InputEvent) -> void:
	# setas esquerda/direita trocam a aparência quando o campo de nome não está em foco
	if campo_nome.has_focus():
		return
	if event.is_action_pressed("ui_left"):
		_trocar_aparencia(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_trocar_aparencia(1)
		get_viewport().set_input_as_handled()


func _on_confirmar() -> void:
	if _nome_limpo() == "":
		return
	botao_confirmar.disabled = true  # evita clique duplo durante o fade
	GameState.nome_jogador = _nome_limpo()
	GameState.aparencia = _aparencia
	SceneManager.trocar_cena(CENA_HUB)
