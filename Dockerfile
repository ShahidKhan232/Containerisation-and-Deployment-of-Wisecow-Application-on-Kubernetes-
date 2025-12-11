# Use Ubuntu as base image
FROM ubuntu:22.04

# Set the working directory
WORKDIR /app

# Install dependencies - update package manager and install tools
RUN apt-get update && \
    apt-get install -y \
    fortune \
    cowsay \
    netcat-openbsd \
    bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Verify tools are installed by checking their locations
RUN echo "Checking installations..." && \
    ls -la /usr/bin/fortune /usr/games/cowsay /bin/nc || echo "Some tools missing"

# Copy the wisecow application
COPY wisecow.sh .

# Convert line endings from Windows (CRLF) to Unix (LF) and make executable
RUN sed -i 's/\r$//' wisecow.sh && chmod +x wisecow.sh

# Expose the port
EXPOSE 4499

# Run the application
CMD ["./wisecow.sh"]
