"""[L8b] Cenário da fase 1979: a mata ao lado da Unifor (Narrativa N3.1).

Mesmo estilo do resto do jogo (paleta curta, contorno escuro, sombra no chão):
- chao_1979.png (640x400): mata rasteira à esquerda, roça, lagoa, trilha, e à direita a terra
  raspada do loteamento com marcas de pneu.
- casa de taipa e casa de alvenaria caiada (comunidade), árvores da mata, mangueira grande
  (onde fica a mesa), cerca de arame farpado, placa do loteamento, trator, retroescavadeira,
  barracão de obra, mesa com bancos e pés de milho/mandioca.

Uso (na raiz do projeto):  python assets/originais/fase1979/gerar_cenario_1979.py
Saída: assets/sprites/fase1979/*.png
"""
from __future__ import annotations

import importlib.util
import math
import os
import random

from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(AQUI, "..", "..", ".."))
PASTA = os.path.join(RAIZ, "assets", "sprites", "fase1979")


def _carregar(nome, caminho):
    spec = importlib.util.spec_from_file_location(nome, os.path.join(AQUI, caminho))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


g = _carregar("arte1904", "../fase1904/gerar_arte_1904.py")
pr = _carregar("predios", "../fase1973/gerar_predios.py")
rgb, escurecer, clarear = g.rgb, g.escurecer, g.clarear
nova, ret, contorno, ruido, CONTORNO = pr.nova, pr.ret, pr.contorno, pr.ruido, pr.CONTORNO


def c(h, a=255):
    v = rgb(h)
    return (v[0], v[1], v[2], a)


# ---------------------------------------------------------------- chão (640x400)

LAGOA = (100, 322, 74, 42)          # centro x, y, raio x, raio y (o .tscn usa os mesmos números)
ROCA = (176, 168, 286, 236)         # x0, y0, x1, y1
CERCA_X = 320
OBRA_X = 336                         # a partir daqui é terra raspada


def chao():
    rng = random.Random(1979)
    w, h = 640, 400
    img = Image.new("RGBA", (w, h), c("4f8a3c"))
    px = img.load()
    capim = [c("4f8a3c"), c("5a9644"), c("467f36"), c("62a04a"), c("3f7431")]
    terra = [c("b88a5a"), c("a87a4c"), c("c49866"), c("9c7046")]
    for y in range(h):
        for x in range(w):
            if x >= OBRA_X + int(4 * math.sin(y / 23)):
                px[x, y] = rng.choice(terra) if rng.random() < 0.35 else terra[0]
            elif rng.random() < 0.45:
                px[x, y] = rng.choice(capim)
    # tufos de capim e florzinhas na parte da mata
    for _ in range(420):
        x, y = rng.randint(0, OBRA_X - 8), rng.randint(0, h - 3)
        px[x, y] = c("2f6b35")
        px[x, y + 1] = c("2f6b35")
        if rng.random() < 0.15:
            px[x + 1, y] = rng.choice([c("f0d040"), c("f4f0e8"), c("e87aa0")])
    d = ImageDraw.Draw(img)
    # marcas de pneu e poças secas na obra
    for x0 in (370, 384, 470, 484):
        for y in range(120, h, 2):
            xx = x0 + int(6 * math.sin(y / 40))
            if (y // 4) % 2 == 0:
                d.line([xx, y, xx + 3, y], fill=c("8a6440"))
    for _ in range(10):
        x, y = rng.randint(360, 620), rng.randint(140, 380)
        d.ellipse([x, y, x + rng.randint(8, 18), y + rng.randint(3, 6)], fill=c("94704c"))
    # trilha de terra que vem do portal (embaixo, no meio) e se divide para os dois lados
    trilha = c("c8a070")
    for t in range(0, 400):
        k = t / 400
        x = CERCA_X + int(math.sin(k * 6) * 10)
        y = h - t
        d.ellipse([x - 9, y - 3, x + 9, y + 3], fill=trilha)
    for t in range(0, 230):                      # ramal para a comunidade
        x = CERCA_X - t
        y = 275 - int(t * 0.35) + int(4 * math.sin(t / 15))
        d.ellipse([x - 7, y - 3, x + 7, y + 3], fill=trilha)
    ruido(img, 100, 150, 340, 399, [c("b08a5c")], 0.0, rng)
    # roça: canteiros de terra arada
    x0, y0, x1, y1 = ROCA
    ret(d, x0, y0, x1, y1, c("7a5232"))
    for y in range(y0 + 2, y1, 6):
        ret(d, x0 + 2, y, x1 - 2, y + 2, c("9a6a42"))
        ret(d, x0 + 2, y + 3, x1 - 2, y + 3, c("5e3e26"))
    contorno(d, x0, y0, x1, y1, c("5e3e26"))
    # lagoa com margem de areia, água em faixas e reflexos
    cx, cy, rx, ry = LAGOA
    d.ellipse([cx - rx - 6, cy - ry - 5, cx + rx + 6, cy + ry + 5], fill=c("d8c08a"))
    d.ellipse([cx - rx - 2, cy - ry - 2, cx + rx + 2, cy + ry + 2], fill=c("3f6f8a"))
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=c("3a7aa0"))
    d.ellipse([cx - rx + 10, cy - ry + 8, cx + rx - 10, cy + ry - 6], fill=c("4a8ab0"))
    d.ellipse([cx - rx + 30, cy - ry + 18, cx + rx - 30, cy + ry - 14], fill=c("3a7aa0"))
    for _ in range(26):
        x = rng.randint(cx - rx + 14, cx + rx - 20)
        y = rng.randint(cy - ry + 8, cy + ry - 8)
        d.line([x, y, x + rng.randint(3, 7), y], fill=c("a8d4e8"))
    for ang in range(0, 360, 14):                # juncos na margem
        a = math.radians(ang)
        x = int(cx + math.cos(a) * (rx + 3))
        y = int(cy + math.sin(a) * (ry + 2))
        if rng.random() < 0.6:
            d.line([x, y, x, y - rng.randint(3, 6)], fill=c("2f6b35"))
            px[x, y - 6] = c("6a4a2a")
    # chão batido em volta da árvore grande e da mesa
    d.ellipse([CERCA_X - 60, 54, CERCA_X + 60, 136], fill=c("a88a5a"))
    d.ellipse([CERCA_X - 54, 58, CERCA_X + 54, 132], fill=c("b89a66"))
    ruido(img, CERCA_X - 50, 60, CERCA_X + 50, 128, [c("a88a5a"), c("c8aa76")], 0.25, rng)
    return img


# ---------------------------------------------------------------- comunidade

def casa_alvenaria(semente):
    """Casa de tijolo caiada, barra azul embaixo, telha de barro e alpendre."""
    rng = random.Random(semente)
    w, h = 72, 58
    img = nova(w, h)
    d = ImageDraw.Draw(img)
    cal = [c("eee6d4"), c("e4dcc8"), c("f4eee0")]
    ret(d, 4, 55, w - 4, 57, (0, 0, 0, 60))
    x0, y0, x1, y1 = 4, 24, w - 5, 55
    ret(d, x0, y0, x1, y1, cal[0])
    ruido(img, x0, y0, x1, y1, cal, 0.25, rng)
    ret(d, x0, y1 - 8, x1, y1, c("3a6ab0"))                       # barra azul
    ruido(img, x0, y1 - 8, x1, y1, [c("2e5a98")], 0.2, rng)
    for _ in range(4):                                            # reboco descascado
        xx, yy = rng.randint(x0 + 4, x1 - 8), rng.randint(y0 + 4, y1 - 14)
        ret(d, xx, yy, xx + 3, yy + 2, c("b86a48"))
    contorno(d, x0, y0, x1, y1)
    # porta verde e duas janelas de madeira
    ret(d, 30, 36, 41, 55, c("2f7a4a"))
    d.line([35, 36, 35, 55], fill=c("23603a"))
    img.putpixel((39, 46), c("e0c050"))
    contorno(d, 29, 35, 42, 55, c("1e4a2e"))
    for jx in (10, 52):
        ret(d, jx, 34, jx + 10, 44, c("2f7a4a"))
        d.line([jx + 5, 34, jx + 5, 44], fill=c("23603a"))
        contorno(d, jx - 1, 33, jx + 11, 45, c("1e4a2e"))
        ret(d, jx - 1, 46, jx + 11, 46, c("c8c0ac"))
    # telhado de duas águas, telha capa e canal
    telha, telha_cl, telha_esc = c("b65a36"), c("d07a4a"), c("82402a")
    for y in range(2, 25):
        a = 8 - (y * 8) // 24
        for x in range(a, w - a):
            cor = telha if (x // 3) % 2 == 0 else telha_esc
            if (x // 3) % 2 == 0 and x % 3 == 1:
                cor = telha_cl
            if y % 5 == 0:
                cor = telha_esc
            img.putpixel((x, y), cor)
    d.line([8, 1, w - 9, 1], fill=CONTORNO)
    ret(d, 0, 24, w - 1, 25, telha_esc)
    d.line([0, 26, w - 1, 26], fill=CONTORNO)
    for y in range(2, 25):
        a = 8 - (y * 8) // 24
        img.putpixel((a, y), CONTORNO)
        img.putpixel((w - 1 - a, y), CONTORNO)
    ruido(img, 10, 3, w - 11, 20, [c("8a8a5a")], 0.02, rng)
    return img


def arvore_mata(semente, alta=True):
    """Árvore nativa de mata (copa irregular em camadas, tronco claro com manchas)."""
    rnd = random.Random(semente)
    t = g.Tela(40, 56 if alta else 44)
    base = t.h - 2
    tronco, tronco_s, tronco_c = rgb("7a6250"), rgb("54402e"), rgb("a08a72")
    for y in range(base - 22, base + 1):
        x = 18 + (1 if y < base - 14 else 0)
        t.ret(x, y, x + 3, y, tronco)
        t.p(x, y, tronco_s)
        if y % 5 == 0:
            t.p(x + 2, y, tronco_c)
    t.ret(15, base - 1, 24, base, tronco_s)
    t.ret(22, base - 18, 27, base - 17, tronco)
    topo = 4
    meio = (base - 22 + topo) // 2 + 2
    blocos = [(20, meio, 15, 11), (10, meio + 4, 9, 7), (30, meio + 3, 9, 7),
              (16, meio - 8, 10, 7), (26, meio - 7, 10, 7), (20, topo + 6, 8, 5)]
    g._copa(t, [(x + rnd.randint(-1, 1), y, rx, ry) for x, y, rx, ry in blocos], rnd, 120)
    t.contorno(0.5)
    return t.imagem()


def mangueira_grande():
    """A árvore grande da mesa (N3.6): copa larga e escura, sombra forte."""
    rnd = random.Random(42)
    t = g.Tela(96, 80)
    tronco, tronco_s = rgb("5e4432"), rgb("3e2c20")
    for y in range(44, 78):
        larg = 6 + (78 - y) // 12
        x = 46 - larg // 2
        t.ret(x, y, x + larg, y, tronco)
        t.p(x, y, tronco_s)
        t.p(x + larg - 1, y, tronco_s)
    t.ret(36, 76, 58, 78, tronco_s)
    t.ret(50, 48, 64, 50, tronco)
    t.ret(30, 50, 44, 52, tronco)
    g._copa(t, [(48, 28, 40, 18), (22, 36, 18, 12), (74, 36, 18, 12), (36, 16, 18, 12),
                (62, 16, 18, 12), (48, 10, 14, 8), (48, 44, 30, 8)], rnd, 360)
    for x, y in [(20, 40), (70, 42), (40, 30), (58, 24), (30, 22), (78, 34)]:  # mangas
        t.ret(x, y, x + 1, y + 2, rgb("e8a030"))
        t.p(x, y, rgb("a8b030"))
    t.contorno(0.5)
    return t.imagem()


def mesa_acordo():
    """Mesa comprida de madeira com dois bancos (um para cada lado)."""
    w, h = 56, 30
    img = nova(w, h)
    d = ImageDraw.Draw(img)
    mad, mad_cl, mad_esc = c("9a6a3e"), c("b8844e"), c("6a4428")
    ret(d, 2, 26, w - 3, 29, (0, 0, 0, 60))
    for bx in (2, w - 12):                                        # bancos
        ret(d, bx, 10, bx + 9, 13, mad)
        ret(d, bx + 1, 14, bx + 2, 24, mad_esc)
        ret(d, bx + 7, 14, bx + 8, 24, mad_esc)
        contorno(d, bx - 1, 9, bx + 10, 14)
    ret(d, 12, 6, w - 13, 13, mad_cl)                             # tampo
    for y in (8, 11):
        d.line([13, y, w - 14, y], fill=mad)
    ret(d, 12, 14, w - 13, 15, mad_esc)
    for lx in (14, w - 16):
        ret(d, lx, 16, lx + 1, 26, mad_esc)
    contorno(d, 11, 5, w - 12, 16)
    ret(d, 22, 7, 31, 11, c("f2eee0"))                            # papel do acordo
    d.line([23, 8, 29, 8], fill=c("8a8a90"))
    d.line([23, 10, 28, 10], fill=c("8a8a90"))
    ret(d, 34, 8, 35, 10, c("2a3a8a"))                            # caneta
    return img


def pe_milho(semente):
    rng = random.Random(semente)
    t = g.Tela(12, 20)
    caule, folha, folha_c = rgb("6a8a2a"), rgb("4a7a2a"), rgb("8ab040")
    t.ret(5, 3, 6, 19, caule)
    for y, lado in [(6, -1), (9, 1), (12, -1), (15, 1)]:
        for i in range(4):
            t.p(5 + lado * (i + 1) + (1 if lado > 0 else 0), y + i // 2, folha if i < 3 else folha_c)
    t.ret(4, 0, 7, 3, rgb("c8b050"))                              # pendão
    if rng.random() < 0.7:
        t.ret(7, 10, 8, 13, rgb("e8d080"))                        # espiga
    t.contorno(0.5)
    return t.imagem()


# ---------------------------------------------------------------- cerca, placa e obra

def cerca_vertical(altura):
    """Cerca de arame farpado nova (mourões de madeira a cada 16 px), vista de cima/lado."""
    w = 10
    img = nova(w, altura)
    d = ImageDraw.Draw(img)
    for y in range(0, altura, 16):
        ret(d, 3, y, 6, y + 9, c("8a6a42"))
        ret(d, 3, y, 6, y + 1, c("b08a5a"))
        contorno(d, 2, y - 1, 7, y + 10)
    for x in (1, 4, 8):                                           # três fios de arame
        for y in range(0, altura):
            if img.getpixel((x, y))[3] == 0:
                img.putpixel((x, y), c("9a9aa0"))
            if y % 5 == 0:
                img.putpixel((x, y), c("5a5a60"))
    return img


def placa_loteamento():
    w, h = 64, 44
    img = nova(w, h)
    d = ImageDraw.Draw(img)
    ret(d, 6, 41, w - 7, 43, (0, 0, 0, 60))
    for px_ in (12, w - 15):                                      # pés
        ret(d, px_, 22, px_ + 2, 42, c("6a4a2a"))
        contorno(d, px_ - 1, 22, px_ + 3, 42)
    ret(d, 2, 2, w - 3, 24, c("f4f0e4"))
    ret(d, 2, 2, w - 3, 8, c("c8302a"))
    contorno(d, 1, 1, w - 2, 25)
    # "LOTEAMENTO" em letras de 1 px (só sugerido) e um desenho de lotes
    for i, x in enumerate(range(6, w - 6, 4)):
        ret(d, x, 4, x + 2, 6, c("f4f0e4"))
    for y in (11, 14):
        for x in range(6, w - 26, 3):
            d.point([x, y], fill=c("3a3a40"))
    for gx in range(w - 24, w - 6, 6):                            # quadrinhas de lote
        for gy in (11, 17):
            contorno(d, gx, gy, gx + 4, gy + 4, c("2a6ab8"))
    ret(d, 6, 19, 26, 21, c("f0c020"))                            # "VENDE-SE"
    return img


def trator():
    """Trator de esteira amarelo com a lâmina abaixada."""
    w, h = 56, 40
    img = nova(w, h)
    d = ImageDraw.Draw(img)
    am, am_cl, am_esc = c("e8b020"), c("f8d050"), c("a87810")
    ret(d, 4, 37, w - 4, 39, (0, 0, 0, 70))
    ret(d, 6, 26, 46, 36, c("2a2a2e"))                            # esteira
    for x in range(7, 46, 4):
        ret(d, x, 27, x + 1, 35, c("4a4a50"))
    for x in (11, 21, 31, 41):
        d.ellipse([x - 3, 28, x + 3, 34], fill=c("6a6a70"))
    contorno(d, 5, 25, 47, 37)
    ret(d, 8, 14, 42, 25, am)                                     # corpo
    ret(d, 8, 14, 42, 15, am_cl)
    ret(d, 8, 23, 42, 25, am_esc)
    for x in range(30, 41, 3):
        d.line([x, 17, x, 22], fill=am_esc)                       # grade do motor
    contorno(d, 7, 13, 43, 26)
    ret(d, 12, 2, 26, 13, am_esc)                                 # cabine
    ret(d, 14, 4, 24, 10, c("8ac0d8"))
    d.line([14, 4, 18, 4], fill=c("d8f0f8"))
    contorno(d, 11, 1, 27, 14)
    ret(d, 36, 6, 38, 13, c("3a3a3e"))                            # escapamento
    ret(d, 36, 4, 38, 5, c("5a5a5e"))
    ret(d, 46, 16, w - 3, 36, am)                                 # lâmina
    ret(d, 46, 33, w - 3, 36, c("8a8a90"))
    contorno(d, 45, 15, w - 2, 37)
    d.line([42, 20, 46, 24], fill=c("3a3a3e"))
    return img


def retroescavadeira():
    w, h = 72, 48
    img = nova(w, h)
    d = ImageDraw.Draw(img)
    am, am_cl, am_esc = c("e8b020"), c("f8d050"), c("a87810")
    ret(d, 6, 45, w - 8, 47, (0, 0, 0, 70))
    ret(d, 10, 26, 52, 36, am)                                    # chassi
    ret(d, 10, 26, 52, 27, am_cl)
    contorno(d, 9, 25, 53, 37)
    ret(d, 26, 8, 42, 25, am_esc)                                 # cabine
    ret(d, 28, 10, 40, 20, c("8ac0d8"))
    d.line([28, 10, 33, 10], fill=c("d8f0f8"))
    contorno(d, 25, 7, 43, 26)
    for cx_, r in ((18, 9), (46, 7)):                             # rodas
        d.ellipse([cx_ - r, 44 - 2 * r, cx_ + r, 44], fill=c("2a2a2e"))
        d.ellipse([cx_ - r + 4, 48 - 2 * r, cx_ + r - 4, 40], fill=c("8a8a90"))
    ret(d, 0, 30, 10, 38, c("8a8a90"))                            # pá da frente
    contorno(d, 0, 29, 11, 39)
    # braço da retro (atrás, para a direita)
    for i in range(18):
        x, y = 52 + i, 24 - i // 2
        ret(d, x, y, x + 2, y + 3, am)
    for i in range(14):
        x, y = 68 - i // 5, 15 + i
        ret(d, x, y, x + 2, y + 2, am_esc)
    ret(d, 62, 28, 70, 34, c("6a6a70"))                           # caçamba
    contorno(d, 61, 27, 71, 35)
    return img


def barracao_obra():
    """Barracão de tábuas com telhado de zinco e a placa da construtora."""
    rng = random.Random(7)
    w, h = 88, 60
    img = nova(w, h)
    d = ImageDraw.Draw(img)
    ret(d, 4, 57, w - 4, 59, (0, 0, 0, 60))
    x0, y0, x1, y1 = 4, 20, w - 5, 57
    ret(d, x0, y0, x1, y1, c("a07a4a"))
    for x in range(x0 + 4, x1, 5):
        d.line([x, y0, x, y1], fill=c("7a5a34"))
    ruido(img, x0, y0, x1, y1, [c("b08a58"), c("8a6a40")], 0.12, rng)
    contorno(d, x0, y0, x1, y1)
    ret(d, 14, 36, 27, 57, c("5a4028"))                           # porta
    contorno(d, 13, 35, 28, 57)
    ret(d, 50, 30, 76, 42, c("f4f0e4"))                           # placa da construtora
    ret(d, 50, 30, 76, 33, c("2a5a9a"))
    for x in range(53, 74, 3):
        d.point([x, 37], fill=c("3a3a40"))
    contorno(d, 49, 29, 77, 43)
    for y in range(2, 21):                                        # zinco ondulado
        for x in range(0, w):
            cor = c("b8bcc4") if (x // 2) % 2 == 0 else c("8a8e96")
            if y < 4 + (x * 0):
                cor = c("c8ccd4") if (x // 2) % 2 == 0 else c("9a9ea6")
            img.putpixel((x, y), cor)
    ruido(img, 0, 2, w - 1, 20, [c("a86a3a")], 0.03, rng)         # ferrugem
    contorno(d, 0, 1, w - 1, 21)
    for x in (14, 40, 66):                                        # sacos de cimento
        pass
    return img


def sacos_cimento():
    w, h = 28, 18
    img = nova(w, h)
    d = ImageDraw.Draw(img)
    ret(d, 1, 15, w - 2, 17, (0, 0, 0, 60))
    for i, (x, y) in enumerate([(2, 8), (13, 8), (7, 2)]):
        ret(d, x, y, x + 11, y + 6, c("d8ccb0"))
        ret(d, x + 3, y + 2, x + 8, y + 4, c("2a5a9a"))
        contorno(d, x - 1, y - 1, x + 12, y + 7)
    return img


def main():
    os.makedirs(PASTA, exist_ok=True)
    salvar = {
        "chao_1979.png": chao(),
        "casa_alvenaria.png": casa_alvenaria(3),
        "casa_taipa.png": pr.casa_taipa("telha", 79),
        "casa_taipa_palha.png": pr.casa_taipa("palha", 80),
        "arvore_mata_1.png": arvore_mata(1),
        "arvore_mata_2.png": arvore_mata(2),
        "arvore_mata_baixa.png": arvore_mata(3, alta=False),
        "mangueira_grande.png": mangueira_grande(),
        "mesa_acordo.png": mesa_acordo(),
        "pe_milho_1.png": pe_milho(1),
        "pe_milho_2.png": pe_milho(2),
        "cerca_arame.png": cerca_vertical(128),
        "placa_loteamento.png": placa_loteamento(),
        "trator.png": trator(),
        "retroescavadeira.png": retroescavadeira(),
        "barracao_obra.png": barracao_obra(),
        "sacos_cimento.png": sacos_cimento(),
    }
    for nome, im in salvar.items():
        im.save(os.path.join(PASTA, nome))
    print("Cenário da fase 1979 gerado:", ", ".join(salvar))


if __name__ == "__main__":
    main()
