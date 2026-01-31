# Using Raspberry Pi Pico 2 W as Logic Analyzer for I2C Debugging

## Overview

Using the Pico 2 W with the Logic Analyzer firmware allows you to capture and analyze I2C communication between devices. This is invaluable for reverse engineering the DARR83 protocol.

## Setup

### 1. Flash Logic Analyzer Firmware

```bash
# Clone the Logic Analyzer firmware
git clone https://github.com/gusmanb/logicanalyzer.git
cd logicanalyzer

# Follow the README to flash the Pico 2 W
# Typically involves:
# 1. Hold BOOTSEL button while plugging in Pico
# 2. Copy the UF2 file to the RPI-RP2 drive
```

### 2. Connection Diagram

```
┌─────────────────────────────────────────────┐
│  Philips Subwoofer Main Board               │
│                                              │
│  ┌──────────────┐                           │
│  │ Debug Header │                           │
│  │ CN203/RB203  │                           │
│  └───┬──────────┘                           │
│      │                                       │
│      ├─ 3.3V  ──────────┬─────────────────┐ │
│      ├─ GND   ──────────┼─────────────┐   │ │
│      ├─ SDA   ──┬───────┼─────────┐   │   │ │
│      └─ SCL   ──┼───┬───┼─────┐   │   │   │ │
│                 │   │   │     │   │   │   │ │
└─────────────────┼───┼───┼─────┼───┼───┼───┼─┘
                  │   │   │     │   │   │   │
        ┌─────────▼───▼───▼─────┼───┼───┼───┼────┐
        │  Raspberry Pi 4B       │   │   │   │    │
        │                        │   │   │   │    │
        │  I2C1 Master           │   │   │   │    │
        │  - SDA (GPIO 2)        │   │   │   │    │
        │  - SCL (GPIO 3)        │   │   │   │    │
        └────────────────────────┼───┼───┼───┼────┘
                                 │   │   │   │
        ┌────────────────────────▼───▼───▼───▼────┐
        │  Pico 2 W Logic Analyzer                 │
        │                                           │
        │  GP0  ← SDA (tap)                        │
        │  GP1  ← SCL (tap)                        │
        │  GND  ← Common Ground                    │
        │  VBUS ← 5V (or 3.3V from VSYS)          │
        │                                           │
        └───────────────────────────────────────────┘
```

### 3. Wiring Instructions

**CRITICAL: The Pico should ONLY monitor the bus, not drive it!**

Connect in this order:
1. **GND** - Connect Pico GND to common ground first
2. **SDA Monitor** - Connect Pico GP0 to SDA line (passive tap)
3. **SCL Monitor** - Connect Pico GP1 to SCL line (passive tap)
4. **Power** - Power the Pico via USB or VBUS pin

**Do NOT:**
- Connect Pico I2C pins in master/slave mode
- Use pull-up resistors from Pico (bus already has them)
- Connect Pico directly to 3.3V power line (use USB power)

### 4. Capture Settings

For I2C at standard speed (100 kHz):
- **Sample Rate**: 1-4 MHz (10-40x oversampling)
- **Channels**: 2 (SDA on GP0, SCL on GP1)
- **Trigger**: Rising edge on SCL (optional)
- **Pre-trigger**: 10-25% for context
- **Capture Duration**: 1-5 seconds depending on operation

For I2C at fast mode (400 kHz):
- **Sample Rate**: 4-16 MHz

## Capture Scenarios

### Scenario 1: Power-On Sequence
**Goal**: See initialization commands sent to DARR83

1. Power off the subwoofer
2. Start logic analyzer capture
3. Power on the subwoofer
4. Stop capture after 5 seconds
5. Look for:
   - Initial register writes
   - Clock configuration
   - Mode setup
   - Default values

### Scenario 2: Volume Change
**Goal**: Identify volume control registers

1. Start capture
2. Change volume on the soundbar (if you had it)
   - Alternative: Use your Python script to change volume
3. Stop capture
4. Compare before/after register states

### Scenario 3: Pairing Process
**Goal**: Understand pairing protocol

1. Factory reset the pairing (using pairing_manager.py)
2. Start capture
3. Press physical pairing button (SW7 / TA201 on schematic)
4. Wait for pairing to complete
5. Stop capture
6. Analyze:
   - Pairing command sequence
   - Key exchange (if any)
   - Status polling

### Scenario 4: Wireless Link Status
**Goal**: Find link quality/status registers

1. Start continuous capture
2. Move transmitter closer/farther
3. Observe which registers change
4. Map signal strength indicators

## Analysis Workflow

### Using PulseView (Sigrok)

```bash
# Install PulseView
sudo apt-get install pulseview

# Launch and configure:
# 1. Select Logic Analyzer device
# 2. Set sample rate (4 MHz recommended)
# 3. Enable I2C decoder
# 4. Configure I2C decoder:
#    - SDA = Channel 0 (GP0)
#    - SCL = Channel 1 (GP1)
#    - Address format = 7-bit
```

### Decoding I2C Transactions

Look for patterns like:
```
START | ADDR(0x40) W | ACK | REG(0x07) | ACK | DATA(0x01) | ACK | STOP
                                         ^^^^        ^^^^
                                      Register    Value
```

### Creating a Register Map

1. Export captured data to CSV
2. Parse with Python script (see below)
3. Group by register address
4. Identify register functions by context

## Helper Scripts

### Parse Logic Analyzer CSV Export

```python
#!/usr/bin/env python3
"""Parse I2C captures from logic analyzer"""

import csv
import sys

def parse_i2c_capture(filename):
    """Parse I2C transactions from CSV"""
    transactions = []
    
    with open(filename, 'r') as f:
        reader = csv.DictReader(f)
        current_trans = None
        
        for row in reader:
            if 'address' in row:  # Start of transaction
                if current_trans:
                    transactions.append(current_trans)
                current_trans = {
                    'address': row['address'],
                    'type': row['type'],
                    'data': []
                }
            elif 'data' in row and current_trans:
                current_trans['data'].append(row['data'])
        
        if current_trans:
            transactions.append(current_trans)
    
    return transactions

def analyze_transactions(transactions):
    """Analyze I2C transactions to find patterns"""
    register_writes = {}
    
    for trans in transactions:
        if trans['type'] == 'write' and len(trans['data']) >= 2:
            addr = trans['address']
            reg = trans['data'][0]
            val = trans['data'][1]
            
            key = f"{addr}:{reg}"
            if key not in register_writes:
                register_writes[key] = []
            register_writes[key].append(val)
    
    print("Register Write Summary:")
    print("Addr | Reg  | Values Seen")
    print("-" * 40)
    for key, values in sorted(register_writes.items()):
        addr, reg = key.split(':')
        unique_vals = set(values)
        print(f"{addr} | {reg} | {unique_vals}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 parse_i2c.py <capture.csv>")
        sys.exit(1)
    
    transactions = parse_i2c_capture(sys.argv[1])
    analyze_transactions(transactions)
```

## Common I2C Patterns to Look For

### 1. Burst Writes (Initialization)
```
START | 0x40 W | REG | D0 | D1 | D2 | ... | STOP
```
Long burst = initialization sequence

### 2. Register Polling
```
START | 0x40 W | REG | STOP
START | 0x40 R | DATA | STOP
```
Repeated reads = status register

### 3. Pairing Handshake
```
WRITE 0x40:0x07 = 0x01    // Enter pairing
READ  0x40:0x03           // Check status
READ  0x40:0x03           // Poll...
READ  0x40:0x03           // Poll...
WRITE 0x40:0x10-0x1F      // Write key
WRITE 0x40:0x07 = 0x00    // Exit pairing
```

## Troubleshooting Logic Analyzer

### No Signal Captured
- Check ground connection first
- Verify SDA/SCL are actually on GP0/GP1
- Check sample rate is appropriate
- Ensure I2C bus is active (run your Python script)

### Corrupted Data
- Increase sample rate
- Check for ground loops
- Add 100Ω series resistors to Pico inputs (protection + impedance)
- Use shorter wires

### Missing Transactions
- Increase capture buffer size
- Use triggered capture
- Reduce pre-trigger percentage

## Advanced: Comparing Before/After

```python
#!/usr/bin/env python3
"""Compare two logic analyzer captures to find differences"""

def compare_captures(before_csv, after_csv):
    """Find what changed between two captures"""
    before = parse_i2c_capture(before_csv)
    after = parse_i2c_capture(after_csv)
    
    # Build register maps
    before_regs = extract_register_states(before)
    after_regs = extract_register_states(after)
    
    # Find differences
    print("Changed Registers:")
    for reg, val in after_regs.items():
        if reg in before_regs and before_regs[reg] != val:
            print(f"Reg {reg}: {before_regs[reg]} -> {val}")
```

## Integration with Your Workflow

1. **Initial Discovery**: Use logic analyzer to capture power-on sequence
2. **Validate Python Scripts**: Compare LA captures with your script's commands
3. **Find Hidden Registers**: Look for transactions your scripts don't generate
4. **Reverse Engineer Protocol**: Build complete register map from captures
5. **Update Python Library**: Add discovered registers to your control scripts

## Safety Notes

⚠️ **Important**:
- The Pico should be in MONITOR mode only
- Do NOT enable Pico's I2C peripheral
- Do NOT connect Pico pull-ups to the bus
- Keep capture wires short (<15cm)
- Use proper grounding

## Next Steps After Capture

1. Export to CSV or save Sigrok session
2. Parse with helper scripts
3. Document register functions
4. Update `darr83_control.py` with findings
5. Share discoveries with community

## Useful Resources

- [Logic Analyzer GitHub](https://github.com/gusmanb/logicanalyzer)
- [Sigrok/PulseView Docs](https://sigrok.org/wiki/Main_Page)
- [I2C Protocol Primer](https://www.i2c-bus.org/)
- [DARR83 Datasheet](https://ww1.microchip.com/downloads/en/DeviceDoc/darr83db.pdf)
