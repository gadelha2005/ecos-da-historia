class_name PortaSaida
extends Area2D
## [K3] Porta de saída do laboratório com 4 fechaduras (uma por época, 0 = 1904 ... 3 = 1982).
## encaixar(fase): a chave aparece, desliza até a fechadura, gira e a fechadura acende
## (no fim chama GameState.encaixar_chave). No _ready, as fechaduras já encaixadas aparecem
## preenchidas sem animação. Com as 4 encaixadas, interagir abre a porta e vai para o final.

signal chave_encaixada(fase: int)
signal porta_aberta

const CENA_FINAL := "res://scenes/final/final.tscn"
## Arte do K9 (Leo): fechaduras 8x8 e chaves 16x16, na ordem das épocas.
const FECHADURA_VAZIA: Texture2D = preload("res://assets/sprites/hub/chaves/fechadura_vazia.png")
const FECHADURAS: Array[Texture2D] = [
	preload("res://assets/sprites/hub/chaves/fechadura_saude.png"),     # 1904 Saúde
	preload("res://assets/sprites/hub/chaves/fechadura_cultura.png"),   # 1973 Cultura
	preload("res://assets/sprites/hub/chaves/fechadura_ambiente.png"),  # 1979 Meio ambiente
	preload("res://assets/sprites/hub/chaves/fechadura_educacao.png"),  # 1982 Educação
]
const CHAVES: Array[Texture2D] = [
	preload("res://assets/sprites/hub/chaves/chave_saude.png"),
	preload("res://assets/sprites/hub/chaves/chave_cultura.png"),
	preload("res://assets/sprites/hub/chaves/chave_ambiente.png"),
	preload("res://assets/sprites/hub/chaves/chave_educacao.png"),
]
## Escala da chave durante a animação (a arte tem 16x16; a porta tem 32 de largura).
const ESCALA_CHAVE := Vector2(0.75, 0.75)

var _ocupada: bool = false

@onready var fechaduras: Array[Sprite2D] = [
	$Fechaduras/Fechadura0, $Fechaduras/Fechadura1, $Fechaduras/Fechadura2, $Fechaduras/Fechadura3,
]
@onready var folha: ColorRect = $ColorRect
@onready var som: AudioStreamPlayer2D = $Som


func _ready() -> void:
	som.stream = _som_clique()
	for fase in fechaduras.size():
		_pintar(fase, GameState.chaves_encaixadas[fase])


func encaixadas() -> int:
	return GameState.chaves_encaixadas.count(true)


## Anima a chave da época `fase` entrando na fechadura. Use com await.
func encaixar(fase: int) -> void:
	if GameState.chaves_encaixadas[fase] or _ocupada:
		return
	_ocupada = true
	var fechadura := fechaduras[fase]
	var chave := Sprite2D.new()
	chave.texture = CHAVES[fase]
	chave.scale = ESCALA_CHAVE
	chave.z_index = 1
	chave.position = fechadura.position + Vector2(0, 30)
	chave.modulate.a = 0.0
	add_child(chave)

	var tw := create_tween()
	tw.tween_property(chave, "modulate:a", 1.0, 0.2)
	tw.tween_property(chave, "position", fechadura.position, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(som.play)
	tw.tween_property(chave, "rotation", PI / 2.0, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(_pintar.bind(fase, true))
	tw.tween_property(fechadura, "scale", Vector2(1.5, 1.5), 0.1)
	tw.parallel().tween_property(chave, "modulate:a", 0.0, 0.15)
	tw.tween_property(fechadura, "scale", Vector2.ONE, 0.15)
	await tw.finished
	chave.queue_free()

	GameState.encaixar_chave(fase)
	chave_encaixada.emit(fase)
	_ocupada = false


## As quatro fechaduras giram juntas e a porta se abre (N5). Use com await.
func abrir() -> void:
	_ocupada = true
	var tw := create_tween().set_parallel(true)
	for f in fechaduras:
		tw.tween_property(f, "rotation", f.rotation + PI / 2.0, 0.4).set_trans(Tween.TRANS_BACK)
	tw.chain().tween_callback(som.play)
	tw.chain().tween_interval(0.2)
	tw.chain().tween_property(folha, "scale:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property($Fechaduras, "modulate:a", 0.0, 0.3)
	tw.chain().tween_interval(0.3)
	await tw.finished
	porta_aberta.emit()


func interagir(jogador: Player) -> void:
	if _ocupada:
		return
	jogador.pode_mover = false
	var faltam := GameState.TOTAL_FASES - encaixadas()
	if faltam <= 0:
		await abrir()
		if not _ir_para(CENA_FINAL):
			jogador.pode_mover = true
		return
	await _mostrar(["Falta 1 chave." if faltam == 1 else "Faltam %d chaves." % faltam])
	jogador.pode_mover = true


func _unhandled_input(event: InputEvent) -> void:
	# atalho de debug: F9 dá todas as chaves (só em build de debug)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		for i in GameState.TOTAL_FASES:
			GameState.dar_chave(i)
		print("Debug: todas as chaves liberadas")


func _pintar(fase: int, cheia: bool) -> void:
	fechaduras[fase].texture = FECHADURAS[fase] if cheia else FECHADURA_VAZIA


func _ir_para(caminho: String, spawn: String = "") -> bool:
	if ResourceLoader.exists(caminho):
		SceneManager.trocar_cena(caminho, spawn)
		return true
	print("Ainda não existe: ", caminho)
	return false


func _mostrar(linhas: Array[String]) -> void:
	var mensagem := get_node_or_null("/root/Mensagem")
	if mensagem:
		await mensagem.mostrar(linhas)
	else:
		print("\n".join(linhas))


## Som provisório de "clique" da fechadura (onda quadrada curta), até entrar o áudio de verdade.
func _som_clique() -> AudioStreamWAV:
	var taxa := 22050
	var n := int(taxa * 0.09)
	var dados := PackedByteArray()
	dados.resize(n * 2)
	for i in n:
		var t := float(i) / taxa
		var onda := 1.0 if fmod(t * (880.0 - 400.0 * t / 0.09), 1.0) < 0.5 else -1.0
		var amostra := int(onda * exp(-t * 40.0) * 9000.0)
		dados.encode_s16(i * 2, amostra)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = taxa
	wav.data = dados
	return wav
