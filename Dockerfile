FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies including fortune data files
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    netcat-openbsd \
    fortune-mod \
    fortunes \
    fortunes-min \
    cowsay \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/games:${PATH}"

WORKDIR /app

COPY wisecow.sh /app/wisecow.sh
RUN chmod +x /app/wisecow.sh
EXPOSE 4499

CMD ["/app/wisecow.sh"]
