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

# Add cowsay and fortune to PATH (Ubuntu installs them in /usr/games/)
ENV PATH="/usr/games:${PATH}"

# Set working directory
WORKDIR /app

# Copy the server script
COPY wisecow.sh /app/wisecow.sh

# Make script executable
RUN chmod +x /app/wisecow.sh

# Expose the port
EXPOSE 4499

# Run the server
CMD ["/app/wisecow.sh"]
