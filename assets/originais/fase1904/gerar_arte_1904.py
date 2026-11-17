"""[J1] Gerador da arte da fase 1904 (pixel art estilo GBA), seguindo o documento
"J1 · Prompts de arte da fase 1904" do Pedro: cores normais (o sépia vem do shader do I7),
contorno escuro de 1 px, sombreamento em 2 tons, cabeça grande e corpo curto como o Catalisador.

Personagens: folha 48x96 igual à catalisador.png (colunas = parado, passo 1, passo 2;
linhas = frente, costas, lado virado para a DIREITA; a esquerda é o lado espelhado).
  assets/sprites/fase1904/morador_<id>.png   6 moradores (a pose característica fica no quadro parado)
  assets/sprites/fase1904/brigada_<id>.png   médico e enfermeiro
Objetos (um PNG cada): assets/sprites/fase1904/objetos/<nome>.png
Tiles 16x16 que se repetem sem emenda: assets/tiles/fase1904/tiles_1904.png (mapa no fim do arquivo)

Uso (na raiz do projeto):  python assets/originais/fase1904/gerar_arte_1904.py
Precisa de Pillow (pip install pillow). O .gdignore em assets/originais faz o Godot ignorar esta pasta.
"""
from __future__ import annotations

import math
import os
import random

from PIL import Image

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
PASTA_SPRITES = os.path.join(RAIZ, "assets", "sprites", "fase1904")
PASTA_OBJETOS = os.path.join(PASTA_SPRITES, "objetos")
PASTA_TILES = os.path.join(RAIZ, "assets", "tiles", "fase1904")

TRANSP = (0, 0, 0, 0)


def rgb(h: str) -> tuple[int, int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def escurecer(c, f=0.55):
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), 255)


def clarear(c, f=0.25):
    return tuple(min(255, int(v + (255 - v) * f)) for v in c[:3]) + (255,)


OLHO = rgb("1e1a1c")
VERMELHO = rgb("c62828")
BRANCO = rgb("f4efe2")
VIDRO = rgb("9fd4e6")
COURO = rgb("7a4a2a")
MADEIRA = rgb("8a5a32")


# ---------------------------------------------------------------- tela

class Tela:
    def __init__(self, w=16, h=32):
        self.w, self.h = w, h
        self.px = [[TRANSP] * w for _ in range(h)]

    def p(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h and c is not None:
            self.px[y][x] = c

    def ret(self, x0, y0, x1, y1, c):  # inclusivo
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                self.p(x, y, c)

    def lh(self, x0, x1, y, c):
        self.ret(x0, y, x1, y, c)

    def elipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    self.p(x, y, c)

    def contorno(self, fator=0.45):
        """Contorno de 1 px com a cor vizinha escurecida (como no Catalisador)."""
        novo = [linha[:] for linha in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x][3] != 0:
                    continue
                for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and self.px[ny][nx][3] != 0:
                        novo[y][x] = escurecer(self.px[ny][nx], fator)
                        break
        self.px = novo

    def imagem(self):
        im = Image.new("RGBA", (self.w, self.h))
        for y in range(self.h):
            for x in range(self.w):
                im.putpixel((x, y), self.px[y][x])
        return im


# ---------------------------------------------------------------- personagens

class Pessoa:
    def __init__(self, pele, cabelo, roupa, calca, sapato, saia=False, cabelo_estilo="curto",
                 chapeu=None, barba=None, bigode=None, lenco=None, xale=None, colete=None,
                 estampa=None, remendos=None, camisa_aberta=False, arregacada=False,
                 mangas_curtas=False, largo=False, bravo=False, gola=None, item=None, pose=None):
        self.pele = rgb(pele)
        self.cabelo = rgb(cabelo)
        self.roupa = rgb(roupa)
        self.calca = rgb(calca)
        self.sapato = rgb(sapato)
        self.saia = saia
        self.cabelo_estilo = cabelo_estilo  # curto, coque, longo, careca
        self.chapeu = chapeu                # palha, couro, coco, bone
        self.barba = rgb(barba) if barba else None
        self.bigode = rgb(bigode) if bigode else None
        self.lenco = rgb(lenco) if lenco else None
        self.xale = rgb(xale) if xale else None
        self.colete = rgb(colete) if colete else None
        self.estampa = rgb(estampa) if estampa else None
        self.remendos = rgb(remendos) if remendos else None
        self.camisa_aberta = camisa_aberta
        self.arregacada = arregacada
        self.mangas_curtas = mangas_curtas
        self.largo = largo
        self.bravo = bravo
        self.gola = rgb(gola) if gola else None
        self.item = item                    # bebe, cesto, bengala, frasco, maleta
        self.pose = pose                    # cruzados, cintura, gesto (só no quadro parado)


def _limites_tronco(p):
    return (3, 12) if p.largo else (4, 11)


def _pernas_frente(t, p, passo):
    le = 1 if passo == 1 else 0
    ld = 1 if passo == 2 else 0
    if p.saia:
        t.ret(5, 24, 6, 27 - le, p.pele)
        t.ret(9, 24, 10, 27 - ld, p.pele)
    else:
        fim = 25 if p.arregacada else 27
        t.ret(5, 23, 7, fim - le, p.calca)
        t.ret(8, 23, 10, fim - ld, p.calca)
        t.lh(7, 8, 23, escurecer(p.calca, 0.8))
        if p.arregacada:
            t.lh(5, 7, fim - le, clarear(p.calca, 0.2))
            t.lh(8, 10, fim - ld, clarear(p.calca, 0.2))
            t.ret(6, fim + 1 - le, 7, 27 - le, p.pele)
            t.ret(8, fim + 1 - ld, 9, 27 - ld, p.pele)
    t.ret(4, 28 - le, 7, 29 - le, p.sapato)
    t.ret(8, 28 - ld, 11, 29 - ld, p.sapato)


def _braco(t, p, x, ate, mao_y):
    """Braço reto ao lado do corpo (frente/costas)."""
    if p.mangas_curtas:
        t.ret(x, 15, x, 17, p.roupa)
        t.ret(x, 18, x, ate, p.pele)
    else:
        t.ret(x, 15, x, ate, p.roupa)
    t.ret(x, mao_y, x, mao_y + 1, p.pele)


def _tronco_frente(t, p, costas, passo):
    x0, x1 = _limites_tronco(p)
    sombra = escurecer(p.roupa, 0.8)
    t.ret(x0, 15, x1, 22, p.roupa)
    t.lh(x0 + 1, x1 - 1, 15, clarear(p.roupa, 0.15))
    t.ret(x0, 16, x0, 22, sombra)
    t.ret(x1, 16, x1, 22, sombra)
    if p.estampa:
        for y in range(16, 23, 2):
            for x in range(x0 + 1 + (y // 2) % 2, x1, 3):
                t.p(x, y, p.estampa)
    if p.colete:
        if costas:
            t.ret(x0 + 1, 16, x1 - 1, 22, p.colete)
        else:
            t.ret(x0 + 1, 16, 6, 22, p.colete)
            t.ret(9, 16, x1 - 1, 22, p.colete)
            t.p(6, 18, clarear(p.colete, 0.4))
            t.p(9, 18, clarear(p.colete, 0.4))
    if p.gola and not costas:
        t.ret(7, 15, 8, 17, p.gola)
        if p.colete:
            t.p(7, 16, escurecer(p.roupa, 0.5))
    if p.camisa_aberta and not costas:
        t.ret(7, 15, 8, 16, p.pele)
        t.p(7, 17, p.pele)
    if p.remendos:
        t.ret(x0 + 1, 18, x0 + 2, 19, p.remendos)
        t.ret(x1 - 2, 20, x1 - 1, 21, escurecer(p.remendos, 0.85))
    if p.saia:
        t.ret(4, 21, 11, 23, p.calca)
        t.ret(3, 24, 12, 26, p.calca)
        t.lh(3, 12, 26, escurecer(p.calca, 0.8))
        if p.estampa:
            for x in range(4, 12, 3):
                t.p(x, 25, p.estampa)
    if p.xale:
        luz = clarear(p.xale, 0.2)
        t.lh(x0, x1, 15, luz)
        t.ret(x0, 16, x1, 17, p.xale)
        if costas:
            t.ret(x0 + 1, 18, x1 - 1, 19, p.xale)
            t.ret(6, 20, 9, 21, p.xale)
        else:
            t.ret(x0, 18, x0 + 1, 20, p.xale)
            t.ret(x1 - 1, 18, x1, 20, p.xale)

    # braços
    ax0, ax1 = x0 - 1, x1 + 1
    pose = p.pose if passo == 0 and not costas else None
    be = 1 if passo == 2 else 0
    bd = 1 if passo == 1 else 0
    if pose == "cruzados":
        t.ret(ax0, 15, ax0, 17, p.roupa)
        t.ret(ax1, 15, ax1, 17, p.roupa)
        t.ret(x0, 18, x1, 19, escurecer(p.roupa, 0.85))
        t.lh(x0 + 1, x1 - 1, 18, p.roupa)
        t.p(x0 + 1, 19, p.pele)
        t.p(x1 - 1, 18, p.pele)
    elif pose == "cintura":
        t.ret(ax0 - 1, 16, ax0, 18, p.roupa)
        t.ret(ax1, 16, ax1 + 1, 18, p.roupa)
        t.ret(ax0, 19, ax0, 20, p.pele)
        t.ret(ax1, 19, ax1, 20, p.pele)
        t.ret(ax0 - 1, 15, ax0, 15, escurecer(p.roupa, 0.85))
        t.ret(ax1, 15, ax1 + 1, 15, escurecer(p.roupa, 0.85))
    elif pose == "gesto":
        _braco(t, p, ax0, 20, 21)
        t.ret(ax1, 13, ax1, 16, p.roupa)          # braço erguido contando a novidade
        t.ret(ax1 + 1, 10, ax1 + 1, 13, p.roupa if not p.mangas_curtas else p.pele)
        t.ret(ax1 + 1, 8, ax1 + 1, 9, p.pele)
        t.p(ax1 + 2, 8, p.pele)
    else:
        _braco(t, p, ax0, 20 + be, 21 + be)
        _braco(t, p, ax1, 20 + bd, 21 + bd)

    # itens
    if p.item == "bebe":
        if costas:
            for i in range(6):
                t.p(x0 + 1 + i, 15 + i, rgb("e8d8b8"))  # pano amarrado
        else:
            pano = rgb("e8d8b8")
            t.elipse(7.5, 18.5, 3.6, 2.6, pano)
            t.lh(5, 10, 20, escurecer(pano, 0.85))
            t.ret(7, 17, 8, 18, clarear(p.pele, 0.15))  # rostinho
            t.p(x0, 20, p.pele)
            t.p(x1, 20, p.pele)
    elif p.item == "cesto":
        xc = ax0 - 3 if costas else ax1
        _cesto(t, xc, 19)
    elif p.item == "bengala":
        xb = ax0 - 1 if costas else ax1 + 1
        t.ret(xb, 20, xb, 29, MADEIRA)
        t.p(xb, 19, escurecer(MADEIRA, 0.8))
        t.p(xb - (1 if not costas else -1), 19, MADEIRA)
    elif p.item == "frasco" and not costas:
        y = 21 + bd if pose is None else 21
        t.ret(ax1 + 1, y - 3, ax1 + 1, y - 1, VIDRO)
        t.p(ax1 + 1, y - 4, rgb("b08850"))
    elif p.item == "maleta":
        xm = ax0 - 3 if costas else ax1
        y = 22 + (bd if not costas else be)
        t.ret(xm, y, xm + 3, y + 3, COURO)
        t.lh(xm, xm + 3, y, clarear(COURO, 0.2))
        t.p(xm + 1, y - 1, escurecer(COURO, 0.7))
        t.p(xm + 2, y - 1, escurecer(COURO, 0.7))


def _cesto(t, x, y):
    palha = rgb("c49a52")
    t.ret(x, y, x + 3, y + 3, palha)
    t.lh(x, x + 3, y + 2, escurecer(palha, 0.8))
    t.p(x + 1, y - 1, rgb("4f8a3a"))
    t.p(x + 2, y - 2, rgb("6aa84a"))
    t.p(x + 3, y - 1, rgb("4f8a3a"))


def _cabeca_frente(t, p, costas):
    t.ret(7, 14, 8, 14, escurecer(p.pele, 0.85))
    t.lh(5, 10, 3, p.pele)
    t.lh(4, 11, 4, p.pele)
    t.ret(3, 5, 12, 12, p.pele)
    t.lh(4, 11, 13, p.pele)
    sombra_pele = escurecer(p.pele, 0.85)
    if not costas:
        if p.bravo:
            t.ret(5, 10, 5, 10, OLHO)
            t.ret(10, 10, 10, 10, OLHO)
            t.lh(4, 6, 8, escurecer(p.cabelo, 0.7))
            t.lh(9, 11, 8, escurecer(p.cabelo, 0.7))
            t.p(6, 9, escurecer(p.cabelo, 0.7))
            t.p(9, 9, escurecer(p.cabelo, 0.7))
        else:
            t.ret(5, 9, 5, 10, OLHO)
            t.ret(10, 9, 10, 10, OLHO)
        t.lh(7, 8, 12, sombra_pele)
        t.p(3, 10, sombra_pele)
        t.p(12, 10, sombra_pele)
    c = p.cabelo
    luz = clarear(c, 0.2)
    if p.cabelo_estilo == "careca":
        if costas:
            t.ret(3, 9, 12, 11, c)
        else:
            t.ret(3, 8, 3, 10, c)
            t.ret(12, 8, 12, 10, c)
    elif costas:
        t.lh(5, 10, 3, c)
        t.lh(4, 11, 4, c)
        t.ret(3, 5, 12, 12, c)
        t.lh(4, 11, 13, c)
        t.lh(5, 9, 4, luz)
        if p.cabelo_estilo == "coque":
            t.ret(6, 1, 9, 3, c)
            t.lh(7, 8, 1, luz)
        if p.cabelo_estilo == "longo":
            t.ret(5, 13, 10, 17, c)
            t.lh(6, 9, 18, c)
    else:
        t.lh(5, 10, 3, c)
        t.lh(4, 11, 4, c)
        t.ret(3, 5, 12, 6, c)
        t.ret(3, 7, 3, 9, c)
        t.ret(12, 7, 12, 9, c)
        t.lh(4, 6, 7, c)
        t.lh(9, 11, 7, c)
        t.lh(5, 9, 4, luz)
        if p.cabelo_estilo == "coque":
            t.ret(6, 1, 9, 3, c)
            t.lh(7, 8, 1, luz)
            t.lh(4, 11, 7, c)
        if p.cabelo_estilo == "longo":
            t.ret(3, 10, 3, 15, c)
            t.ret(12, 10, 12, 15, c)
    if p.barba and not costas:
        t.ret(4, 11, 11, 13, p.barba)
        t.lh(5, 10, 14, p.barba)
        t.lh(7, 8, 11, escurecer(p.pele, 0.7))
    if p.bigode and not costas:
        t.lh(5, 10, 11, p.bigode)
        t.p(4, 12, p.bigode)
        t.p(11, 12, p.bigode)
        t.lh(7, 8, 12, sombra_pele)
    if p.lenco:
        t.lh(4, 11, 2, p.lenco)
        t.ret(3, 3, 12, 6, p.lenco)
        t.lh(4, 11, 3, clarear(p.lenco, 0.25))
        if costas:
            t.ret(3, 7, 12, 9, p.lenco)
            t.ret(7, 10, 8, 11, p.lenco)
        else:
            t.ret(3, 7, 3, 9, p.lenco)
            t.ret(12, 7, 12, 9, p.lenco)
    _chapeu(t, p, lado=False, costas=costas)


def _chapeu(t, p, lado, costas=False):
    if p.chapeu == "palha":
        palha = rgb("e2c46a")
        t.ret(5, 1, 10, 4, palha)
        t.lh(4, 11, 4, palha)
        t.lh(1, 14, 5, palha)
        t.lh(5, 10, 4, rgb("8d5b2c"))
        t.lh(6, 9, 1, clarear(palha, 0.3))
    elif p.chapeu == "couro":
        couro = rgb("8a5530")
        t.ret(5, 1, 10, 4, couro)
        t.lh(4, 11, 4, couro)
        t.lh(2, 13, 5, couro)
        t.p(1, 4, couro)
        t.p(14, 4, couro)
        t.lh(5, 10, 4, escurecer(couro, 0.7))
        t.lh(6, 9, 1, clarear(couro, 0.25))
    elif p.chapeu == "coco":
        preto = rgb("2c2a30")
        t.ret(5, 0, 10, 4, preto)
        t.lh(4, 11, 3, preto)
        t.lh(3, 12, 5, preto)
        t.lh(6, 9, 0, clarear(preto, 0.2))
        t.lh(5, 10, 4, rgb("4a2a2a"))
    elif p.chapeu == "bone":
        bone = rgb("4a5a72")
        t.ret(4, 2, 11, 5, bone)
        t.lh(5, 10, 2, clarear(bone, 0.2))
        if lado:
            t.lh(10, 14, 6, escurecer(bone, 0.8))
        elif not costas:
            t.lh(4, 11, 6, escurecer(bone, 0.8))


def _quadro_frente(p, passo, costas=False):
    t = Tela()
    _pernas_frente(t, p, passo)
    _tronco_frente(t, p, costas, passo)
    _cabeca_frente(t, p, costas)
    t.contorno()
    return t


def _quadro_lado(p, passo):
    """Virado para a direita."""
    t = Tela()
    sombra = escurecer(p.calca, 0.8)
    if p.saia:
        if passo == 0:
            t.ret(7, 24, 8, 27, p.pele)
            t.ret(6, 28, 10, 29, p.sapato)
        else:
            t.ret(9, 24, 10, 27, p.pele)
            t.ret(5, 24, 6, 27, escurecer(p.pele, 0.85))
            t.ret(9, 28, 12, 29, p.sapato)
            t.ret(3, 28, 6, 29, escurecer(p.sapato, 0.8))
    else:
        fim = 25 if p.arregacada else 27
        if passo == 0:
            t.ret(6, 23, 9, fim, p.calca)
            if p.arregacada:
                t.ret(7, fim + 1, 8, 27, p.pele)
            t.ret(6, 28, 10, 29, p.sapato)
        else:
            t.ret(8, 23, 10, fim, p.calca)
            t.ret(5, 23, 7, fim, sombra)
            if p.arregacada:
                t.ret(9, fim + 1, 10, 27, p.pele)
                t.ret(5, fim + 1, 6, 27, escurecer(p.pele, 0.85))
            t.ret(9, 28, 12, 29, p.sapato)
            t.ret(3, 28, 6, 29, escurecer(p.sapato, 0.8))
    x0, x1 = (4, 11) if p.largo else (5, 10)
    t.ret(x0, 15, x1, 22, p.roupa)
    t.lh(x0 + 1, x1 - 1, 15, clarear(p.roupa, 0.15))
    t.ret(x0, 16, x0, 22, escurecer(p.roupa, 0.8))
    if p.estampa:
        for y in range(16, 23, 2):
            for x in range(x0 + 1 + (y // 2) % 2, x1 + 1, 3):
                t.p(x, y, p.estampa)
    if p.colete:
        t.ret(x0 + 3, 16, x1, 22, p.colete)
    if p.gola:
        t.ret(x1 - 1, 15, x1, 16, p.gola)
    if p.camisa_aberta:
        t.ret(x1, 15, x1, 16, p.pele)
    if p.remendos:
        t.ret(x0 + 1, 19, x0 + 2, 20, p.remendos)
    if p.saia:
        t.ret(5, 21, 10, 23, p.calca)
        t.ret(4, 24, 11, 26, p.calca)
        t.lh(4, 11, 26, escurecer(p.calca, 0.8))
    if p.xale:
        t.ret(x0, 15, x1, 18, p.xale)
        t.ret(x0, 19, x0 + 2, 20, p.xale)
        t.lh(x0, x1, 15, clarear(p.xale, 0.2))

    pose = p.pose if passo == 0 else None
    dx = {0: 0, 1: 1, 2: -1}[passo]
    manga = escurecer(p.roupa, 0.88)
    if pose == "cruzados":
        t.ret(7, 16, 8, 17, manga)
        t.ret(7, 18, 11, 19, manga)
        t.p(11, 18, p.pele)
    elif pose == "cintura":
        t.ret(4, 16, 6, 18, manga)
        t.ret(6, 19, 7, 20, p.pele)
    elif pose == "gesto":
        t.ret(8, 15, 9, 16, manga)
        t.ret(10, 12, 11, 15, manga)
        t.ret(11, 10, 12, 11, p.pele)
    else:
        if p.mangas_curtas:
            t.ret(7 + dx, 16, 8 + dx, 17, manga)
            t.ret(7 + dx, 18, 8 + dx, 20, p.pele)
        else:
            t.ret(7 + dx, 16, 8 + dx, 20, manga)
        t.ret(7 + dx, 21, 8 + dx, 22, p.pele)

    if p.item == "bebe":
        pano = rgb("e8d8b8")
        t.elipse(10.5, 18.5, 2.6, 2.6, pano)
        t.ret(11, 17, 12, 18, clarear(p.pele, 0.15))
        t.ret(8, 20, 10, 20, p.pele)
    elif p.item == "cesto":
        _cesto(t, 8 + dx, 20)
    elif p.item == "bengala":
        t.ret(11, 21, 11, 29, MADEIRA)
        t.ret(9, 20, 11, 20, MADEIRA)
    elif p.item == "frasco" and pose is None:
        t.ret(9 + dx, 19, 9 + dx, 21, VIDRO)
        t.p(9 + dx, 18, rgb("b08850"))
    elif p.item == "maleta":
        t.ret(6 + dx, 22, 9 + dx, 25, COURO)
        t.lh(6 + dx, 9 + dx, 22, clarear(COURO, 0.2))

    # cabeça de perfil
    t.ret(7, 14, 8, 14, escurecer(p.pele, 0.85))
    t.lh(5, 10, 3, p.pele)
    t.lh(4, 11, 4, p.pele)
    t.ret(4, 5, 12, 12, p.pele)
    t.lh(5, 11, 13, p.pele)
    t.p(13, 9, p.pele)
    if p.bravo:
        t.p(10, 10, OLHO)
        t.lh(9, 11, 8, escurecer(p.cabelo, 0.7))
    else:
        t.ret(10, 9, 10, 10, OLHO)
    c = p.cabelo
    if p.cabelo_estilo != "careca":
        t.lh(5, 10, 3, c)
        t.lh(4, 11, 4, c)
        t.ret(4, 5, 12, 6, c)
        t.ret(4, 7, 8, 11, c)
        t.ret(4, 12, 6, 12, c)
        t.lh(5, 9, 4, clarear(c, 0.2))
        t.ret(7, 9, 7, 10, escurecer(p.pele, 0.85))
        t.p(7, 9, p.pele)
        if p.cabelo_estilo == "coque":
            t.ret(2, 5, 4, 8, c)
        if p.cabelo_estilo == "longo":
            t.ret(4, 12, 6, 16, c)
    else:
        t.ret(4, 8, 6, 11, c)
    if p.barba:
        t.ret(8, 11, 12, 13, p.barba)
        t.ret(9, 14, 11, 14, p.barba)
    if p.bigode:
        t.ret(11, 11, 13, 11, p.bigode)
    if p.lenco:
        t.lh(4, 11, 2, p.lenco)
        t.ret(4, 3, 12, 6, p.lenco)
        t.ret(3, 6, 6, 10, p.lenco)
        t.ret(2, 9, 3, 11, p.lenco)
    _chapeu(t, p, lado=True)
    if p.chapeu in ("palha", "couro", "coco"):
        cor = t.px[5][7]
        t.lh(3, 15, 5, cor)
    t.contorno()
    return t


def folha_personagem(p):
    folha = Image.new("RGBA", (48, 96))
    for col in range(3):
        folha.paste(_quadro_frente(p, col).imagem(), (col * 16, 0))
        folha.paste(_quadro_frente(p, col, costas=True).imagem(), (col * 16, 32))
        folha.paste(_quadro_lado(p, col).imagem(), (col * 16, 64))
    return folha


# Descrições da tabela do documento do Pedro (povoado do litoral do Ceará, 1904).
PERSONAGENS = {
    # jovem mãe, vestido simples de algodão, lenço, bebê em pano no colo, expressão preocupada
    "morador_inacia": Pessoa(pele="8d5a3b", cabelo="2a1d18", roupa="7a94b0", calca="5e7896",
                             sapato="5a3a26", saia=True, cabelo_estilo="longo", lenco="d08a3a",
                             item="bebe"),
    # meia-idade, saia longa escura, blusa de manga comprida, xale, braços cruzados
    "morador_dona_maria": Pessoa(pele="c58c63", cabelo="4a3a34", roupa="b8a890", calca="2e2b3e",
                                 sapato="2a2224", saia=True, cabelo_estilo="coque", xale="7a3040",
                                 pose="cruzados"),
    # magro e falante, camisa aberta, calça arregaçada, chapéu de palha, gesto de contar novidade
    "morador_ze_tonico": Pessoa(pele="a8703f", cabelo="3a2418", roupa="e8e0c8", calca="5d6b7a",
                                sapato="6b4226", chapeu="palha", camisa_aberta=True,
                                arregacada=True, pose="gesto"),
    # idoso de barba grisalha, chapéu de couro, camisa surrada, bengala
    "morador_seu_anselmo": Pessoa(pele="d9a47c", cabelo="a8a4a0", roupa="b0a88a", calca="5a5040",
                                  sapato="3a2a20", barba="b8b4ae", chapeu="couro",
                                  remendos="8a8268", item="bengala"),
    # homem forte, camisa remendada, mãos na cintura, cara de zangado
    "morador_seu_quintino": Pessoa(pele="9c6a48", cabelo="2a1e18", roupa="8a6a4a", calca="4a4a52",
                                   sapato="3a2a20", largo=True, bravo=True, remendos="c0a070",
                                   pose="cintura"),
    # idosa, vestido estampado simples, lenço, cesto de ervas no braço
    "morador_dona_cotinha": Pessoa(pele="7a4a30", cabelo="c8c4c0", roupa="5c7aa0", calca="4a6890",
                                   sapato="3a2a20", saia=True, lenco="e8e0d0", estampa="e8d870",
                                   item="cesto"),
    # médico sanitarista, meia-idade, bigode, terno escuro de três peças, chapéu, frasco de vacina
    "brigada_medico": Pessoa(pele="e0b090", cabelo="3a2c26", roupa="2e3040", calca="2a2c38",
                             sapato="1e1c22", bigode="3a2c26", chapeu="coco", colete="4a4458",
                             gola="f2f0ea", item="frasco"),
    # enfermeiro jovem, camisa clara com mangas arregaçadas, colete, boné, maleta de couro
    "brigada_enfermeiro": Pessoa(pele="b07850", cabelo="241a16", roupa="e8e4d8", calca="5a5448",
                                 sapato="3a2a20", colete="6e5440", mangas_curtas=True,
                                 chapeu="bone", item="maleta"),
}


# ---------------------------------------------------------------- objetos

VERDES = [rgb("2f6b35"), rgb("3f8442"), rgb("57a04f"), rgb("234f29")]


def _copa(t, blocos, rnd, folhas=70):
    copa = set()
    for cx, cy, rx, ry in blocos:
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    copa.add((x, y))
    for x, y in copa:
        sombra = any((x, y + k) not in copa for k in (1, 2, 3))
        t.p(x, y, VERDES[3] if sombra else VERDES[1])
    pts = sorted(copa)
    for _ in range(folhas):
        x, y = rnd.choice(pts)
        if t.px[y][x] != VERDES[3]:
            t.p(x, y, VERDES[2] if rnd.random() < 0.6 else VERDES[0])
    return copa


def _cajus(t, posicoes):
    for x, y in posicoes:
        cor = rgb("d63b2a") if (x + y) % 2 else rgb("f0b830")
        t.ret(x, y, x + 1, y + 2, cor)
        t.p(x, y + 3, rgb("8a6a3a"))


def cajueiro_grande():
    rnd = random.Random(1904)
    t = Tela(48, 48)
    tronco, tronco_s = rgb("6b4a32"), rgb("4e3424")
    for y in range(28, 46):
        x = 22 + (1 if y < 36 else 0) + (1 if y < 32 else 0)
        t.ret(x, y, x + 4, y, tronco)
        t.p(x, y, tronco_s)
    t.ret(18, 44, 30, 46, tronco)
    t.lh(17, 31, 46, tronco_s)
    t.ret(26, 30, 34, 32, tronco)
    t.ret(13, 33, 22, 34, tronco)
    _copa(t, [(24, 16, 20, 11), (12, 20, 10, 8), (36, 20, 10, 8), (18, 10, 10, 7), (30, 10, 10, 7),
              (8, 26, 7, 5), (40, 26, 7, 5), (24, 26, 14, 6)], rnd, 140)
    _cajus(t, [(9, 25), (33, 27), (21, 29), (40, 22), (6, 19), (28, 21), (15, 14)])
    t.contorno(0.5)
    return t.imagem()


def cajueiro_pequeno():
    rnd = random.Random(19)
    t = Tela(32, 32)
    tronco = rgb("6b4a32")
    t.ret(14, 20, 16, 30, tronco)
    t.ret(12, 29, 18, 30, tronco)
    t.ret(16, 21, 20, 22, tronco)
    _copa(t, [(15, 12, 12, 8), (8, 15, 6, 5), (23, 15, 6, 5), (15, 18, 9, 4)], rnd, 50)
    _cajus(t, [(8, 15), (20, 17), (14, 19)])
    t.contorno(0.5)
    return t.imagem()


def coqueiro(alto=True):
    rnd = random.Random(7 if alto else 8)
    w, h = 32, (64 if alto else 48)
    t = Tela(w, h)
    caule, caule_s, caule_c = rgb("9a7a52"), rgb("6e5638"), rgb("b8946a")
    topo = 14
    base = h - 2
    anterior = None
    for y in range(topo, base + 1):
        k = (y - topo) / (base - topo)
        x = int(round(15 + 4 * math.sin(k * 2.2)))   # tronco levemente curvo
        xa = x if anterior is None else min(x, anterior)
        t.ret(xa, y, max(x, xa) + 2, y, caule)       # emenda com a linha de cima
        if y % 3 == 0:
            t.lh(x, x + 2, y, caule_s)
        t.p(x + 2, y, caule_c)
        anterior = x
    t.ret(13, base - 1, 20, base, caule_s)
    # folhas (palmas) saindo do topo
    cx, cy = 16, topo
    for ang, comp in [(-160, 13), (-125, 12), (-90, 8), (-55, 12), (-20, 13), (200, 11), (-5, 10), (185, 10)]:
        a = math.radians(ang)
        for i in range(comp):
            x = cx + math.cos(a) * i
            y = cy + math.sin(a) * i + (i * i) / (comp * 1.4)   # pende para baixo
            t.p(int(x), int(y), VERDES[1] if i < comp - 2 else VERDES[0])
            t.p(int(x), int(y) + 1, VERDES[3])
            if i % 2 == 0:
                t.p(int(x), int(y) - 1, VERDES[2])
    for x, y in [(14, topo + 1), (17, topo + 2), (16, topo)]:  # cocos
        t.ret(x, y, x + 1, y + 1, rgb("6a5a2a"))
    t.contorno(0.5)
    return t.imagem()


def moita():
    rnd = random.Random(3)
    t = Tela(16, 16)
    _copa(t, [(8, 10, 7, 4), (5, 9, 4, 4), (11, 9, 4, 4), (8, 7, 4, 3)], rnd, 18)
    t.contorno(0.5)
    return t.imagem()


def arbusto_flores():
    rnd = random.Random(4)
    t = Tela(16, 16)
    _copa(t, [(8, 10, 7, 4), (5, 9, 4, 4), (11, 9, 4, 4), (8, 7, 4, 3)], rnd, 14)
    for x, y in [(4, 8), (9, 6), (12, 10), (6, 11), (10, 9)]:
        t.p(x, y, rgb("e85a8a"))
        t.p(x, y - 1, rgb("f8a0c0"))
    t.contorno(0.5)
    return t.imagem()


def _casa_base(t, rnd, w, telhado_ate):
    barro, barro_c, barro_s = rgb("b07a4a"), rgb("c8925c"), rgb("8a5a34")
    palha, palha_s = rgb("d8b45c"), rgb("a8843c")
    x0, x1 = 6, w - 7
    t.ret(x0, telhado_ate - 1, x1, 61, barro)
    for _ in range(int(w * 2.2)):
        t.p(rnd.randint(x0, x1), rnd.randint(telhado_ate, 61), barro_c if rnd.random() < 0.5 else barro_s)
    for x, y0, y1 in [(x0 + 6, 40, 46), (x1 - 12, 36, 41)]:
        t.ret(x, y0, x + 4, y1, rgb("6b4a32"))
        for yy in range(y0, y1 + 1, 2):
            t.lh(x, x + 4, yy, rgb("a88a5a"))
    t.lh(x0, x1, 61, barro_s)
    meio = w // 2
    for y in range(8, telhado_ate):
        larg = 4 + (y - 8) * (w / 2 - 3) / (telhado_ate - 8)
        t.ret(max(1, int(meio - larg)), y, min(w - 2, int(meio + larg)), y, palha)
    for y in range(10, telhado_ate, 3):
        for x in range(2, w - 2):
            if t.px[y][x][3] and (x + y) % 4 == 0:
                t.p(x, y, palha_s)
    t.lh(1, w - 2, telhado_ate - 1, palha_s)
    t.lh(meio - 4, meio + 4, 8, clarear(palha, 0.3))


def casa_taipa_porta():
    rnd = random.Random(31)
    t = Tela(64, 64)
    _casa_base(t, rnd, 64, 32)
    t.ret(27, 44, 36, 61, rgb("5a3a22"))
    t.ret(28, 45, 35, 61, rgb("744a2a"))
    t.ret(31, 45, 32, 61, rgb("5a3a22"))
    t.p(34, 53, rgb("d9b46a"))
    t.contorno(0.5)
    return t.imagem()


def casa_taipa_janela():
    rnd = random.Random(32)
    t = Tela(64, 64)
    _casa_base(t, rnd, 64, 32)
    for x in (16, 38):
        t.ret(x, 42, x + 9, 50, rgb("2a1e18"))
        t.ret(x, 42, x + 4, 50, rgb("744a2a"))
        t.lh(x - 1, x + 10, 51, rgb("8a5a34"))
    t.contorno(0.5)
    return t.imagem()


def cerca():
    t = Tela(48, 24)
    for x in range(2, 48, 11):
        t.ret(x, 4, x + 2, 22, MADEIRA)
        t.p(x + 1, 3, MADEIRA)
        t.ret(x, 4, x, 22, escurecer(MADEIRA, 0.8))
    for y in (8, 15):
        t.ret(0, y, 47, y + 1, rgb("a8743f"))
        t.lh(0, 47, y + 1, escurecer(MADEIRA, 0.85))
    t.contorno(0.5)
    return t.imagem()


def carroca():
    t = Tela(48, 32)
    madeira_c, madeira_s = rgb("a8743f"), rgb("5e3c22")
    t.ret(6, 12, 39, 20, MADEIRA)
    for y in (14, 17):
        t.lh(6, 39, y, madeira_s)
    t.lh(6, 39, 12, madeira_c)
    t.ret(6, 12, 7, 20, madeira_s)
    t.ret(38, 12, 39, 20, madeira_s)
    t.ret(40, 17, 47, 18, MADEIRA)
    # caixote com frascos de vacina
    t.ret(10, 7, 22, 11, rgb("c49a62"))
    t.lh(10, 22, 7, rgb("dab47a"))
    for x in range(11, 22, 3):
        t.ret(x, 3, x + 1, 6, VIDRO)
        t.lh(x, x + 1, 2, rgb("b08850"))
        t.p(x, 4, clarear(VIDRO, 0.5))
    t.ret(25, 8, 33, 11, rgb("d9b46a"))   # saco
    t.lh(26, 32, 8, clarear(rgb("d9b46a"), 0.3))
    cx, cy, r = 16, 24, 7
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = math.hypot(x - cx, y - cy)
            if r - 1.5 <= d <= r:
                t.p(x, y, madeira_s)
            elif d < 1.5:
                t.p(x, y, rgb("3a2a1a"))
    for i in range(-r + 2, r - 1):
        t.p(cx + i, cy, madeira_s)
        t.p(cx, cy + i, madeira_s)
    t.contorno(0.5)
    return t.imagem()


def barril():
    t = Tela(16, 24)
    t.elipse(7.5, 12, 6.5, 10, MADEIRA)
    for x in range(1, 15):
        for y in range(2, 23):
            if t.px[y][x][3] and x in (3, 7, 11):
                t.p(x, y, escurecer(MADEIRA, 0.85))
    for y in (5, 18):
        t.lh(1, 14, y, rgb("4a4a52"))
    t.elipse(7.5, 3, 5, 1.5, rgb("a8743f"))
    t.contorno(0.5)
    return t.imagem()


def pedra():
    t = Tela(16, 16)
    t.elipse(7.5, 10, 6.5, 4.5, rgb("8a8478"))
    t.elipse(6.5, 9, 4, 2.5, rgb("a8a090"))
    t.lh(4, 7, 8, rgb("c4bcac"))
    t.contorno(0.5)
    return t.imagem()


def tronco_caido():
    t = Tela(32, 16)
    t.ret(3, 6, 27, 12, rgb("6b4a32"))
    t.lh(4, 26, 6, rgb("8a6444"))
    for x in range(5, 26, 5):
        t.p(x, 9, rgb("4e3424"))
        t.p(x + 1, 10, rgb("4e3424"))
    t.elipse(28, 9, 2.5, 3.5, rgb("c8a070"))
    t.p(28, 9, rgb("8a6444"))
    t.ret(10, 4, 11, 5, VERDES[1])
    t.contorno(0.5)
    return t.imagem()


def poco():
    t = Tela(32, 32)
    pedra_c, pedra_s = rgb("a8a090"), rgb("7a7468")
    t.ret(5, 16, 26, 28, pedra_c)
    for y in range(17, 29, 3):
        for x in range(5 + (y % 2) * 2, 27, 5):
            t.ret(x, y, x, y + 1, pedra_s)
        t.lh(5, 26, y + 2, pedra_s)
    t.elipse(15.5, 16, 10.5, 3.5, pedra_c)
    t.elipse(15.5, 16, 8, 2.2, rgb("1e2430"))
    t.ret(6, 3, 7, 16, MADEIRA)
    t.ret(24, 3, 25, 16, MADEIRA)
    t.ret(6, 3, 25, 4, rgb("a8743f"))
    t.ret(15, 5, 15, 10, rgb("c4b494"))   # corda
    t.ret(13, 10, 17, 13, rgb("7a6a5a"))  # balde
    t.contorno(0.5)
    return t.imagem()


def caixote():
    t = Tela(16, 16)
    t.ret(2, 4, 13, 14, rgb("a8743f"))
    t.lh(2, 13, 4, rgb("c49a62"))
    for y in (8, 11):
        t.lh(2, 13, y, MADEIRA)
    t.ret(2, 4, 2, 14, MADEIRA)
    t.ret(13, 4, 13, 14, MADEIRA)
    for i in range(10):
        t.p(3 + i, 13 - i, rgb("7a5232"))
    t.contorno(0.5)
    return t.imagem()


OBJETOS = {
    "cajueiro_grande": cajueiro_grande,
    "cajueiro_pequeno": cajueiro_pequeno,
    "coqueiro_alto": lambda: coqueiro(True),
    "coqueiro_baixo": lambda: coqueiro(False),
    "moita": moita,
    "arbusto_flores": arbusto_flores,
    "casa_taipa_porta": casa_taipa_porta,
    "casa_taipa_janela": casa_taipa_janela,
    "cerca": cerca,
    "carroca": carroca,
    "barril": barril,
    "pedra": pedra,
    "tronco_caido": tronco_caido,
    "poco": poco,
    "caixote": caixote,
}


# ---------------------------------------------------------------- tiles 16x16

GRAMA = rgb("6a9a44")
GRAMA_P = [rgb("5a8a3a"), rgb("7eae52"), rgb("4a7a30")]
AREIA = rgb("e2c48c")
AREIA_P = [rgb("d4b47a"), rgb("ecd4a2"), rgb("c9a86c")]
TERRA = rgb("b48a5a")
TERRA_P = [rgb("a07a4a"), rgb("c49a68"), rgb("8e6a40")]
BORDA = rgb("4a7a30")


def _ondulacao(i):
    """Deslocamento da borda grama/areia; depende só da posição ao longo da borda,
    então tiles vizinhos do mesmo tipo emendam sem costura."""
    return (0, 1, 1, 0, -1, 0, 1, 0, 0, -1, -1, 0, 1, 1, 0, -1)[i % 16]


def _tile_misto(rnd, e_grama):
    im = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            g = e_grama(x, y)
            base, pontos = (GRAMA, GRAMA_P) if g else (AREIA, AREIA_P)
            im.putpixel((x, y), rnd.choice(pontos) if rnd.random() < 0.16 else base)
    # contorno escuro da grama onde ela encosta na areia
    for y in range(16):
        for x in range(16):
            if e_grama(x, y) and any(0 <= x + dx < 16 and 0 <= y + dy < 16 and not e_grama(x + dx, y + dy)
                                     for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                im.putpixel((x, y), BORDA)
    return im


def _tile_liso(rnd, base, pontos, n):
    im = Image.new("RGBA", (16, 16), base)
    for _ in range(n):
        im.putpixel((rnd.randint(0, 15), rnd.randint(0, 15)), rnd.choice(pontos))
    return im


def _tile_mato_denso(rnd):
    """Mato fechado (obstáculo): tufos escuros que se repetem sem emenda."""
    im = Image.new("RGBA", (16, 16), rgb("2f6b35"))
    tufos = [(2, 3), (9, 1), (13, 7), (5, 10), (11, 13), (0, 13), (7, 6)]
    for cx, cy in tufos:
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if abs(dx) + abs(dy) <= 2:
                    x, y = (cx + dx) % 16, (cy + dy) % 16
                    im.putpixel((x, y), VERDES[1] if dy < 1 else VERDES[3])
        im.putpixel((cx % 16, (cy - 1) % 16), VERDES[2])
    for _ in range(14):
        im.putpixel((rnd.randint(0, 15), rnd.randint(0, 15)), rnd.choice([VERDES[0], VERDES[3]]))
    return im


def _tile_telhado(rnd):
    """Telhado de palha visto de cima: fiadas de palha que emendam nas 4 direções."""
    palha, palha_c, palha_s = rgb("d8b45c"), rgb("ecd08a"), rgb("a8843c")
    im = Image.new("RGBA", (16, 16), palha)
    for y in range(16):
        for x in range(16):
            if y % 4 == 3:
                im.putpixel((x, y), palha_s)            # sombra de cada fiada
            elif (x + (y // 4) * 2) % 4 == 0:
                im.putpixel((x, y), palha_c)            # fios de palha
    for _ in range(10):
        x, y = rnd.randint(0, 15), rnd.randint(0, 15)
        if y % 4 != 3:
            im.putpixel((x, y), palha_s)
    return im


def _tile_taipa(rnd, rachada):
    im = _tile_liso(rnd, rgb("b07a4a"), [rgb("c8925c"), rgb("8a5a34")], 40)
    for y in (0, 8):
        for x in range(16):
            im.putpixel((x, y), rgb("8a5a34"))
    if rachada:
        for x, y in [(5, 2), (6, 3), (6, 4), (7, 5), (7, 6)]:
            im.putpixel((x, y), rgb("6b4a32"))
        for x in range(9, 14):
            for y in range(10, 14):
                im.putpixel((x, y), rgb("6b4a32") if y % 2 == 0 else rgb("a88a5a"))
    return im


def tiles():
    """Atlas 8x3 de tiles 16x16. A linha 0 tem as MESMAS posições do placeholder do I1
    (assim o mapa fase_1904.tscn troca de visual sem ser repintado):
    (0,0) areia   (1,0) grama   (2,0) terra batida/trilha   (3,0) mato denso (colisão)
    (4,0) parede de taipa (colisão)   (5,0) telhado de palha (colisão)
    (6,0) areia 2   (7,0) grama 2
    Borda grama/areia (grama por fora, areia por dentro):
    (0,1) canto NO  (1,1) borda N  (2,1) canto NE  (3,1) canto interno NO  (4,1) canto interno NE
    (5,1) canto SO  (6,1) borda S  (7,1) canto SE
    (0,2) borda O   (1,2) areia    (2,2) borda L   (3,2) canto interno SO  (4,2) canto interno SE
    (5,2) terra batida 2   (6,2) taipa rachada (colisão)
    """
    rnd = random.Random(7)
    folha = Image.new("RGBA", (16 * 8, 16 * 3))

    def put(im, c, l):
        folha.paste(im, (c * 16, l * 16))

    put(_tile_liso(rnd, AREIA, AREIA_P, 24), 0, 0)
    put(_tile_liso(rnd, GRAMA, GRAMA_P, 44), 1, 0)
    put(_tile_liso(rnd, TERRA, TERRA_P, 30), 2, 0)
    put(_tile_mato_denso(rnd), 3, 0)
    put(_tile_taipa(rnd, False), 4, 0)
    put(_tile_telhado(rnd), 5, 0)
    a2 = _tile_liso(rnd, AREIA, AREIA_P, 18)
    for x, y in [(3, 5), (12, 3), (8, 12)]:
        a2.putpixel((x, y), rgb("f0dcb0"))
        a2.putpixel((x + 1, y), rgb("a8a090"))
    put(a2, 6, 0)
    g2 = _tile_liso(rnd, GRAMA, GRAMA_P, 30)
    for x, y in [(3, 5), (4, 4), (11, 10), (12, 9)]:
        g2.putpixel((x, y), rgb("8ec060"))
    put(g2, 7, 0)
    t2 = _tile_liso(rnd, TERRA, TERRA_P, 22)
    for x in range(16):
        t2.putpixel((x, 5), TERRA_P[2] if x % 3 else TERRA_P[0])
        t2.putpixel((x, 11), TERRA_P[2] if (x + 1) % 3 else TERRA_P[0])
    put(t2, 5, 2)
    put(_tile_taipa(rnd, True), 6, 2)

    B = 4  # largura da faixa de grama nas bordas
    o = _ondulacao
    def n(x, y):  return y < B + o(x)
    def s(x, y):  return y > 15 - B - o(x)
    def w(x, y):  return x < B + o(y)
    def e(x, y):  return x > 15 - B - o(y)
    formas = {
        (0, 1): lambda x, y: n(x, y) or w(x, y),
        (1, 1): n,
        (2, 1): lambda x, y: n(x, y) or e(x, y),
        (0, 2): w,
        (1, 2): lambda x, y: False,
        (2, 2): e,
        (5, 1): lambda x, y: s(x, y) or w(x, y),
        (6, 1): s,
        (7, 1): lambda x, y: s(x, y) or e(x, y),
        (3, 1): lambda x, y: x ** 2 + y ** 2 < (B + 0.5) ** 2,
        (4, 1): lambda x, y: (x - 15) ** 2 + y ** 2 < (B + 0.5) ** 2,
        (3, 2): lambda x, y: x ** 2 + (y - 15) ** 2 < (B + 0.5) ** 2,
        (4, 2): lambda x, y: (x - 15) ** 2 + (y - 15) ** 2 < (B + 0.5) ** 2,
    }
    for (c, l), f in formas.items():
        put(_tile_misto(rnd, f), c, l)
    return folha


# ---------------------------------------------------------------- main

def main():
    os.makedirs(PASTA_OBJETOS, exist_ok=True)
    os.makedirs(PASTA_TILES, exist_ok=True)
    for nome, pessoa in PERSONAGENS.items():
        folha_personagem(pessoa).save(os.path.join(PASTA_SPRITES, nome + ".png"))
    for nome, func in OBJETOS.items():
        func().save(os.path.join(PASTA_OBJETOS, nome + ".png"))
    tiles().save(os.path.join(PASTA_TILES, "tiles_1904.png"))
    print("Arte da fase 1904 gerada.")


if __name__ == "__main__":
    main()
