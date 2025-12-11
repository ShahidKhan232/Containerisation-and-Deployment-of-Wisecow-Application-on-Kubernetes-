# Use Ubuntu as base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SRVPORT=4499

# Install prerequisites
RUN apt-get update && \
    apt-get install -y \
    fortune-mod \
    cowsay \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Add cowsay to PATH
ENV PATH="/usr/games:${PATH}"

# Create app directory
WORKDIR /app

# Copy the wisecow script
COPY wisecow.sh /app/wisecow.sh

# Make script executable and verify it exists
RUN chmod +x /app/wisecow.sh && \
    ls -la /app/wisecow.sh

# Expose port
EXPOSE 4499

# Test the script works (comment out after testing)
# RUN timeout 5s /app/wisecow.sh || echo "Script test completed"

# Run the application
CMD ["./wisecow.sh"]