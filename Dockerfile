
# Build whisper.cpp
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN cmake -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release -j2

# Download the small English Whisper model at build time.
RUN mkdir -p /app/models \
    && bash ./models/download-ggml-model.sh tiny /app/models

# Runtime image
FROM ubuntu:24.04 AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/build/bin/whisper-server /app/whisper-server
COPY --from=builder /app/models/ggml-tiny.bin /app/models/ggml-tiny.bin

ENV MODEL_PATH=/app/models/ggml-tiny.bin

CMD ["sh", "-c", "exec /app/whisper-server --host 0.0.0.0 --port ${PORT:-10000} --model ${MODEL_PATH} -t 2"]

