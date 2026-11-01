extends Node

const TOTAL_FASES: int = 4

var nome_jogador: String = ""
var aparencia: int = 0
var chaves: Array[bool] = [false, false, false, false]  # 1904, 1973, 1979, 1982
var tentativas: Array[int] = [0, 0, 0, 0]
var pontuacao: Array[float] = [0.0, 0.0, 0.0, 0.0]


func tem_chave(fase: int) -> bool:
	return chaves[fase]


func dar_chave(fase: int) -> void:
	chaves[fase] = true


func total_chaves() -> int:
	return chaves.count(true)


func portal_liberado(fase: int) -> bool:
	return fase == 0 or chaves[fase - 1]  # o portal só abre com a chave anterior


func reiniciar() -> void:
	nome_jogador = ""
	aparencia = 0
	for i in TOTAL_FASES:
		chaves[i] = false
		tentativas[i] = 0
		pontuacao[i] = 0.0
