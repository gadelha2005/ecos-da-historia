extends Area2D
## [I2] Área de interação do morador: o Player (C4) só detecta Area2D no grupo
## "interagivel", então esta área repassa a interação para o Morador (o pai).


func interagir(jogador: Player) -> void:
	var morador := get_parent()
	if morador and morador.has_method("interagir"):
		morador.interagir(jogador)
