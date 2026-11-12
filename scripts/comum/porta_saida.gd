class_name PortaSaida
extends Area2D
## [K3] Porta de saída do laboratório com 4 fechaduras (uma por época, 0 = 1904 ... 3 = 1982).
## encaixar(fase): a chave aparece, desliza até a fechadura, gira e a fechadura acende
## (no fim chama GameState.encaixar_chave). No _ready, as fechaduras já encaixadas aparecem
## preenchidas sem animação. Com as 4 encaixadas, interagir abre a porta e vai para o final.

signal chave_encaixada(fase: int)
signal porta_aberta

const CENA_FINAL := "res://scenes/final/final.tscn"
## Cores provisórias das fechaduras/chaves (até a arte do K9).
const CORES: Array[Color] = [
	Color(0.85, 0.15, 0.15),  # 1904 Saúde
	Color(0.85, 0.2, 0.7),    # 1973 Cultura
	Color(0.2, 0.7, 0.25),    # 1979 Meio ambiente
	Color(0.9, 0.7, 0.15),    # 1982 Educação
]
const COR_VAZIA := Color(0.16, 0.16, 0.19)

## Arte da chave (K9). Vazio = retângulo na cor da época.
@export var textura_chave: Texture2D

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
	if textura_chave:
		chave.texture = textura_chave
	else:
		chave.texture = fechadura.texture
		chave.scale = Vector2(0.5, 1.5)
		chave.modulate = CORES[fase].lightened(0.25)
	chave.position = fechadura.position + Vector2(0, 30)
	chave.modulate.a = 0.0
	add_child(chave)

	var tw := create_tween()
	tw.tween_property(chave, "modulate:a", 1.0, 0.2)
	tw.tween_property(chave, "position", fechadura.position, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(som.play)
	tw.tween_property(chave, "rotation", PI / 2.0, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(_pintar.bind(fase, true))
	tw.tween_property(fechadura, "scale", Vector2(1.6, 1.6), 0.1)
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
	fechaduras[fase].modulate = CORES[fase] if cheia else COR_VAZIA


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
