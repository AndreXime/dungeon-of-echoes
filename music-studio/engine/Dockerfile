FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    fluidsynth \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1

RUN pip install --no-cache-dir pretty_midi numpy scipy

COPY . /app/engine/

ENTRYPOINT ["python"]
