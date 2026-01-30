# Philips Fidelio HTL9100 Subwoofer I2C Control

Complete I2C control interface for the Philips Fidelio wireless subwoofer using Raspberry Pi.

## Hardware Architecture

```
┌─────────────────┐
│  Raspberry Pi   │
│   (I2C Master)  │
└────────┬────────┘
         │ I2C (SDA, SCL, GND, 3.3V)
         │
┌────────▼─────────────────────────┐
│  DWHP83 Wireless Module          │
│  ┌──────────────────────────┐   │
│  │  DARR83 Chip             │   │
│  │  - Slave I2C @ 0x40/0x41 │   │
│  │  - Master I2C controller │   │
│  └──────────┬───────────────┘   │
└─────────────┼───────────────────┘
              │ I2C Master Bus
┌─────────────▼───────────────┐
│  TAS5538 Audio DSP           │
│  (8-Channel PWM Processor)   │
│  I2C Address: TBD            │
└──────────────────────────────┘
```

## Components

### DARR83 (in DWHP83/DWAM83 Module)
- **Manufacturer**: Microchip (formerly SMSC)
- **Function**: Wireless audio receiver with I2C bridge
- **I2C Addresses**: 
  - Primary: 0x40
  - Secondary: 0x41
- **Features**:
  - Slave I2C interface for host control
  - Master I2C interface for controlling downstream devices
  - Wireless audio reception and decoding
  - Link status and signal quality reporting

### TAS5538
- **Manufacturer**: Texas Instruments
- **Function**: 8-Channel Digital Audio PWM Processor
- **Features**:
  - Per-channel volume control
  - Master volume control
  - Soft mute
  - Dynamic range control (DRC)
  - Biquad filters for EQ

## Pin Connections

From your header (CN203 on schematic):

```
Header Pin:  Function:
1            3.3V
2            GND
3            SDA (AMP_SDA / M-SDA)
4            SCL (AMP_SCL / M-SCL)
```

Additional available pins:
- RESET (AMP-RESET)
- DEBUG

## Installation

### 1. Enable I2C on Raspberry Pi

```bash
sudo raspi-config
# Navigate to: Interface Options -> I2C -> Enable

# Verify I2C is enabled
lsmod | grep i2c
```

### 2. Install Required Python Packages

```bash
sudo apt-get update
sudo apt-get install -y python3-smbus i2c-tools
pip3 install smbus2
```

### 3. Verify Connection

```bash
i2cdetect -y 1
```

Expected output:
```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:                         -- -- -- -- -- -- -- --
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
40: 40 41 -- -- -- -- -- -- -- -- -- -- -- -- -- --
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
70: -- -- -- -- -- -- -- --
```

## Usage

### Quick Start

```bash
# Run the interactive control interface
python3 subwoofer_control.py
```

### Python Library Usage

```python
from darr83_control import DARR83
from tas5538_control import TAS5538

# Connect to DARR83
darr = DARR83(address=0x40)

# Get wireless link status
link_status = darr.get_link_status()
print(f"Link connected: {bool(link_status & 0x01)}")

# Get signal quality
quality = darr.get_signal_quality()
print(f"Signal quality: {quality}/255")

# Connect to TAS5538 (through DARR83 I2C master)
tas = TAS5538(darr)

# Control volume
tas.set_master_volume(40)  # -20dB (40 * 0.5dB)

# Mute/unmute
tas.mute(True)   # Mute
tas.mute(False)  # Unmute

# Control individual channels
tas.set_channel_volume(1, 30)  # -15dB on channel 1

# Cleanup
darr.close()
```

## DARR83 Register Map (Typical)

**Note**: Exact register addresses may vary. Use the scan function to map your device.

| Register | Function | Access | Description |
|----------|----------|--------|-------------|
| 0x00 | Device ID | R | Device identification |
| 0x01 | Status | R | General status register |
| 0x02 | Control | R/W | Main control register |
| 0x03 | Link Status | R | Wireless link status |
| 0x04 | Signal Quality | R | Signal strength (0-255) |
| 0x05 | Volume | R/W | Volume control |
| 0x06 | Mute | R/W | Mute control |
| 0x07 | Pairing | R/W | Pairing mode control |
| 0x08 | Error | R | Error status |
| 0x0A-0x0D | I2C Master | R/W | I2C master interface control |

## TAS5538 Register Map

| Register | Function | Access | Default | Description |
|----------|----------|--------|---------|-------------|
| 0x00 | Clock Control | R/W | 0x6C | Clock configuration |
| 0x01 | Device ID | R | 0x00 | Device identification |
| 0x02 | Error Status | R | 0x00 | Error and warning flags |
| 0x03 | System Ctrl 1 | R/W | 0xA0 | System control register 1 |
| 0x04 | Serial Data IF | R/W | 0x05 | Serial data interface config |
| 0x05 | System Ctrl 2 | R/W | 0x00 | System control register 2 |
| 0x06 | Soft Mute | R/W | 0xFF | Soft mute control (bit per channel) |
| 0x07 | Master Volume | R/W | 0x00 | Master volume (0=0dB, 255=-127.5dB) |
| 0x08-0x0F | CH1-8 Volume | R/W | 0x30 | Individual channel volumes |
| 0x10 | HP Volume | R/W | 0x30 | Headphone volume |
| 0x11 | Volume Config | R/W | 0x91 | Volume configuration |

### Volume Calculation

Volume registers use 0.5dB steps:
- 0x00 = 0 dB (maximum)
- 0x01 = -0.5 dB
- 0x02 = -1.0 dB
- ...
- 0xFE = -127.0 dB
- 0xFF = -127.5 dB (mute)

Formula: `dB = (value - 255) * 0.5`

## Troubleshooting

### No I2C Devices Detected

1. Check physical connections (SDA, SCL, GND, 3.3V)
2. Verify subwoofer is powered on
3. Check if pairing button affects I2C (may need to be in certain state)
4. Try adding pull-up resistors (4.7kΩ) if lines are long

### Devices Detected But No Response

1. Try both addresses (0x40 and 0x41)
2. Check if RESET pin needs to be high/low
3. Verify 3.3V power is stable
4. Look for any initialization sequence needed

### Can't Find TAS5538

The TAS5538 may be:
1. Behind the DARR83 I2C master interface (use `i2c_master_read/write`)
2. Using an unexpected address (try all possible addresses)
3. In a powered-down state requiring initialization

### Register Values Don't Change

Some registers may be:
1. Read-only status registers
2. Require specific unlock sequences
3. Only active when audio is playing
4. Protected by hardware configuration

## Advanced Features

### Logic Analyzer Capture

For reverse engineering unknown registers:

```bash
# Use sigrok/PulseView or similar
# Capture I2C traffic during:
# - Power on sequence
# - Volume changes
# - Pairing
# - Audio playback
```

### Custom Register Mapping

```python
# Scan and log all registers
darr = DARR83(address=0x40)
registers = darr.scan_registers(0, 256)

# Test which registers change during operations
initial = {r: v for r, v in registers}
# ... perform action (volume change, pairing, etc.) ...
changed = {r: v for r, v in darr.scan_registers(0, 256)}

# Find differences
for reg in range(256):
    if reg in initial and reg in changed:
        if initial[reg] != changed[reg]:
            print(f"Reg 0x{reg:02X}: 0x{initial[reg]:02X} -> 0x{changed[reg]:02X}")
```

## Safety Notes

⚠️ **Important Safety Considerations**:

1. **Only use 3.3V** - The I2C bus is 3.3V, not 5V
2. **Be careful with register writes** - Unknown registers may control critical functions
3. **Start with read-only operations** - Scan and understand before writing
4. **Have a backup plan** - Be prepared to power cycle if device hangs
5. **Don't write to flash/EEPROM** registers without knowing what they do

## Hardware Modifications

### Alternative Connection Points

If the header is not accessible, you can connect to:
- **RB203** (DEBUG connector) - has SDA, SCL, RESET
- **CN204** (26-pin module connector) - careful with this one
- Test points: TP2, TP5, TP6, TP18, TP19 (see schematic)

### Adding Pull-up Resistors

If needed, add 4.7kΩ resistors:
- One between SDA and 3.3V
- One between SCL and 3.3V

## References

- [DARR83 Datasheet](https://ww1.microchip.com/downloads/en/DeviceDoc/darr83db.pdf)
- [TAS5538 Datasheet](https://www.ti.com/product/TAS5538) - Texas Instruments
- Philips Service Manual (your uploaded PDF)

## Contributing

If you discover register functions or improve the control library:
1. Document your findings
2. Add comments to the code
3. Share with the community

## License

This code is provided as-is for educational and personal use.

## Support

For issues or questions:
- Check register scans against datasheet
- Try different I2C addresses
- Use logic analyzer to verify timing
- Test with minimal code first

## Changelog

### v1.0 - Initial Release
- DARR83 control library
- TAS5538 control through DARR83 I2C master
- Interactive CLI interface
- Register scanning utilities
- Volume and mute control
- Status monitoring
