"""[L8a] Personagens da fase 1979 no mesmo estilo de 1904 e 1973.

Reaproveita o gerador de 1973 (que já reaproveita o de 1904): mesmo corpo, cabeça, contorno
e folha 48x96 (colunas = parado, passo 1, passo 2; linhas = frente, costas, lado).
Acrescenta o que é desta fase: capacete de obra, cocar e pintura de urucum, colar de sementes,
e os objetos na mão (enxada, vara de pesca, planta enrolada, livro). Gera também o .tres.

Uso (na raiz do projeto):  python assets/originais/fase1979/gerar_npcs_1979.py
Saída: assets/sprites/fase1979/morador_<id>.png e .tres (o Morador carrega sozinho pela fase).
"""
from __future__ import annotations

import importlib.util
import os

AQUI = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "npcs1973", os.path.join(AQUI, "..", "fase1973", "gerar_npcs_1973.py"))
m73 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(m73)
g = m73.g
rgb, escurecer, clarear = g.rgb, g.escurecer, g.clarear

RAIZ = os.path.abspath(os.path.join(AQUI, "..", "..", ".."))
PASTA = os.path.join(RAIZ, "assets", "sprites", "fase1979")

_extras_1973 = m73._desenhar_extras


def _extras_1979(t, p, vista, passo):
    _extras_1973(t, p, vista, passo)
    ex = p.extras
    frente, costas, lado = vista == "frente", vista == "costas", vista == "lado"
    parado = passo == 0

    if "capacete" in ex:                       # capacete de obra (cor por pessoa)
        c = getattr(p, "cor_capacete", rgb("f0c020"))
        t.ret(3, 1, 12, 4, c)
        t.lh(2, 13, 5, escurecer(c, 0.8))
        t.lh(5, 10, 2, clarear(c, 0.35))
        t.lh(7, 8, 0, c)
    if "cocar" in ex:                          # faixa de palha com penas (vermelha, amarela, azul)
        t.lh(3, 12, 4, rgb("c89a50"))
        penas = [rgb("c8382a"), rgb("f0b830"), rgb("2a6ab8"), rgb("f0b830"), rgb("c8382a")]
        xs = [4, 6, 8, 10, 12] if not lado else [6, 8, 10]
        for i, x in enumerate(xs):
            cor = penas[i % len(penas)]
            alt = 4 if i in (1, 2, 3) else 3
            t.ret(x, 4 - alt, x, 3, cor)
            t.p(x, 4 - alt, clarear(cor, 0.3))
    if "pintura" in ex and not costas:         # traços de urucum nas bochechas
        u = rgb("b8402a")
        if frente:
            t.lh(4, 5, 10, u)
            t.lh(10, 11, 10, u)
        else:
            t.lh(9, 10, 10, u)
    if "colar" in ex and not costas:           # colar de sementes
        s1, s2 = rgb("e8dcc0"), rgb("8a3a2a")
        if frente:
            for i, x in enumerate(range(5, 11)):
                t.p(x, 14 + (1 if 6 <= x <= 9 else 0), s1 if i % 2 else s2)
        else:
            t.p(9, 14, s1)
            t.p(10, 15, s2)

    item = getattr(p, "item79", None)
    if costas or item is None:
        return
    x_mao = 13 if frente else 10
    y_mao = 20 + (1 if (passo == 1 and frente) else 0)
    if item == "enxada":                       # cabo comprido com a lâmina em cima
        t.ret(x_mao, y_mao - 11, x_mao, y_mao + 6, g.MADEIRA)
        t.ret(x_mao - 2, y_mao - 12, x_mao + 1, y_mao - 11, rgb("8a8a90"))
        t.p(x_mao - 2, y_mao - 12, rgb("b8b8c0"))
    elif item == "vara":                       # vara de pesca inclinada com a linha
        for i in range(12):
            t.p(x_mao + i // 3, y_mao - i, rgb("a8844a"))
        t.ret(x_mao + 4, y_mao - 11, x_mao + 4, y_mao - 5, rgb("e8e8e8"))
    elif item == "planta":                     # planta do loteamento enrolada
        azul = rgb("4a7ab8")
        t.ret(x_mao - 1, y_mao - 2, x_mao + 1, y_mao + 2, azul)
        t.lh(x_mao - 1, x_mao + 1, y_mao - 2, clarear(azul, 0.4))
        t.p(x_mao, y_mao, rgb("e8e8f0"))
    elif item == "livro":
        capa = rgb("7a2a2a")
        t.ret(x_mao - 1, y_mao - 3, x_mao + 1, y_mao + 1, capa)
        t.lh(x_mao - 1, x_mao + 1, y_mao + 1, rgb("f0ead8"))
        t.p(x_mao, y_mao - 2, rgb("d8b040"))


m73._desenhar_extras = _extras_1979


class Pessoa79(m73.Pessoa73):
    def __init__(self, item79=None, cor_capacete=None, **kw):
        super().__init__(**kw)
        self.item79 = item79
        if cor_capacete:
            self.cor_capacete = rgb(cor_capacete)


# Mata ao lado da Unifor, 1979 (Narrativa N3). Ninguém é vilão: cada um tem a sua razão.
PERSONAGENS = {
    # Prof. Augusto, de Direito: paletó cinza, gravata, óculos, barba grisalha, livro de leis
    "professor": Pessoa79(pele="c58c63", cabelo="8a8480", roupa="5a5a62", calca="3a3a42",
                          sapato="1e1c22", barba="a8a49e", gola="f2f0ea",
                          extras={"gravata", "lapela", "oculos"}, item79="livro"),
    # Dona Rita: agricultora há 40 anos, lenço na cabeça, vestido de chita, enxada
    "dona_rita": Pessoa79(pele="8a5a3a", cabelo="5a5450", roupa="6a8a4a", calca="5a7040",
                          sapato="5a3a26", saia=True, cabelo_estilo="coque", lenco="d8483a",
                          estampa="f0dca0", arregacada=True, item79="enxada"),
    # Seu Raimundo: pescador da lagoa, chapéu de palha, camisa aberta, calça arregaçada, vara
    "seu_raimundo": Pessoa79(pele="7a4a30", cabelo="d8d4ce", roupa="e0d8c0", calca="6a6a5a",
                             sapato="6a4a30", chapeu="palha", bigode="d8d4ce",
                             camisa_aberta=True, arregacada=True, item79="vara"),
    # Iberê: jovem indígena da comunidade, cocar de penas, urucum, colar de sementes
    "jovem": Pessoa79(pele="9a5e3a", cabelo="141010", roupa="d8c8a0", calca="5a6a8a",
                      sapato="3a2a20", cabelo_estilo="longo", mangas_curtas=True,
                      extras={"cocar", "pintura", "colar"}),
    # Dr. Heitor, engenheiro: capacete branco, camisa social azul clara, planta do loteamento
    "engenheiro": Pessoa79(pele="e0b090", cabelo="3a2a20", roupa="a8c8e0", calca="4a4a50",
                           sapato="2a2224", bigode="3a2a20", extras={"capacete", "oculos"},
                           cor_capacete="f2f2f2", item79="planta"),
    # Sr. Otávio, investidor: terno claro de linho, gravata, maleta
    "investidor": Pessoa79(pele="d9a47c", cabelo="2a1e18", roupa="d8ccb0", calca="c8bca0",
                           sapato="5a3a26", gola="f2f0ea", item="maleta",
                           extras={"gravata", "lapela"}),
    # Zé Carlos, operário: capacete amarelo, macacão azul, mangas arregaçadas
    "operario": Pessoa79(pele="a8703f", cabelo="2a1e18", roupa="2a5a9a", calca="2a5a9a",
                         sapato="3a2a20", bigode="2a1e18", arregacada=True, largo=True,
                         extras={"capacete"}, cor_capacete="f0c020"),
}


def main():
    os.makedirs(PASTA, exist_ok=True)
    for id_, p in PERSONAGENS.items():
        m73.folha(p).save(os.path.join(PASTA, f"morador_{id_}.png"))
        with open(os.path.join(PASTA, f"morador_{id_}.tres"), "w", encoding="utf-8") as f:
            f.write(m73.tres(id_).replace("fase1973", "fase1979"))
    print("Personagens da fase 1979 gerados.")


if __name__ == "__main__":
    main()
