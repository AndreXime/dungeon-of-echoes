"""Hub: acampamento noturno, loop calmo em Am."""

import pretty_midi

from engine.musica import (
    adicionar_acorde,
    exportar_ogg,
    segundos_por_beat,
    segundos_por_compasso,
)

BPM = 92
BEAT = segundos_por_beat(BPM)
COMPASSO = segundos_por_compasso(BPM)
C = BEAT / 2
S = BEAT / 4

# Am → F → C → Em → Am → Dm → E → Am
PROGRESSAO = [
    {"root": 45, "chord": [57, 60, 64]},
    {"root": 41, "chord": [53, 57, 60]},
    {"root": 48, "chord": [55, 60, 64]},
    {"root": 40, "chord": [52, 55, 59]},
    {"root": 45, "chord": [57, 60, 64]},
    {"root": 38, "chord": [50, 53, 57]},
    {"root": 40, "chord": [52, 56, 59]},
    {"root": 45, "chord": [57, 60, 64]},
]


def n(inst, pitch, inicio, duracao, velocity=80):
    inst.notes.append(
        pretty_midi.Note(
            velocity=velocity,
            pitch=pitch,
            start=inicio,
            end=inicio + duracao * 0.92,
        )
    )


def groove_leve(bateria, inicio):
    for i in range(8):
        n(bateria, 42, inicio + i * C, S, velocity=38 + (i % 2) * 8)
    n(bateria, 36, inicio, C, velocity=78)
    n(bateria, 36, inicio + BEAT * 2, C, velocity=70)
    n(bateria, 38, inicio + BEAT, C, velocity=62)
    n(bateria, 38, inicio + BEAT * 3, C, velocity=58)


def baixo(bass, root, inicio):
    for i, (off, dur) in enumerate(
        [(0, C), (0, C), (7, C), (0, C), (12, C), (7, C), (5, C), (0, C)]
    ):
        n(bass, root + off, inicio + i * C, dur * 0.85, velocity=72)


def arpejo(harp, chord, inicio):
    ordem = [chord[0], chord[1], chord[2], chord[1], chord[0] + 12, chord[2], chord[1], chord[0]]
    for i, pitch in enumerate(ordem):
        n(harp, pitch, inicio + i * C, C * 0.9, velocity=58 + (i % 2) * 6)


def melodia(flute, inicio, grau=0):
    escala = [69, 72, 74, 76, 79, 81, 84]
    frase = [
        escala[(0 + grau) % 7],
        escala[(2 + grau) % 7],
        None,
        escala[(3 + grau) % 7],
        escala[(2 + grau) % 7],
        escala[(1 + grau) % 7],
        None,
        escala[(0 + grau) % 7],
    ]
    for i, pitch in enumerate(frase):
        if pitch is not None:
            n(flute, pitch, inicio + i * C, C * 1.05, velocity=78)


def gerar():
    midi = pretty_midi.PrettyMIDI(initial_tempo=BPM)
    pad = pretty_midi.Instrument(program=89)      # Warm Pad
    harp = pretty_midi.Instrument(program=46)     # Harp
    flute = pretty_midi.Instrument(program=73)    # Flute
    bass = pretty_midi.Instrument(program=32)     # Acoustic Bass
    bateria = pretty_midi.Instrument(program=0, is_drum=True)

    t = 0.0
    for volta in range(2):
        for i, harm in enumerate(PROGRESSAO):
            groove_leve(bateria, t)
            if volta == 0 and i == 0:
                n(bateria, 49, t, BEAT, velocity=70)
            baixo(bass, harm["root"], t)
            adicionar_acorde(pad, harm["chord"], t, COMPASSO * 0.98, velocity=42)
            arpejo(harp, harm["chord"], t)
            if i % 2 == 0:
                melodia(flute, t, grau=i % 3)
            t += COMPASSO

    # Costura do loop: Am curto
    adicionar_acorde(pad, [57, 60, 64], t - S, S, velocity=35)

    midi.instruments.extend([pad, harp, flute, bass, bateria])
    exportar_ogg(midi, "hub_campfire.ogg")


if __name__ == "__main__":
    gerar()
