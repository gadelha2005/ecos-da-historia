"""[K9] Gerador das 4 chaves e das fechaduras (pixel art estilo GBA, fundo transparente).

Saída em assets/sprites/hub/chaves/:
  chave_saude.png     (cabeça em cruz, N1.6)       16x16
  chave_cultura.png   (pincel e máscara, N2.6)     16x16
  chave_ambiente.png  (folha, N3.7)                16x16
  chave_educacao.png  (dourada, N4.6)              16x16
  fechadura_vazia.png                               8x8
  fechadura_saude.png / _cultura / _ambiente / _educacao   8x8 (com a chave encaixada)

As chaves ficam de pé, com a ponta (dentes) para CIMA: na animação do K3 a chave sobe até a
fechadura e gira 90°. As fechaduras têm 8x8 porque na porta do K3 elas ficam a 8 px uma da outra.
Cores seguem as do K3 (Saúde vermelho, Cultura magenta, Meio ambiente verde, Educação dourado).

Uso (na raiz do projeto):  python assets/originais/hub/gerar_chaves_k9.py   (precisa de Pillow)
"""
from __future__ import annotations

import os

from PIL import Image

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
PASTA = os.path.join(RAIZ, "assets", "sprites", "hub", "chaves")
TRANSP = (0, 0, 0, 0)


def rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def escurecer(c, f=0.55):
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), 255)


def clarear(c, f=0.3):
    return tuple(min(255, int(v + (255 - v) * f)) for v in c[:3]) + (255,)


class Tela:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[TRANSP] * w for _ in range(h)]

    def p(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def ret(self, x0, y0, x1, y1, c):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                self.p(x, y, c)

    def elipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    self.p(x, y, c)

    def limpar(self, x, y):
        self.p(x, y, TRANSP)

    def contorno(self, fator=0.4):
        novo = [linha[:] for linha in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x][3]:
                    continue
                for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and self.px[ny][nx][3]:
                        novo[y][x] = escurecer(self.px[ny][nx], fator)
                        break
        self.px = novo

    def imagem(self):
        im = Image.new("RGBA", (self.w, self.h))
        for y in range(self.h):
            for x in range(self.w):
                im.putpixel((x, y), self.px[y][x])
        return im


OURO = rgb("e8b43c")
OURO_C = rgb("f8dc78")
OURO_S = rgb("b0802a")

ZONAS = {
    "saude": {"cor": rgb("d93030"), "metal": (OURO, OURO_C, OURO_S)},
    "cultura": {"cor": rgb("d838b0"), "metal": (rgb("c8a0d8"), rgb("ecdcf4"), rgb("8a6aa0"))},
    "ambiente": {"cor": rgb("38a848"), "metal": (rgb("9a7a4a"), rgb("c4a470"), rgb("6a5230"))},
    "educacao": {"cor": rgb("f0c030"), "metal": (rgb("f0c030"), rgb("fff0a0"), rgb("b88a18"))},
}


def _haste(t, metal):
    """Haste vertical (x 7-8) com os dentes no alto, à direita, e o colar logo acima da cabeça."""
    base, luz, sombra = metal
    t.ret(7, 1, 8, 8, base)
    t.ret(7, 1, 7, 8, luz)
    t.ret(9, 2, 10, 3, base)      # dente 1
    t.ret(9, 5, 9, 5, base)       # dente 2
    t.p(10, 3, sombra)
    t.ret(6, 7, 9, 7, sombra)     # colar
    t.ret(6, 8, 9, 8, base)


def chave_saude():
    t = Tela(16, 16)
    _haste(t, ZONAS["saude"]["metal"])
    vermelho = ZONAS["saude"]["cor"]
    t.elipse(7.5, 11.5, 4.6, 4.0, BRANCO)          # cabeça redonda branca
    t.ret(4, 14, 11, 14, rgb("d8d0c0"))            # sombra embaixo
    t.ret(3, 13, 3, 13, rgb("d8d0c0"))
    t.ret(12, 13, 12, 13, rgb("d8d0c0"))
    t.ret(7, 9, 8, 14, vermelho)                   # cruz vermelha
    t.ret(5, 11, 10, 12, vermelho)
    t.contorno()
    return t.imagem()


def chave_cultura():
    t = Tela(16, 16)
    madeira, madeira_c, madeira_s = rgb("a86a3a"), rgb("d09a5a"), rgb("70421e")
    # a haste é o cabo de um pincel; a ponta tem cerdas com tinta magenta
    t.ret(7, 3, 8, 8, madeira)
    t.ret(7, 3, 7, 8, madeira_c)
    t.ret(7, 1, 8, 2, rgb("d838b0"))      # cerdas com tinta
    t.p(7, 1, clarear(rgb("d838b0"), 0.4))
    t.ret(9, 3, 10, 3, madeira_s)          # dentes
    t.ret(9, 5, 9, 5, madeira_s)
    t.ret(6, 7, 9, 7, rgb("c8c8d0"))       # virola de metal
    # cabeça: máscara de teatro
    cor = ZONAS["cultura"]["cor"]
    t.elipse(7.5, 11.5, 4.6, 3.6, cor)
    t.ret(5, 9, 10, 9, clarear(cor, 0.3))
    t.limpar(5, 11)
    t.limpar(6, 11)
    t.limpar(9, 11)
    t.limpar(10, 11)
    t.p(5, 10, escurecer(cor, 0.6))
    t.p(10, 10, escurecer(cor, 0.6))
    for x, y in [(5, 13), (6, 14), (7, 14), (8, 14), (9, 14), (10, 13)]:
        t.p(x, y, escurecer(cor, 0.5))     # sorriso
    t.contorno()
    return t.imagem()


def chave_ambiente():
    t = Tela(16, 16)
    _haste(t, ZONAS["ambiente"]["metal"])
    verde = ZONAS["ambiente"]["cor"]
    t.elipse(7.5, 11.5, 3.8, 3.6, verde)
    t.ret(7, 14, 8, 15, verde)            # ponta da folha
    t.p(5, 9, clarear(verde, 0.35))
    t.p(4, 10, clarear(verde, 0.35))
    t.ret(7, 9, 7, 14, escurecer(verde, 0.65))   # nervura central
    t.p(6, 11, escurecer(verde, 0.65))
    t.p(5, 10, escurecer(verde, 0.65))
    t.p(8, 12, escurecer(verde, 0.65))
    t.p(9, 11, escurecer(verde, 0.65))
    t.ret(6, 8, 9, 8, rgb("6a5230"))
    t.contorno()
    return t.imagem()


def chave_educacao():
    t = Tela(16, 16)
    base, luz, sombra = ZONAS["educacao"]["metal"]
    _haste(t, (base, luz, sombra))
    # cabeça: argola dourada trabalhada com uma estrela no meio
    t.elipse(7.5, 11.5, 4.6, 3.8, base)
    t.elipse(7.5, 11.5, 2.6, 2.0, rgb("fff6c8"))
    t.ret(7, 10, 8, 13, OURO_S)            # estrela
    t.ret(6, 11, 9, 12, OURO_S)
    t.p(4, 10, luz)
    t.p(5, 9, luz)
    t.p(11, 13, sombra)
    t.p(10, 14, sombra)
    for x, y in [(3, 11), (12, 11)]:        # pedrinhas
        t.p(x, y, rgb("4aa0e8"))
    t.contorno()
    return t.imagem()


BRANCO = rgb("f8f4ea")


def _placa():
    t = Tela(8, 8)
    ferro, ferro_c, ferro_s = rgb("6a6a74"), rgb("9a9aa6"), rgb("44444c")
    t.ret(1, 1, 6, 6, ferro)
    t.ret(1, 1, 6, 1, ferro_c)
    t.ret(1, 1, 1, 6, ferro_c)
    t.ret(6, 2, 6, 6, ferro_s)
    t.ret(2, 6, 6, 6, ferro_s)
    return t


def fechadura_vazia():
    t = _placa()
    t.ret(3, 2, 4, 3, rgb("141418"))       # buraco da fechadura
    t.ret(3, 4, 4, 5, rgb("141418"))
    t.p(3, 5, rgb("26262c"))
    t.contorno(0.35)
    return t.imagem()


def fechadura_cheia(zona):
    """A cabeça da chave aparece no buraco e a placa ganha um brilho na cor da época."""
    t = _placa()
    cor = ZONAS[zona]["cor"]
    t.ret(1, 1, 6, 1, clarear(cor, 0.2))
    t.ret(1, 1, 1, 6, clarear(cor, 0.2))
    t.ret(6, 2, 6, 6, escurecer(cor, 0.7))
    t.ret(2, 6, 6, 6, escurecer(cor, 0.7))
    if zona == "saude":
        t.ret(3, 2, 4, 5, BRANCO)
        t.ret(2, 3, 5, 4, BRANCO)
        t.ret(3, 3, 4, 4, cor)
    elif zona == "cultura":
        t.ret(2, 2, 5, 5, cor)
        t.p(3, 3, escurecer(cor, 0.5))
        t.p(4, 3, escurecer(cor, 0.5))
        t.ret(3, 5, 4, 5, escurecer(cor, 0.5))
    elif zona == "ambiente":
        t.ret(3, 2, 4, 5, cor)
        t.ret(2, 3, 5, 4, cor)
        t.p(3, 2, clarear(cor, 0.4))
        t.ret(4, 3, 4, 5, escurecer(cor, 0.6))
    elif zona == "educacao":
        t.ret(2, 2, 5, 5, cor)
        t.ret(3, 3, 4, 4, rgb("fff6c8"))
    t.contorno(0.35)
    return t.imagem()


def main():
    os.makedirs(PASTA, exist_ok=True)
    chaves = {"saude": chave_saude, "cultura": chave_cultura,
              "ambiente": chave_ambiente, "educacao": chave_educacao}
    for nome, f in chaves.items():
        f().save(os.path.join(PASTA, f"chave_{nome}.png"))
        fechadura_cheia(nome).save(os.path.join(PASTA, f"fechadura_{nome}.png"))
    fechadura_vazia().save(os.path.join(PASTA, "fechadura_vazia.png"))
    print("Chaves e fechaduras geradas em", PASTA)


if __name__ == "__main__":
    main()
