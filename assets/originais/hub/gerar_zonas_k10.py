"""[K10] Gerador dos objetos COLORIDOS das zonas do laboratório (pixel art estilo GBA).
O shader do K1 é que deixa tudo cinza; aqui a arte sai sempre colorida.

Saída em assets/sprites/hub/zonas/ (fundo transparente, vista de cima inclinada como o resto do jogo):
  Saúde:   saude_maca.png (32x24), saude_armario_remedios.png (24x32), saude_cruz_parede.png (16x16)
  Cultura: cultura_quadro_paisagem.png (24x16), cultura_quadro_retrato.png (16x16),
           cultura_quadro_abstrato.png (16x16), cultura_mural.png (64x32)
Natureza (vaso_*) e Educação (estante_2, estante_3) já existem em sprites-v2/lab/objetos (E2):
só falta conferir a cor quando essa pasta estiver no repositório.

Uso (na raiz do projeto):  python assets/originais/hub/gerar_zonas_k10.py   (precisa de Pillow)
"""
from __future__ import annotations

import math
import os
import random

from PIL import Image

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
PASTA = os.path.join(RAIZ, "assets", "sprites", "hub", "zonas")
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


BRANCO = rgb("f4f2ec")
BRANCO_S = rgb("cfcbc0")
METAL = rgb("a8b0bc")
METAL_S = rgb("6e7684")
VERMELHO = rgb("d93030")
MADEIRA = rgb("9a6a3a")
MADEIRA_C = rgb("c0905a")
MADEIRA_S = rgb("6a4424")
DOURADO = rgb("e0b040")


# ---------------------------------------------------------------- Saúde

def saude_maca():
    t = Tela(32, 24)
    # pernas e rodinhas
    for x in (4, 27):
        t.ret(x, 14, x, 20, METAL_S)
        t.ret(x - 1, 21, x + 1, 22, rgb("3a3a42"))
    t.ret(4, 17, 27, 17, METAL_S)              # barra de baixo
    # estrutura e colchão (vista de cima inclinada)
    t.ret(2, 11, 29, 14, METAL)
    t.ret(2, 3, 29, 11, BRANCO)
    t.ret(2, 3, 29, 3, clarear(BRANCO, 0.5))
    t.ret(2, 10, 29, 11, BRANCO_S)
    t.ret(10, 4, 29, 10, rgb("8ec8e8"))        # lençol azul-claro
    t.ret(10, 4, 29, 4, rgb("b8e0f4"))
    t.ret(10, 9, 29, 10, rgb("6aa8cc"))
    t.ret(3, 4, 8, 9, BRANCO)                  # travesseiro
    t.ret(3, 4, 8, 4, clarear(BRANCO, 0.5))
    t.ret(3, 9, 8, 9, BRANCO_S)
    t.ret(18, 4, 19, 10, rgb("6aa8cc"))        # dobra do lençol
    t.contorno()
    return t.imagem()


def saude_armario_remedios():
    t = Tela(24, 32)
    t.ret(2, 4, 21, 30, BRANCO)                # corpo do armário
    t.ret(2, 4, 21, 5, clarear(BRANCO, 0.5))
    t.ret(21, 6, 21, 30, BRANCO_S)
    t.ret(2, 30, 21, 30, BRANCO_S)
    t.ret(9, 0, 14, 3, BRANCO)                 # placa com a cruz em cima
    t.ret(11, 0, 12, 3, VERMELHO)
    t.ret(10, 1, 13, 2, VERMELHO)
    # duas portas de vidro com prateleiras de remédios
    vidro = rgb("bfe4ec")
    for x0 in (4, 12):
        t.ret(x0, 7, x0 + 7, 21, vidro)
        for y in (11, 16, 21):
            t.ret(x0, y, x0 + 7, y, BRANCO_S)
        frascos = [rgb("e85a4a"), rgb("4a8ae8"), rgb("f0c040"), rgb("5ab85a"), rgb("b06ad0"), rgb("f08a3a")]
        rnd = random.Random(x0)
        for prat_y in (10, 15, 20):
            x = x0 + 1
            while x < x0 + 7:
                cor = rnd.choice(frascos)
                alto = rnd.choice((2, 3))
                t.ret(x, prat_y - alto + 1, x, prat_y, cor)
                t.p(x, prat_y - alto, BRANCO)
                x += 2
        t.p(x0 + 1, 8, BRANCO)                 # reflexo no vidro
        t.p(x0 + 2, 8, BRANCO)
    t.ret(11, 7, 12, 21, BRANCO_S)             # divisão entre as portas
    t.ret(4, 23, 19, 29, BRANCO)               # gaveta de baixo
    t.ret(4, 26, 19, 26, BRANCO_S)
    t.ret(10, 24, 13, 24, METAL_S)             # puxadores
    t.ret(10, 28, 13, 28, METAL_S)
    t.contorno()
    return t.imagem()


def saude_cruz_parede():
    t = Tela(16, 16)
    t.ret(2, 2, 13, 13, BRANCO)                # placa branca
    t.ret(2, 2, 13, 2, clarear(BRANCO, 0.5))
    t.ret(13, 3, 13, 13, BRANCO_S)
    t.ret(3, 13, 13, 13, BRANCO_S)
    t.ret(6, 4, 9, 11, VERMELHO)               # cruz
    t.ret(4, 6, 11, 9, VERMELHO)
    t.ret(6, 4, 9, 4, clarear(VERMELHO, 0.3))
    t.ret(4, 6, 5, 6, clarear(VERMELHO, 0.3))
    t.contorno()
    return t.imagem()


# ---------------------------------------------------------------- Cultura

def _moldura(t, x0, y0, x1, y1, cor=MADEIRA, luz=MADEIRA_C, sombra=MADEIRA_S):
    t.ret(x0, y0, x1, y1, cor)
    t.ret(x0, y0, x1, y0, luz)
    t.ret(x0, y0, x0, y1, luz)
    t.ret(x1, y0 + 1, x1, y1, sombra)
    t.ret(x0 + 1, y1, x1, y1, sombra)


def cultura_quadro_paisagem():
    t = Tela(24, 16)
    _moldura(t, 1, 1, 22, 14, DOURADO, clarear(DOURADO, 0.4), escurecer(DOURADO, 0.7))
    t.ret(3, 3, 20, 7, rgb("7ac0ec"))          # céu
    t.elipse(17, 5, 1.6, 1.6, rgb("f8e070"))    # sol
    t.ret(3, 8, 20, 12, rgb("4aa04a"))          # morro
    for x, y in [(5, 7), (6, 6), (7, 6), (8, 7), (12, 7), (13, 6), (14, 7)]:
        t.p(x, y, rgb("3a8a3a"))
    t.ret(3, 11, 20, 12, rgb("3a7ac0"))         # rio
    t.ret(6, 11, 9, 11, rgb("7ab0e8"))
    t.contorno()
    return t.imagem()


def cultura_quadro_retrato():
    t = Tela(16, 16)
    _moldura(t, 2, 1, 13, 14)
    t.ret(4, 3, 11, 12, rgb("4a3a6a"))          # fundo
    t.elipse(7.5, 7, 2.2, 2.6, rgb("d8a07a"))   # rosto
    t.ret(5, 4, 10, 5, rgb("2a1a14"))           # cabelo
    t.ret(5, 10, 10, 12, rgb("c03a3a"))         # roupa
    t.p(6, 7, rgb("2a1a14"))
    t.p(9, 7, rgb("2a1a14"))
    t.contorno()
    return t.imagem()


def cultura_quadro_abstrato():
    t = Tela(16, 16)
    _moldura(t, 1, 1, 14, 14, rgb("2a2a30"), rgb("4a4a54"), rgb("16161a"))
    t.ret(3, 3, 12, 12, rgb("f4ecd8"))
    t.ret(3, 3, 7, 7, rgb("e04040"))            # blocos de cor
    t.ret(8, 3, 12, 5, rgb("f0c030"))
    t.ret(8, 6, 12, 12, rgb("3a6ad8"))
    t.ret(3, 9, 6, 12, rgb("3aa850"))
    t.ret(3, 8, 12, 8, rgb("1a1a1e"))
    t.ret(7, 3, 7, 12, rgb("1a1a1e"))
    t.contorno()
    return t.imagem()


def cultura_mural():
    """Mural colorido (anos 70 / Tropicália): sol, ondas, máscaras e notas musicais."""
    t = Tela(64, 32)
    t.ret(1, 1, 62, 30, rgb("f4e2b8"))              # parede pintada
    faixas = [rgb("e85040"), rgb("f09a30"), rgb("f0d040"), rgb("50b060"), rgb("3a80d0"), rgb("9a50c0")]
    for i, cor in enumerate(faixas):                 # arco-íris de faixas
        for x in range(1, 63):
            y = 22 + i + int(2 * math.sin((x + i * 3) / 6.0))
            t.ret(x, y, x, min(30, y + 1), cor)
    t.ret(1, 29, 62, 30, faixas[-1])
    t.elipse(12, 10, 6, 6, rgb("f8c030"))           # sol
    t.elipse(12, 10, 4, 4, rgb("f8e070"))
    for dx, dy in [(-8, 0), (8, 0), (0, -8), (0, 8), (-6, -6), (6, -6), (-6, 6), (6, 6)]:
        t.p(12 + dx, 10 + dy, rgb("f8c030"))
    # máscara de teatro (comédia) e máscara (tragédia)
    t.elipse(32, 11, 5, 6, rgb("d838b0"))
    t.ret(30, 9, 30, 9, rgb("3a1a30"))
    t.ret(34, 9, 34, 9, rgb("3a1a30"))
    for x, y in [(29, 13), (30, 14), (31, 14), (32, 14), (33, 14), (34, 13)]:
        t.p(x, y, rgb("3a1a30"))
    t.elipse(42, 13, 4, 5, rgb("3a80d0"))
    t.p(40, 11, rgb("14244a"))
    t.p(44, 11, rgb("14244a"))
    for x, y in [(40, 16), (41, 15), (42, 15), (43, 15), (44, 16)]:
        t.p(x, y, rgb("14244a"))
    # notas musicais
    for nx, ny in [(52, 6), (57, 9)]:
        t.ret(nx, ny, nx, ny + 6, rgb("2a2a30"))
        t.ret(nx - 2, ny + 5, nx - 1, ny + 7, rgb("2a2a30"))
        t.ret(nx, ny, nx + 2, ny + 1, rgb("2a2a30"))
    # pinceladas
    for x, y, cor in [(22, 4, rgb("50b060")), (23, 5, rgb("50b060")), (48, 18, rgb("e85040")),
                      (49, 19, rgb("e85040")), (6, 19, rgb("3a80d0")), (58, 16, rgb("f09a30"))]:
        t.ret(x, y, x + 2, y, cor)
    t.contorno(0.5)
    return t.imagem()


OBJETOS = {
    "saude_maca": saude_maca,
    "saude_armario_remedios": saude_armario_remedios,
    "saude_cruz_parede": saude_cruz_parede,
    "cultura_quadro_paisagem": cultura_quadro_paisagem,
    "cultura_quadro_retrato": cultura_quadro_retrato,
    "cultura_quadro_abstrato": cultura_quadro_abstrato,
    "cultura_mural": cultura_mural,
}


def main():
    os.makedirs(PASTA, exist_ok=True)
    for nome, f in OBJETOS.items():
        f().save(os.path.join(PASTA, nome + ".png"))
    print("Objetos das zonas gerados em", PASTA)


if __name__ == "__main__":
    main()
