import os
import subprocess
from pathlib import Path

import numpy as np
from scipy import signal as scipy_signal
from scipy.io import wavfile

SAMPLE_RATE = 44100
PASTA_SAIDA = Path("output/sfx")


def _fase(frequencia, duracao, sample_rate=SAMPLE_RATE):
    if np.isscalar(frequencia):
        t = np.linspace(0, duracao, int(sample_rate * duracao), endpoint=False)
        return 2 * np.pi * frequencia * t
    return 2 * np.pi * np.cumsum(frequencia) / sample_rate


def seno(frequencia, duracao, amplitude=0.5, sample_rate=SAMPLE_RATE):
    return amplitude * np.sin(_fase(frequencia, duracao, sample_rate))


def quadrada(frequencia, duracao, amplitude=0.4, sample_rate=SAMPLE_RATE):
    return amplitude * scipy_signal.square(
        _fase(frequencia, duracao, sample_rate)
    )


def dente_de_serra(frequencia, duracao, amplitude=0.35, sample_rate=SAMPLE_RATE):
    return amplitude * scipy_signal.sawtooth(
        _fase(frequencia, duracao, sample_rate)
    )


def ruido_branco(duracao, amplitude=0.5, sample_rate=SAMPLE_RATE):
    n = int(sample_rate * duracao)
    return amplitude * np.random.default_rng().uniform(-1.0, 1.0, n)


def rampa_frequencia(inicio, fim, duracao, sample_rate=SAMPLE_RATE):
    return np.linspace(inicio, fim, int(sample_rate * duracao), endpoint=False)


def envelope_adsr(
    audio,
    attack=0.01,
    decay=0.05,
    sustain=0.6,
    release=0.1,
    sample_rate=SAMPLE_RATE,
):
    n = len(audio)
    if n == 0:
        return audio

    n_attack = min(int(attack * sample_rate), n)
    n_release = min(int(release * sample_rate), n - n_attack)
    n_decay = min(int(decay * sample_rate), max(n - n_attack - n_release, 0))
    n_sustain = max(n - n_attack - n_decay - n_release, 0)

    env = np.concatenate(
        [
            np.linspace(0.0, 1.0, n_attack, endpoint=False),
            np.linspace(1.0, sustain, n_decay, endpoint=False),
            np.full(n_sustain, sustain),
            np.linspace(sustain, 0.0, n_release, endpoint=False),
        ]
    )

    if len(env) < n:
        env = np.pad(env, (0, n - len(env)))
    elif len(env) > n:
        env = env[:n]

    return audio * env


def misturar(*trilhas, pico=0.9):
    if not trilhas:
        return np.zeros(0)

    tamanho = max(len(t) for t in trilhas)
    mix = np.zeros(tamanho)
    for trilha in trilhas:
        mix[: len(trilha)] += trilha

    atual = np.max(np.abs(mix)) if mix.size else 0.0
    if atual == 0:
        return mix
    return mix * (pico / atual)


def exportar_ogg(audio, arquivo_ogg, sample_rate=SAMPLE_RATE):
    PASTA_SAIDA.mkdir(parents=True, exist_ok=True)

    if not os.path.dirname(arquivo_ogg):
        arquivo_ogg = str(PASTA_SAIDA / arquivo_ogg)
    else:
        Path(arquivo_ogg).parent.mkdir(parents=True, exist_ok=True)

    pcm = np.clip(audio, -1.0, 1.0)
    pcm_i16 = (pcm * 32767.0).astype(np.int16)

    arquivo_wav = str(Path(arquivo_ogg).with_suffix(".tmp.wav"))
    wavfile.write(arquivo_wav, sample_rate, pcm_i16)

    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i",
            arquivo_wav,
            "-c:a",
            "libvorbis",
            "-qscale:a",
            "6",
            arquivo_ogg,
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    if os.path.exists(arquivo_wav):
        os.remove(arquivo_wav)

    print(f"SFX renderizado: {arquivo_ogg}")
    return arquivo_ogg
