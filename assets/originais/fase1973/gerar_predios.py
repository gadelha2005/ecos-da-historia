"""Gera a arte em pixel art das casas de taipa (1904) e dos prédios do campus (1973).

Uso (na raiz do repositório):  python assets/originais/fase1973/gerar_predios.py
Saída: assets/sprites/fase1904/casa_taipa_*.png e assets/sprites/fase1973/predio_*.png
Paleta curta e contorno escuro, no estilo GBA do resto do jogo. Dá para retocar no LibreSprite.
"""
import random
from PIL import Image, ImageDraw

RAIZ = "assets/sprites"
CONTORNO = (46, 34, 30, 255)


def nova(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def ret(d, x0, y0, x1, y1, cor):
    """Retângulo cheio com cantos inclusivos."""
    if x1 >= x0 and y1 >= y0:
        d.rectangle([x0, y0, x1, y1], fill=cor)


def contorno(d, x0, y0, x1, y1, cor=CONTORNO):
    d.rectangle([x0, y0, x1, y1], outline=cor)


def ruido(img, x0, y0, x1, y1, cores, chance, rng):
    px = img.load()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if rng.random() < chance:
                px[x, y] = rng.choice(cores)


# ---------------------------------------------------------------- 1904: casa de taipa

def casa_taipa(telhado, semente):
    rng = random.Random(semente)
    w, h = 64, 56
    img = nova(w, h)
    d = ImageDraw.Draw(img)
    barro = [(198, 150, 98, 255), (184, 136, 86, 255), (170, 122, 76, 255)]
    barro_esc = (138, 96, 60, 255)
    vara = (104, 72, 44, 255)
    vara_cl = (132, 94, 58, 255)

    # sombra no chão
    ret(d, 4, 53, 61, 55, (0, 0, 0, 60))
    # paredes
    px0, py0, px1, py1 = 3, 22, 60, 53
    ret(d, px0, py0, px1, py1, barro[1])
    ruido(img, px0, py0, px1, py1, barro, 0.35, rng)
    ret(d, px0, py1 - 3, px1, py1, barro_esc)                      # respingo de chão
    ruido(img, px0, py1 - 5, px1, py1 - 4, [barro_esc], 0.4, rng)
    # reboco caído mostrando a trama de varas (pau a pique)
    for (cx, cy, cw, ch) in [(rng.randint(28, 34), 26, 9, 7), (rng.randint(50, 53), 40, 6, 8)]:
        ret(d, cx, cy, cx + cw, cy + ch, (92, 64, 40, 255))
        for yy in range(cy + 1, cy + ch, 3):
            d.line([cx, yy, cx + cw, yy], fill=vara_cl)
        for xx in range(cx + 1, cx + cw, 3):
            d.line([xx, cy, xx, cy + ch], fill=vara)
        contorno(d, cx - 1, cy - 1, cx + cw + 1, cy + ch + 1, barro_esc)
    # rachaduras
    for _ in range(3):
        x, y = rng.randint(6, 56), rng.randint(30, 48)
        for _ in range(4):
            img.putpixel((x, y), barro_esc)
            x += rng.choice([-1, 0, 1]); y += 1
    contorno(d, px0, py0, px1, py1)

    # porta de tábuas
    dx0, dy0, dx1, dy1 = 11, 33, 23, 53
    ret(d, dx0, dy0, dx1, dy1, (110, 70, 40, 255))
    for xx in range(dx0 + 3, dx1, 3):
        d.line([xx, dy0, xx, dy1], fill=(84, 52, 30, 255))
    ret(d, dx0, dy0, dx1, dy0 + 1, (84, 52, 30, 255))
    img.putpixel((dx1 - 2, 44), (210, 180, 90, 255))                # tramela
    contorno(d, dx0 - 1, dy0 - 1, dx1 + 1, dy1, (70, 44, 26, 255))

    # janela com uma folha aberta
    jx0, jy0, jx1, jy1 = 38, 32, 47, 41
    ret(d, jx0, jy0, jx1, jy1, (40, 28, 22, 255))
    ret(d, jx0 + 1, jy0 + 1, jx0 + 4, jy1 - 1, (58, 40, 30, 255))
    ret(d, jx1 + 1, jy0, jx1 + 4, jy1, (120, 78, 44, 255))          # folha aberta
    d.line([jx1 + 2, jy0 + 1, jx1 + 2, jy1 - 1], fill=(90, 58, 32, 255))
    contorno(d, jx0 - 1, jy0 - 1, jx1 + 1, jy1 + 1, (84, 56, 34, 255))
    ret(d, jx0 - 1, jy1 + 2, jx1 + 1, jy1 + 2, barro_esc)            # peitoril

    # sombra do beiral
    ret(d, px0 + 1, py0 + 1, px1 - 1, py0 + 2, (120, 84, 52, 255))

    # telhado
    if telhado == "palha":
        claro, medio, escuro = (232, 200, 122, 255), (204, 166, 88, 255), (158, 120, 58, 255)
        for y in range(1, 25):
            a = 7 - (y * 7) // 24
            x0, x1 = a, w - 1 - a
            for x in range(x0, x1 + 1):
                c = medio
                if (x + (y // 3)) % 4 == 0:
                    c = escuro
                elif (x * 7 + y) % 5 == 0:
                    c = claro
                if x > w // 2 + 6:
                    c = tuple(max(0, v - 18) if i < 3 else v for i, v in enumerate(c))
                img.putpixel((x, y), c)
        # franja irregular
        for x in range(0, w):
            for y in range(24, 24 + rng.choice([0, 1, 1, 2])):
                img.putpixel((x, y), escuro)
        d.line([7, 1, w - 8, 1], fill=(120, 90, 42, 255))            # cumeeira
        d.line([7, 0, w - 8, 0], fill=CONTORNO)
        for y in range(1, 25):
            a = 7 - (y * 7) // 24
            img.putpixel((a, y), CONTORNO); img.putpixel((w - 1 - a, y), CONTORNO)
    else:  # telha de barro (capa e canal)
        telha, telha_cl, telha_esc = (178, 84, 52, 255), (206, 112, 70, 255), (128, 56, 36, 255)
        for y in range(1, 24):
            a = 6 - (y * 6) // 23
            for x in range(a, w - a):
                c = telha if (x // 3) % 2 == 0 else telha_esc
                if (x // 3) % 2 == 0 and x % 3 == 1:
                    c = telha_cl
                if y % 5 == 0:
                    c = telha_esc
                img.putpixel((x, y), c)
        d.line([6, 0, w - 7, 0], fill=CONTORNO)
        ret(d, 0, 23, w - 1, 24, telha_esc)
        d.line([0, 25, w - 1, 25], fill=CONTORNO)
        for y in range(1, 24):
            a = 6 - (y * 6) // 23
            img.putpixel((a, y), CONTORNO); img.putpixel((w - 1 - a, y), CONTORNO)
        ruido(img, 8, 2, w - 9, 20, [(150, 140, 90, 255)], 0.02, rng)  # limo
    # pontas dos caibros
    for x in range(6, w - 4, 8):
        ret(d, x, 25, x + 1, 26, (80, 54, 32, 255))
    return img


# ---------------------------------------------------------------- 1973: prédios do campus

CONCRETO = [(176, 174, 166, 255), (166, 164, 156, 255), (186, 184, 176, 255)]
CONCRETO_ESC = (124, 122, 116, 255)
VIDRO = (64, 92, 112, 255)
VIDRO_CL = (120, 160, 182, 255)
TIJOLO = [(170, 86, 58, 255), (156, 76, 50, 255), (184, 98, 66, 255)]


def laje(img, d, w, r, rng, extras=True):
    """Telhado plano de concreto visto de cima, com platibanda."""
    ret(d, 0, 0, w - 1, r - 1, CONCRETO[0])
    ruido(img, 2, 2, w - 3, r - 3, CONCRETO, 0.25, rng)
    ruido(img, 2, 2, w - 3, r - 3, [(150, 150, 142, 255)], 0.04, rng)  # manchas de chuva
    ret(d, 2, 2, w - 3, 3, (200, 198, 190, 255))
    contorno(d, 0, 0, w - 1, r - 1)
    d.rectangle([2, 2, w - 3, r - 3], outline=CONCRETO_ESC)
    if extras:
        # caixa d'água e respiros
        cx = rng.randint(8, w - 30)
        ret(d, cx, 6, cx + 17, 6 + min(14, r - 14), (150, 150, 146, 255))
        contorno(d, cx, 6, cx + 17, 6 + min(14, r - 14))
        ret(d, cx + 2, 8, cx + 15, 9, (196, 196, 190, 255))
        for i in range(2):
            vx = rng.randint(cx + 22, w - 10) if cx + 22 < w - 10 else 6 + i * 8
            ret(d, vx, r - 10, vx + 4, r - 7, (98, 98, 96, 255))
            contorno(d, vx, r - 10, vx + 4, r - 7)


def faixa_letreiro(d, w, y):
    ret(d, 0, y, w - 1, y + 9, (214, 212, 204, 255))
    d.line([0, y + 9, w - 1, y + 9], fill=CONCRETO_ESC)
    d.line([0, y, w - 1, y], fill=CONTORNO)


def base_fachada(img, d, w, y0, y1, rng, cores=CONCRETO):
    ret(d, 0, y0, w - 1, y1, cores[0])
    ruido(img, 1, y0, w - 2, y1, cores, 0.25, rng)


def porta_vidro(d, cx, y1, larg=16, alt=20):
    x0, x1 = cx - larg // 2, cx + larg // 2 - 1
    ret(d, x0 - 2, y1 - alt - 3, x1 + 2, y1 - alt - 1, CONCRETO_ESC)       # marquise
    ret(d, x0, y1 - alt, x1, y1, VIDRO)
    d.line([cx, y1 - alt, cx, y1], fill=(40, 40, 44, 255))
    d.line([x0 + 2, y1 - alt + 2, x0 + 2, y1 - 4], fill=VIDRO_CL)
    d.line([cx + 2, y1 - alt + 2, cx + 2, y1 - 4], fill=VIDRO_CL)
    contorno(d, x0 - 1, y1 - alt - 1, x1 + 1, y1, (40, 40, 44, 255))


def janelas(d, x0, x1, y0, y1, passo, larg, cor_vidro=VIDRO):
    for x in range(x0, x1 - larg + 1, passo):
        ret(d, x, y0, x + larg - 1, y1, cor_vidro)
        d.line([x + 1, y0 + 1, x + 1, y1 - 1], fill=VIDRO_CL)
        d.rectangle([x - 1, y0 - 1, x + larg, y1 + 1], outline=CONCRETO_ESC)


def brises(d, x0, x1, y0, y1, passo=6):
    """Brise-soleil vertical de concreto (bem típico dos anos 1970 em Fortaleza)."""
    ret(d, x0, y0, x1, y1, (52, 70, 84, 255))
    for x in range(x0, x1 + 1, passo):
        ret(d, x, y0, x + 2, y1, CONCRETO[2])
        d.line([x + 2, y0, x + 2, y1], fill=CONCRETO_ESC)
    d.rectangle([x0 - 1, y0 - 1, x1 + 1, y1 + 1], outline=CONTORNO)


def tijolos(img, d, x0, y0, x1, y1, rng):
    ret(d, x0, y0, x1, y1, (196, 180, 160, 255))                         # rejunte
    for y in range(y0, y1 + 1, 3):
        off = 0 if (y - y0) // 3 % 2 == 0 else 3
        for x in range(x0 - off, x1 + 1, 6):
            ret(d, max(x0, x), y, min(x1, x + 4), min(y1, y + 1), rng.choice(TIJOLO))


def fechar(d, w, h):
    contorno(d, 0, 0, w - 1, h - 1)


def biblioteca(rng):
    w, h, r = 160, 80, 30
    img = nova(w, h); d = ImageDraw.Draw(img)
    laje(img, d, w, r, rng)
    faixa_letreiro(d, w, r)
    y0 = r + 10
    base_fachada(img, d, w, y0, h - 1, rng)
    brises(d, 6, w - 8, y0 + 3, y0 + 18)
    tijolos(img, d, 1, h - 16, w - 2, h - 2, rng)                         # embasamento de tijolo
    porta_vidro(d, w // 2, h - 1, 16, 16)
    fechar(d, w, h)
    return img


def bloco_novo(rng):
    w, h, r = 160, 80, 30
    img = nova(w, h); d = ImageDraw.Draw(img)
    laje(img, d, w, r, rng, extras=False)
    # parte da laje ainda em obra: vergalhões espetados
    for x in range(108, 154, 5):
        d.line([x, 4, x, 10], fill=(120, 70, 40, 255))
        img.putpixel((x, 3), (90, 50, 30, 255))
    ret(d, 10, 8, 40, 20, (150, 140, 120, 255)); contorno(d, 10, 8, 40, 20)  # pilha de material
    for y in range(10, 20, 3):
        d.line([12, y, 38, y], fill=(126, 116, 96, 255))
    faixa_letreiro(d, w, r)
    y0 = r + 10
    base_fachada(img, d, w, y0, h - 1, rng)
    janelas(d, 8, 96, y0 + 4, y0 + 14, 14, 9)
    janelas(d, 8, 66, y0 + 22, y0 + 32, 14, 9)
    # lado direito ainda no tijolo, com vãos sem esquadria
    tijolos(img, d, 100, y0, w - 2, h - 2, rng)
    for x in (108, 126, 144):
        ret(d, x, y0 + 5, x + 8, y0 + 14, (34, 30, 30, 255))
    d.line([99, y0, 99, h - 1], fill=CONCRETO_ESC)
    porta_vidro(d, w // 2, h - 1, 14, 18)
    fechar(d, w, h)
    return img


def cantina(rng):
    w, h, r = 140, 90, 34
    img = nova(w, h); d = ImageDraw.Draw(img)
    laje(img, d, w, r, rng)
    faixa_letreiro(d, w, r)
    y0 = r + 10
    creme = [(226, 214, 186, 255), (216, 204, 176, 255), (234, 222, 196, 255)]
    base_fachada(img, d, w, y0, h - 1, rng, creme)
    # painel de azulejos azul e branco
    for y in range(y0 + 2, y0 + 14, 4):
        for x in range(4, w - 4, 4):
            c = (60, 104, 168, 255) if ((x // 4) + (y // 4)) % 2 == 0 else (232, 236, 240, 255)
            ret(d, x, y, x + 3, y + 3, c)
            img.putpixel((x + 1, y + 1), (40, 76, 140, 255) if c[0] == 60 else (180, 200, 226, 255))
    d.rectangle([3, y0 + 1, w - 4, y0 + 14], outline=CONCRETO_ESC)
    # balcão com toldo listrado
    ret(d, 10, y0 + 17, 56, y0 + 20, (220, 70, 60, 255))
    for x in range(10, 57, 6):
        ret(d, x, y0 + 17, x + 2, y0 + 20, (240, 236, 226, 255))
    ret(d, 12, y0 + 21, 54, y0 + 32, (60, 44, 34, 255))
    ret(d, 12, y0 + 33, 54, y0 + 36, (150, 104, 64, 255))               # balcão
    contorno(d, 11, y0 + 21, 55, y0 + 36)
    janelas(d, 90, w - 4, y0 + 20, y0 + 32, 14, 10)
    porta_vidro(d, w // 2 + 4, h - 1, 14, 18)
    fechar(d, w, h)
    return img


def auditorio(rng):
    w, h, r = 160, 90, 30
    img = nova(w, h); d = ImageDraw.Draw(img)
    # cobertura em duas águas de fibrocimento, vista de cima
    ret(d, 0, 0, w - 1, r - 1, (150, 152, 150, 255))
    for x in range(2, w - 2, 4):
        d.line([x, 2, x, r - 3], fill=(132, 134, 132, 255))
    d.line([2, r // 2, w - 3, r // 2], fill=(176, 178, 176, 255))
    contorno(d, 0, 0, w - 1, r - 1)
    faixa_letreiro(d, w, r)
    y0 = r + 10
    base_fachada(img, d, w, y0, h - 1, rng)
    for x in range(3, w - 3, 5):                                         # concreto frisado
        d.line([x, y0 + 1, x, h - 3], fill=CONCRETO_ESC)
    # painel em cores de serigrafia
    ret(d, 14, y0 + 6, 54, y0 + 30, (238, 228, 204, 255))
    ret(d, 18, y0 + 9, 38, y0 + 19, (216, 34, 120, 255))
    ret(d, 30, y0 + 14, 50, y0 + 24, (40, 170, 214, 220))
    ret(d, 22, y0 + 22, 40, y0 + 28, (244, 200, 30, 255))
    contorno(d, 13, y0 + 5, 55, y0 + 31)
    janelas(d, 110, w - 6, y0 + 8, y0 + 14, 12, 8)
    # porta dupla de madeira com marquise
    cx = w // 2
    ret(d, cx - 16, y0 + 10, cx + 15, y0 + 12, CONCRETO_ESC)
    ret(d, cx - 13, y0 + 13, cx + 12, h - 1, (112, 70, 40, 255))
    d.line([cx, y0 + 13, cx, h - 1], fill=(70, 44, 26, 255))
    for x in (cx - 8, cx + 7):
        d.line([x, y0 + 15, x, h - 4], fill=(90, 56, 32, 255))
    img.putpixel((cx - 2, y0 + 30), (220, 190, 90, 255)); img.putpixel((cx + 1, y0 + 30), (220, 190, 90, 255))
    contorno(d, cx - 14, y0 + 12, cx + 13, h - 1)
    fechar(d, w, h)
    return img


def andaime():
    w, h = 24, 72
    img = nova(w, h); d = ImageDraw.Draw(img)
    madeira, madeira_cl = (130, 88, 48, 255), (170, 122, 70, 255)
    for x in (1, 11, 21):
        ret(d, x, 0, x + 1, h - 1, madeira)
        d.line([x, 0, x, h - 1], fill=madeira_cl)
    for y in (14, 38, 62):
        ret(d, 0, y, w - 1, y + 2, (176, 132, 78, 255))
        d.line([0, y + 3, w - 1, y + 3], fill=(96, 62, 34, 255))
    for (y0, y1) in ((16, 38), (40, 62)):
        d.line([2, y0, 20, y1], fill=(110, 74, 40, 255))
    return img


if __name__ == "__main__":
    import os
    os.makedirs(f"{RAIZ}/fase1973", exist_ok=True)
    casa_taipa("palha", 1).save(f"{RAIZ}/fase1904/casa_taipa_palha.png")
    casa_taipa("telha", 2).save(f"{RAIZ}/fase1904/casa_taipa_telha.png")
    rng = random.Random(73)
    biblioteca(rng).save(f"{RAIZ}/fase1973/predio_biblioteca.png")
    bloco_novo(rng).save(f"{RAIZ}/fase1973/predio_bloco_novo.png")
    cantina(rng).save(f"{RAIZ}/fase1973/predio_cantina.png")
    auditorio(rng).save(f"{RAIZ}/fase1973/predio_auditorio.png")
    andaime().save(f"{RAIZ}/fase1973/andaime.png")
    print("ok")
