import os
import subprocess

import pretty_midi

_SOUNDFONT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "GeneralUser_GS.sf2",
)


def segundos_por_beat(bpm):
    return 60.0 / bpm


def segundos_por_compasso(bpm, tempos_por_compasso=4):
    return segundos_por_beat(bpm) * tempos_por_compasso


def adicionar_acorde(instrumento, pitches, inicio, duracao, velocity=70):
    for pitch in pitches:
        instrumento.notes.append(
            pretty_midi.Note(
                velocity=velocity,
                pitch=pitch,
                start=inicio,
                end=inicio + duracao,
            )
        )


def exportar_ogg(midi, arquivo_ogg="musica.ogg", soundfont_path=None):
    if soundfont_path is None:
        soundfont_path = _SOUNDFONT

    pasta_saida = "output"
    os.makedirs(pasta_saida, exist_ok=True)

    if not os.path.dirname(arquivo_ogg):
        arquivo_ogg = os.path.join(pasta_saida, arquivo_ogg)

    arquivo_mid = os.path.join(pasta_saida, "temp_output.mid")
    arquivo_wav = os.path.join(pasta_saida, "temp_output.wav")

    midi.write(arquivo_mid)

    # FluidSynth espera o release do soundfont acabar e pode
    # alongar o arquivo com quase silêncio. Corta no fim do MIDI.
    duracao = midi.get_end_time() + 0.8

    subprocess.run(
        [
            "fluidsynth",
            "-ni",
            soundfont_path,
            arquivo_mid,
            "-F",
            arquivo_wav,
            "-r",
            "44100",
        ],
        check=True,
    )

    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i",
            arquivo_wav,
            "-t",
            f"{duracao:.3f}",
            "-c:a",
            "libvorbis",
            "-qscale:a",
            "5",
            arquivo_ogg,
        ],
        check=True,
    )


    for arquivo_temp in [arquivo_mid, arquivo_wav]:
        if os.path.exists(arquivo_temp):
            os.remove(arquivo_temp)

    print(f"Áudio renderizado com sucesso: {arquivo_ogg}")
