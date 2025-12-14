FROM arm64v8/python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy the RaspyRFM project
COPY . /app

# Install Python dependencies from setup.py and additional packages
RUN pip install --no-cache-dir \
    "paho-mqtt>=2.0.0,<3.0.0" \
    influxdb \
    influxdb-client \
    spidev \
    rpi-lgpio

# Install the RaspyRFM package
RUN pip install --no-cache-dir -e .

# Copy entrypoint script
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create config directory for runtime
RUN mkdir -p /config

# Use the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
CMD ["rcpulsegw.py"]
