"""Dungeon: catacumba tensa, loop escuro em Dm."""

import pretty_midi

from engine.musica import (
    adicionar_acorde,
    exportar_ogg,
    segundos_por_beat,
    segundos_por_compasso,
)

BPM = 118
BEAT = segundos_por_beat(BPM)
COMPASSO = segundos_por_compasso(BPM)
C = BEAT / 2
S = BEAT / 4

# Dm → Bb → F → C → Dm → Gm → A → Dm
PROGRESSAO = [
    {"root": 38, "chord": [50, 53, 57]},
    {"root": 34, "chord": [46, 50, 53]},
    {"root": 41, "chord": [53, 57, 60]},
    {"root": 36, "chord": [48, 52, 55]},
    {"root": 38, "chord": [50, 53, 57]},
    {"root": 43, "chord": [55, 58, 62]},
    {"root": 33, "chord": [45, 49, 52]},
    {"root": 38, "chord": [50, 53, 57]},
]

KICK, SNARE, HH, HH_OPEN, CRASH, TOM = 36, 38, 42, 46, 49, 45


def n(inst, pitch, inicio, duracao, velocity=90):
    inst.notes.append(
        pretty_midi.Note(
            velocity=velocity,
            pitch=pitch,
            start=inicio,
            end=inicio + duracao * 0.88,
        )
    )


def groove(bateria, inicio, intenso=False):
    for i in range(8):
        n(bateria, HH if i != 7 else HH_OPEN, inicio + i * C, S, velocity=48 + (i % 2) * 10)
    n(bateria, KICK, inicio, C, velocity=108 if intenso else 96)
    n(bateria, KICK, inicio + BEAT * 2.5, S, velocity=88)
    n(bateria, SNARE, inicio + BEAT, C, velocity=100 if intenso else 88)
    n(bateria, SNARE, inicio + BEAT * 3, C, velocity=92 if intenso else 82)
    if intenso:
        n(bateria, TOM, inicio + BEAT * 1.5, S, velocity=70)


def fill(bateria, inicio):
    for i in range(8):
        n(bateria, SNARE if i % 2 else TOM, inicio + i * S, S, velocity=65 + i * 4)
    n(bateria, CRASH, inicio + BEAT * 2, BEAT, velocity=90)
    n(bateria, KICK, inicio + BEAT * 3, C, velocity=115)


def ostinato(bass, root, inicio, variante=0):
    if variante == 0:
        padrao = [(0, C), (0, C), (7, C), (0, C), (12, C), (7, S), (5, S), (7, C)]
    else:
        padrao = [(0, C), (12, C), (7, C), (12, C), (0, C), (3, C), (5, C), (7, C)]
    t = inicio
    for off, dur in padrao:
        n(bass, root + off, t, dur, velocity=94)
        t += dur


def riff(guitarra, root, inicio, modo="verso"):
    if modo == "verso":
        for i, (off, vel) in enumerate(
            [(0, 78), (0, 64), (7, 74), (0, 64), (0, 82), (7, 68), (3, 76), (0, 70)]
        ):
            n(guitarra, root + 12 + off, inicio + i * C, C * 0.65, velocity=vel)
    else:
        for i in (0, 2, 4, 6):
            adicionar_acorde(
                guitarra,
                [root + 12, root + 19],
                inicio + i * C,
                C * 0.8,
                velocity=88 if i % 4 == 0 else 74,
            )


def lead_frase(lead, inicio, intenso=False):
    if intenso:
        frase = [69, 67, 65, 67, 69, 72, 69, 65]
        vel = 92
    else:
        frase = [65, 67, 69, None, 67, 65, 62, 65]
        vel = 78
    for i, pitch in enumerate(frase):
        if pitch is not None:
            n(lead, pitch, inicio + i * C, C, velocity=vel)


def pulse_chip(chip, chord, inicio):
    ordem = [chord[0], chord[1], chord[2], chord[1]]
    for i in range(8):
        n(chip, ordem[i % 4] + 12, inicio + i * S, S * 0.85, velocity=46 + (i % 2) * 8)


def secao(instruments, inicio, passos, modo, fill_fim=False, crash=False):
    guitarra, bass, pad, lead, chip, choir, bateria = instruments
    t = inicio
    for i, harm in enumerate(passos):
        root = harm["root"]
        chord = harm["chord"]
        if fill_fim and i == len(passos) - 1:
            fill(bateria, t)
        else:
            groove(bateria, t, intenso=(modo == "refrão"))
            if crash and i == 0:
                n(bateria, CRASH, t, BEAT, velocity=95)

        ostinato(bass, root, t, variante=1 if modo == "refrão" else 0)
        adicionar_acorde(pad, chord, t, COMPASSO * 0.98, velocity=40)
        adicionar_acorde(choir, [p + 12 for p in chord], t, COMPASSO * 0.95, velocity=28)
        riff(guitarra, root, t, modo="refrão" if modo == "refrão" else "verso")
        pulse_chip(chip, chord, t)
        if modo != "intro" or i % 2 == 0:
            lead_frase(lead, t, intenso=(modo == "refrão"))
        t += COMPASSO
    return t


def gerar():
    midi = pretty_midi.PrettyMIDI(initial_tempo=BPM)
    guitarra = pretty_midi.Instrument(program=30)  # Distortion
    bass = pretty_midi.Instrument(program=39)      # Synth Bass 2
    pad = pretty_midi.Instrument(program=94)       # Halo Pad
    lead = pretty_midi.Instrument(program=80)      # Square
    chip = pretty_midi.Instrument(program=81)      # Saw
    choir = pretty_midi.Instrument(program=52)     # Choir Aahs
    bateria = pretty_midi.Instrument(program=0, is_drum=True)
    instruments = (guitarra, bass, pad, lead, chip, choir, bateria)

    t = 0.0
    t = secao(instruments, t, PROGRESSAO[:4], modo="intro", crash=True)
    t = secao(instruments, t, PROGRESSAO, modo="verso")
    t = secao(instruments, t, PROGRESSAO, modo="refrão", crash=True)
    t = secao(instruments, t, PROGRESSAO[4:], modo="verso")
    t = secao(instruments, t, PROGRESSAO, modo="refrão", fill_fim=True, crash=True)

    adicionar_acorde(pad, [50, 53, 57], t - S, S, velocity=32)

    midi.instruments.extend([guitarra, bass, pad, lead, chip, choir, bateria])
    exportar_ogg(midi, "dungeon_echoes.ogg")


if __name__ == "__main__":
    gerar()
