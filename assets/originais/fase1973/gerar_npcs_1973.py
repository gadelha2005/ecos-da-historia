"""[M6] Personagens da fase 1973 no mesmo estilo dos moradores de 1904 (J1).

Reaproveita o gerador da fase 1904 (mesmo corpo, cabeça, contorno e folha 48x96:
colunas = parado, passo 1, passo 2; linhas = frente, costas, lado virado para a direita)
e acrescenta o que é dos anos 1970: cabelo volumoso, boina, faixa no cabelo, calça boca
de sino, gravata larga e os objetos de cada um (almofada de bilro, cordel, máscara, paleta,
prancheta). Também gera o .tres (SpriteFrames) de cada um.

Uso (na raiz do projeto):  python assets/originais/fase1973/gerar_npcs_1973.py
Saída: assets/sprites/fase1973/morador_<id>.png e .tres (o Morador carrega sozinho pela fase).
"""
from __future__ import annotations

import importlib.util
import os

AQUI = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "arte1904", os.path.join(AQUI, "..", "fase1904", "gerar_arte_1904.py"))
g = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(g)

from PIL import Image  # noqa: E402

rgb, escurecer, clarear = g.rgb, g.escurecer, g.clarear
RAIZ = os.path.abspath(os.path.join(AQUI, "..", "..", ".."))
PASTA = os.path.join(RAIZ, "assets", "sprites", "fase1973")

# ---------------------------------------------------------------- extras dos anos 1970
# Desenhados logo antes do contorno de cada quadro (por isso o contorno também os envolve).

_ctx = {"p": None, "vista": "frente", "passo": 0}
_contorno_original = g.Tela.contorno


def _contorno_com_extras(self, fator=0.45):
    p = _ctx["p"]
    if p is not None and hasattr(p, "extras"):
        _desenhar_extras(self, p, _ctx["vista"], _ctx["passo"])
    _contorno_original(self, fator)


g.Tela.contorno = _contorno_com_extras


def _desenhar_extras(t, p, vista, passo):
    ex = p.extras
    frente, costas, lado = vista == "frente", vista == "costas", vista == "lado"
    parado = passo == 0

    if "volumoso" in ex:                       # cabelo black power / volumoso
        c, luz = p.cabelo, clarear(p.cabelo, 0.2)
        for y in range(0, 11):
            for x in range(1, 15):
                cx = 8.5 if lado else 7.5
                if ((x - cx) / 6.6) ** 2 + ((y - 5) / 5.2) ** 2 > 1.0:
                    continue
                rosto = (y >= 7 and 4 <= x <= 11) if frente else (lado and y >= 7 and x >= 8)
                if not rosto:
                    t.p(x, y, c)
        if not costas:
            t.lh(4, 9, 1, luz)
    if "faixa" in ex:                          # faixa no cabelo
        cor = rgb("e8c030")
        t.lh(3, 12, 5, cor)
        if lado:
            t.lh(4, 12, 5, cor)
    if "boina" in ex:
        boina = rgb("6a2a34")
        t.ret(3, 1, 11, 3, boina)
        t.lh(2, 12, 4, boina)
        t.lh(4, 9, 1, clarear(boina, 0.25))
        t.p(7 if not lado else 6, 0, escurecer(boina, 0.7))
    if "oculos" in ex and not costas:
        aro = rgb("2a2020")
        if frente:
            t.ret(4, 9, 6, 10, aro)
            t.ret(9, 9, 11, 10, aro)
            t.lh(7, 8, 9, aro)
        else:
            t.ret(9, 9, 11, 10, aro)
            t.lh(5, 8, 9, aro)

    if "boca_de_sino" in ex and not p.saia:   # calça que abre embaixo
        le = 1 if passo == 1 else 0
        ld = 1 if passo == 2 else 0
        if lado:
            t.lh(4, 11, 27, p.calca)
        else:
            t.lh(4, 7, 27 - le, p.calca)
            t.lh(8, 11, 27 - ld, p.calca)
    if "gravata" in ex and frente:
        gr = rgb("b8602a")
        t.ret(7, 16, 8, 20, gr)
        t.p(7, 21, escurecer(gr, 0.8))
        t.lh(7, 8, 16, clarear(gr, 0.2))
    if "lapela" in ex and frente:
        t.p(6, 16, escurecer(p.roupa, 0.7))
        t.p(9, 16, escurecer(p.roupa, 0.7))

    # objetos na mão (só de frente e de lado, como no 1904)
    item = p.extra_item
    if costas or item is None:
        return
    x_mao = 13 if frente else 10
    y_mao = 20 + (1 if (passo == 1 and frente) else 0)
    if item == "almofada":                     # almofada de bilro com os bilros pendurados
        branco, linha = rgb("f4efe2"), rgb("c8b890")
        t.elipse(7.5, 19.5, 4.4, 2.4, branco) if frente else t.elipse(10.5, 19.5, 3.0, 2.4, branco)
        for x in (range(4, 12, 2) if frente else range(9, 13, 2)):
            t.p(x, 21, linha)
            t.p(x, 22, g.MADEIRA)
        t.lh(5, 10, 18, rgb("e8a0b0")) if frente else t.lh(9, 12, 18, rgb("e8a0b0"))
    elif item == "cordel":                     # folheto erguido (pose gesto) ou na mão
        papel, capa = rgb("efe2c0"), rgb("3a2a20")
        if frente and parado:
            t.ret(13, 5, 15, 8, papel)
            t.p(14, 6, capa)
            t.p(14, 7, capa)
        else:
            t.ret(x_mao, y_mao - 2, x_mao + 2, y_mao + 1, papel)
            t.p(x_mao + 1, y_mao - 1, capa)
    elif item == "mascara":                    # máscara de teatro branca
        branco = rgb("f4f0e8")
        t.ret(x_mao, y_mao - 3, x_mao + 2, y_mao, branco)
        t.p(x_mao, y_mao - 2, g.OLHO)
        t.p(x_mao + 2, y_mao - 2, g.OLHO)
        t.p(x_mao + 1, y_mao, rgb("c62860"))
    elif item == "paleta":                     # paleta de pintor com tinta
        madeira = rgb("c89858")
        t.ret(x_mao - 1, y_mao - 1, x_mao + 2, y_mao + 1, madeira)
        t.p(x_mao - 1, y_mao - 1, rgb("d82878"))
        t.p(x_mao + 1, y_mao - 1, rgb("28a8d8"))
        t.p(x_mao + 2, y_mao, rgb("f0c820"))
        t.ret(x_mao + 2, y_mao - 4, x_mao + 2, y_mao - 2, g.MADEIRA)   # pincel
        t.p(x_mao + 2, y_mao - 5, rgb("d82878"))
    elif item == "prancheta":
        t.ret(x_mao - 1, y_mao - 3, x_mao + 1, y_mao + 1, rgb("9a7448"))
        t.ret(x_mao - 1, y_mao - 2, x_mao + 1, y_mao + 1, rgb("f4f0e8"))
        t.p(x_mao, y_mao - 3, rgb("8a8a90"))
        t.p(x_mao, y_mao - 1, rgb("5a6a8a"))


class Pessoa73(g.Pessoa):
    def __init__(self, extras=(), extra_item=None, **kw):
        super().__init__(**kw)
        self.extras = set(extras)
        self.extra_item = extra_item


def folha(p):
    im = Image.new("RGBA", (48, 96))
    _ctx["p"] = p
    for col in range(3):
        _ctx.update(vista="frente", passo=col)
        im.paste(g._quadro_frente(p, col).imagem(), (col * 16, 0))
        _ctx.update(vista="costas", passo=col)
        im.paste(g._quadro_frente(p, col, costas=True).imagem(), (col * 16, 32))
        _ctx.update(vista="lado", passo=col)
        im.paste(g._quadro_lado(p, col).imagem(), (col * 16, 64))
    _ctx["p"] = None
    return im


# Fortaleza, 1973: campus novo e a primeira Mostra de Cultura (Narrativa N2).
PERSONAGENS = {
    # coordenadora da comissão: jovem, cabelo volumoso, blusa mostarda, calça boca de sino, prancheta
    "comissao": Pessoa73(pele="7a4a30", cabelo="1e1612", roupa="d0a030", calca="7a4a2a",
                         sapato="3a2418", extras={"volumoso", "boca_de_sino"},
                         extra_item="prancheta"),
    # Dona Socorro, rendeira: senhora de chapéu de palha, vestido florido, almofada de bilro
    "rendeira": Pessoa73(pele="9c6a48", cabelo="8a8480", roupa="c8705a", calca="a85a48",
                         sapato="5a3a26", saia=True, cabelo_estilo="coque", chapeu="palha",
                         estampa="f4e4c8", extra_item="almofada"),
    # Seu Firmino, cordelista: chapéu de couro, bigode, camisa quadriculada, declamando com o folheto
    "cordelista": Pessoa73(pele="a8703f", cabelo="3a2c26", roupa="5a7a9a", calca="6a5a48",
                           sapato="4a3020", chapeu="couro", bigode="3a2c26", estampa="e8dcc0",
                           pose="gesto", extra_item="cordel"),
    # Lúcia, diretora de teatro amador: cabelo longo com faixa, gola alta preta, jeans boca de sino, máscara
    "diretor_teatro": Pessoa73(pele="c58c63", cabelo="5a3020", roupa="2a2830", calca="4a6a9a",
                               sapato="2a2224", cabelo_estilo="longo",
                               extras={"faixa", "boca_de_sino"}, extra_item="mascara"),
    # Professor Aurélio, pintor de formação clássica: boina, barba grisalha, colete, paleta
    "pintor": Pessoa73(pele="e0b090", cabelo="b8b4ae", roupa="ece6d6", calca="4a4450",
                       sapato="2a2224", barba="c8c4be", colete="6a6a50", extras={"boina"},
                       extra_item="paleta"),
    # Dr. Valdemar, patrocinador: terno marrom anos 70, gravata larga, óculos, bigode, maleta
    "patrocinador": Pessoa73(pele="d9a47c", cabelo="3a2a20", roupa="6a4a30", calca="5a3e28",
                             sapato="1e1c22", bigode="3a2a20", gola="f2f0ea", item="maleta",
                             extras={"gravata", "lapela", "oculos"}),
    # comissão (figurantes ao lado da coordenadora): professor de artes e estudante
    "professor_artes": Pessoa73(pele="b07850", cabelo="2a1e18", roupa="8a9a6a", calca="4a4038",
                                sapato="2a2224", barba="2a1e18", gola="ece6d6",
                                extras={"oculos", "volumoso"}),
    "estudante": Pessoa73(pele="e0b090", cabelo="6a4028", roupa="d85a3a", calca="4a6a9a",
                          sapato="ece6d6", cabelo_estilo="longo", mangas_curtas=True,
                          extras={"boca_de_sino"}, extra_item="cordel"),
}

TRES = """[gd_resource type="SpriteFrames" format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/fase1973/morador_{id}.png" id="1_folha"]

{subs}
[resource]
animations = [{anims}]
"""


def tres(id_):
    subs = []
    for lin in range(3):
        for col in range(3):
            subs.append(f'[sub_resource type="AtlasTexture" id="q_{lin}_{col}"]\n'
                        f'atlas = ExtResource("1_folha")\nregion = Rect2({col * 16}, {lin * 32}, 16, 32)\n')
    anims = []
    for lin, nome in enumerate(["baixo", "cima", "lado"]):
        quadros = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("q_%d_%d")\n}' % (lin, c)
                            for c in (0, 1, 2))
        anims.append('{\n"frames": [%s],\n"loop": true,\n"name": &"andar_%s",\n"speed": 5.0\n}' % (quadros, nome))
        anims.append('{\n"frames": [{\n"duration": 1.0,\n"texture": SubResource("q_%d_0")\n}],\n'
                     '"loop": true,\n"name": &"idle_%s",\n"speed": 5.0\n}' % (lin, nome))
    return TRES.format(id=id_, subs="\n".join(subs), anims=", ".join(anims))


def main():
    os.makedirs(PASTA, exist_ok=True)
    for id_, p in PERSONAGENS.items():
        folha(p).save(os.path.join(PASTA, f"morador_{id_}.png"))
        with open(os.path.join(PASTA, f"morador_{id_}.tres"), "w", encoding="utf-8") as f:
            f.write(tres(id_))
    print("Personagens da fase 1973 gerados.")


if __name__ == "__main__":
    main()
