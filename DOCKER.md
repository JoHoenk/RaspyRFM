# RaspyRFM Docker Container

This directory contains the Docker configuration for running RaspyRFM in a containerized environment on your Raspberry Pi.

## Overview

RaspyRFM is a radio module interface that allows communication with 434 MHz RF devices and other wireless protocols. This Docker container package provides:

- **rcpulsegw.py**: RC Pulse Gateway - primary application for RC protocol support
- **868gw.py**: 868 MHz gateway
- **Other apps**: Additional protocol handlers (Lacrosse, MaxRX, etc.)

## Hardware Requirements

- Raspberry Pi with GPIO and SPI support
- RaspyRFM radio module connected to SPI
- Running on the host machine (cannot run on different architectures)

## Docker Compose Integration

The RaspyRFM service is configured in the main `compose.yaml` with:

- Container name: `raspyrfm`
- Network: Connected to `custom_net` (10.5.0.20)
- SPI device access: `/dev/spidev0.0` and `/dev/spidev0.1`
- Memory access: `/dev/mem` (required for GPIO)
- Dependencies: Mosquitto MQTT broker

## Building the Image

The Docker image is automatically built from the `Dockerfile` when you run:

```bash
docker compose up -d raspyrfm
```

To manually build:

```bash
docker build -t raspyrfm:latest .
```

## Running the Container

### Default (RC Pulse Gateway)

```bash
docker compose up -d raspyrfm
```

This starts the default `rcpulsegw.py` application.

### Running Different Applications

To run a different app, use the compose override or docker command:

```bash
docker compose run --rm raspyrfm 868gw.py
docker compose run --rm raspyrfm scan.py
```

Or with docker run:

```bash
docker run --rm --privileged \
  --device /dev/spidev0.0:/dev/spidev0.0 \
  --device /dev/spidev0.1:/dev/spidev0.1 \
  --device /dev/mem:/dev/mem \
  -v /etc/localtime:/etc/localtime:ro \
  raspyrfm:latest rcpulsegw.py
```

## Configuration

### Development vs Production

The container supports two configurations:

**Production (compose.yaml)**
- Immutable image - no live code mounting
- Uses `cap_add: SYS_RAWIO` instead of full privileged mode
- Secure for long-term deployment
- Restart: unless-stopped

**Development (docker-compose.override.yml)**
- Live code editing via mounted volume
- Optional privileged mode for advanced debugging
- Auto-applied when present in workspace

To enable development mode, the `docker-compose.override.yml` file mounts the apps directory:

```bash
# Automatically uses override file if present
docker compose up -d raspyrfm

# Edit files and restart to see changes
docker compose restart raspyrfm
```

To disable development mode temporarily:

```bash
docker compose up -d raspyrfm --no-override
```

### Capabilities vs Privileged

Production uses `cap_add: SYS_RAWIO` instead of full privileged mode for:
- **SYS_RAWIO**: Allows raw I/O device access (SPI, GPIO via /dev/mem)
- More secure: Only grants required capabilities
- Reduces attack surface compared to `privileged: true`

If you need full privileged mode for debugging, uncomment in `docker-compose.override.yml`.

### MQTT Configuration

The `rcpulsegw.conf` file controls MQTT settings:

```json
{
  "mqtt": {
    "server": "mosquitto",
    "port": 1883,
    "user": "pi",
    "pass": "password"
  },
  "apiport": 1989
}
```

Copy `rcpulsegw.conf.tmpl` to `rcpulsegw.conf` if it doesn't exist.

### Environment Variables

Available in compose.yaml:

- `TZ`: Timezone (default: Europe/Berlin)

## Available Applications

- **rcpulsegw.py**: RC Pulse Gateway (default) - MQTT gateway for RC protocols
- **868gw.py**: 868 MHz gateway
- **scan.py**: Scan and test radio module
- **rcpulse.py**: RC Pulse receiver/sender
- **lacrosse.py**: Lacrosse protocol handler
- **maxrx.py**: MaxRX protocol handler
- **sensors.py**: Sensor interface
- **connair.py**: ConnAir protocol handler
- **ec3000.py**: EC3000 protocol handler

## Logs

View container logs:

```bash
docker compose logs -f raspyrfm
```

## Network Communication

The container communicates via:

- **MQTT**: Connects to `mosquitto` on port 1883
- **API**: Listens on port 1989 (internal, can be exposed if needed)
- **SPI**: Direct hardware access via `/dev/spidev0.x`

## Troubleshooting

### SPI Device Not Found

Ensure the RaspyRFM module is properly connected and SPI is enabled on the Raspberry Pi:

```bash
ls -la /dev/spidev*
```

### MQTT Connection Issues

Verify the container can reach the Mosquitto broker:

```bash
docker compose exec raspyrfm ping mosquitto
```

### Privilege Issues

The container runs with `privileged: true` to access GPIO and memory. This is required for hardware control.

## Development

To modify the RaspyRFM source code:

1. Edit files in the `./RaspyRFM/` directory
2. Changes to apps are reflected immediately (mounted volume)
3. Changes to `setup.py` or system dependencies require image rebuild:

```bash
docker compose build --no-cache raspyrfm
```

## Integration with Home Assistant

Configure Home Assistant MQTT devices to receive RaspyRFM data:

- MQTT broker: `mosquitto` (or your broker hostname)
- Topic prefix: `home/rcpulse/`

Example Home Assistant YAML:

```yaml
mqtt:
  broker: mosquitto
  port: 1883

light:
  - platform: mqtt
    name: "RC Light"
    command_topic: "home/rcpulse/rc_switch/set"
    state_topic: "home/rcpulse/rc_switch"
```

## Security Considerations

- Container runs with `privileged: true` - only use with trusted configurations
- MQTT credentials should be kept in secrets (use `secrets.yaml`)
- Do not expose the API port (1989) to untrusted networks without authentication

## References

- RaspyRFM GitHub: https://github.com/Phunkafizer/RaspyRFM
- Paho MQTT Python: https://github.com/eclipse/paho.mqtt.python
- Raspberry Pi GPIO: https://github.com/gpiozero/gpiozero
