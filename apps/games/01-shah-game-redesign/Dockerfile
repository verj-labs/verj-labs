# Online game server for Shah Exchange: a headless Godot running godot/server/server_main.tscn.
# Build context is this folder (apps/games/01-shah-game-redesign).
#   docker build -t shah-server .
#   docker run --rm -p 8080:8080 -e PORT=8080 shah-server
# Railway: set the service's Root Directory to this folder; it picks up railway.toml.

FROM debian:bookworm-slim AS godot
ARG GODOT_VERSION=4.7.2
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/godot.zip \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
    && unzip -q /tmp/godot.zip -d /opt \
    && mv "/opt/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot

FROM debian:bookworm-slim
# Shared libraries the Godot binary links against, even when running headless.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libfontconfig1 libx11-6 libxcursor1 \
       libxinerama1 libxrandr2 libxi6 libgl1 libasound2 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=godot /usr/local/bin/godot /usr/local/bin/godot
WORKDIR /app
COPY godot/ /app/godot/
# Import once at build time so the first start does not have to (builds the class cache).
RUN godot --headless --path /app/godot --import || true
ENV PORT=8080
EXPOSE 8080
CMD ["godot", "--headless", "--path", "/app/godot", "res://server/server_main.tscn", "--", "--server"]
