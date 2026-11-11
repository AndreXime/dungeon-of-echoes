"""SFXs de combate para Dungeon Of Echoes."""

from engine.sfx import (
    dente_de_serra,
    envelope_adsr,
    exportar_ogg,
    misturar,
    quadrada,
    rampa_frequencia,
    ruido_branco,
    seno,
)


def _atrasar(audio, segundos):
    silencio = ruido_branco(segundos, amplitude=0.0)
    return misturar(silencio, audio, pico=0.95)


def swing():
    whoosh = ruido_branco(0.26, amplitude=0.72)
    whoosh = envelope_adsr(whoosh, attack=0.035, decay=0.05, sustain=0.5, release=0.15)
    corte = seno(rampa_frequencia(1500, 180, 0.2), 0.2, amplitude=0.32)
    corte = envelope_adsr(corte, attack=0.015, decay=0.04, sustain=0.3, release=0.11)
    ting = quadrada(rampa_frequencia(3400, 1600, 0.05), 0.05, amplitude=0.16)
    ting = envelope_adsr(ting, attack=0.001, decay=0.012, sustain=0.18, release=0.03)
    ting = _atrasar(ting, 0.07)
    return misturar(whoosh, corte, ting)


def hit():
    body = seno(rampa_frequencia(180, 55, 0.12), 0.12, amplitude=0.55)
    body = envelope_adsr(body, attack=0.002, decay=0.04, sustain=0.25, release=0.07)
    crack = ruido_branco(0.06, amplitude=0.85)
    crack = envelope_adsr(crack, attack=0.001, decay=0.02, sustain=0.15, release=0.03)
    thud = dente_de_serra(rampa_frequencia(90, 40, 0.1), 0.1, amplitude=0.28)
    thud = envelope_adsr(thud, attack=0.001, decay=0.03, sustain=0.2, release=0.05)
    return misturar(body, crack, thud)


def kill():
    impacto = hit()
    fall = seno(rampa_frequencia(220, 60, 0.28), 0.28, amplitude=0.35)
    fall = envelope_adsr(fall, attack=0.01, decay=0.08, sustain=0.35, release=0.14)
    shimmer = quadrada(rampa_frequencia(900, 300, 0.18), 0.18, amplitude=0.12)
    shimmer = envelope_adsr(shimmer, attack=0.02, decay=0.05, sustain=0.25, release=0.1)
    shimmer = _atrasar(shimmer, 0.05)
    return misturar(impacto, fall, shimmer)


def hurt():
    grit = seno(rampa_frequencia(320, 140, 0.18), 0.18, amplitude=0.4)
    grit = envelope_adsr(grit, attack=0.005, decay=0.05, sustain=0.4, release=0.1)
    noise = ruido_branco(0.14, amplitude=0.35)
    noise = envelope_adsr(noise, attack=0.002, decay=0.04, sustain=0.3, release=0.08)
    return misturar(grit, noise)


def break_prop():
    wood = ruido_branco(0.22, amplitude=0.7)
    wood = envelope_adsr(wood, attack=0.001, decay=0.05, sustain=0.35, release=0.14)
    crack = dente_de_serra(rampa_frequencia(400, 80, 0.16), 0.16, amplitude=0.3)
    crack = envelope_adsr(crack, attack=0.001, decay=0.04, sustain=0.25, release=0.09)
    bits = ruido_branco(0.12, amplitude=0.45)
    bits = envelope_adsr(bits, attack=0.01, decay=0.03, sustain=0.2, release=0.07)
    bits = _atrasar(bits, 0.04)
    return misturar(wood, crack, bits)


def block():
    clang = quadrada(rampa_frequencia(2400, 900, 0.09), 0.09, amplitude=0.35)
    clang = envelope_adsr(clang, attack=0.001, decay=0.02, sustain=0.25, release=0.05)
    ring = seno(rampa_frequencia(1800, 700, 0.14), 0.14, amplitude=0.22)
    ring = envelope_adsr(ring, attack=0.002, decay=0.03, sustain=0.3, release=0.08)
    thud = ruido_branco(0.05, amplitude=0.4)
    thud = envelope_adsr(thud, attack=0.001, decay=0.015, sustain=0.15, release=0.025)
    return misturar(clang, ring, thud)


def shoot():
    twang = seno(rampa_frequencia(900, 220, 0.14), 0.14, amplitude=0.4)
    twang = envelope_adsr(twang, attack=0.002, decay=0.03, sustain=0.3, release=0.08)
    click = quadrada(rampa_frequencia(2200, 1100, 0.04), 0.04, amplitude=0.22)
    click = envelope_adsr(click, attack=0.001, decay=0.01, sustain=0.15, release=0.02)
    air = ruido_branco(0.1, amplitude=0.25)
    air = envelope_adsr(air, attack=0.005, decay=0.03, sustain=0.2, release=0.05)
    air = _atrasar(air, 0.02)
    return misturar(twang, click, air)


def gerar():
    exportar_ogg(swing(), "swing.ogg")
    exportar_ogg(hit(), "hit.ogg")
    exportar_ogg(kill(), "kill.ogg")
    exportar_ogg(hurt(), "hurt.ogg")
    exportar_ogg(break_prop(), "break.ogg")
    exportar_ogg(block(), "block.ogg")
    exportar_ogg(shoot(), "shoot.ogg")


if __name__ == "__main__":
    gerar()
