# PCM1808 ADC Integration for Hardwired Subwoofer

## Overview

Convert analog audio from your receiver → I2S digital → TAS5538 DSP → Amplifier → Subwoofer

```
Receiver (RCA/Speaker outputs)
    ↓ Analog audio (line level or speaker level)
Level Converter (if needed)
    ↓ Line level (~2Vrms)
PCM1808 ADC Module
    ↓ I2S Digital Audio
    ├─ LRCK (44.1/48 kHz)
    ├─ BCK (Bit clock)
    ├─ DATA (Serial audio)
    └─ MCLK (System clock)
       ↓
TAS5538 DSP (IC401)
    ↓ PWM
TAS5342 Amplifier (IC501)
    ↓ 90W Analog Power
Subwoofer Speaker
```

## PCM1808 Module Specifications

**Typical PCM1808 breakout board** (~$3-5 on Amazon/eBay):
- **Input**: Stereo line level (0.5-2.0 Vrms)
- **Output**: I2S digital audio
- **Sample Rates**: 8-96 kHz (auto-detected or pin-selectable)
- **Bit Depth**: 24-bit
- **Built-in**: 
  - Master clock oscillator (can be disabled)
  - Anti-aliasing filters
  - Optional gain control

**Pinout** (typical module):
```
PCM1808 Module Pins:
┌─────────────────────┐
│ VIN   (3.3-5V)      │  Power input
│ GND   (Ground)      │  Ground
│ LRCK  (WS)          │  Word Select / Frame Sync → TAS5538 Pin 22
│ BCK   (SCK)         │  Bit Clock → TAS5538 Pin 23
│ DATA  (DOUT)        │  Serial Data → TAS5538 Pin 24
│ MCLK  (Optional)    │  Master Clock → TAS5538 Pin 11
│ L_IN  (Left)        │  Left audio input
│ R_IN  (Right)       │  Right audio input
│ FMT   (Format)      │  I2S format select (tie to GND)
│ MD0/1 (Mode)        │  Sample rate select
└─────────────────────┘
```

## Audio Input Options

### Option 1: Line Level from Receiver (EASIEST)

Most receivers have "Subwoofer Out" or "Pre-Out" RCA connections.

**Signal Level**: ~2Vrms (line level)
**Connection**: Direct to PCM1808

```
Receiver RCA Subwoofer Out
    ↓
[Optional: Combine L+R if stereo]
    ↓
PCM1808 L_IN and R_IN
```

**Wiring**:
```
Receiver Sub Out (RCA) ──[+]──→ PCM1808 L_IN
                        └[GND]→ PCM1808 GND

If stereo pre-outs:
Left RCA   ──[+]──→ PCM1808 L_IN
Right RCA  ──[+]──→ PCM1808 R_IN
Common GND ───────→ PCM1808 GND
```

### Option 2: Speaker Level from Receiver (REQUIRES ATTENUATION)

If your receiver only has speaker outputs (most common):

**Signal Level**: ~10-50Vrms (speaker level) - **TOO HIGH!**
**Solution**: Voltage divider to reduce to line level

```
Receiver Speaker Out
    ↓
Voltage Divider (10:1 or 20:1)
    ↓ ~2Vrms (line level)
PCM1808 Input
```

**Simple Voltage Divider Circuit**:
```
Speaker Out (+) ──[R1: 10kΩ]──┬──→ PCM1808 L_IN
                              │
                          [R2: 1kΩ]
                              │
Speaker Out (-) ──────────────┴──→ PCM1808 GND

Attenuation = R2/(R1+R2) = 1k/(10k+1k) = 1/11 ≈ -20.8dB
```

**Better: Use Resistor Network + Capacitor**:
```
                    100kΩ
Speaker (+) ───[====]────┬────[10µF]──→ PCM1808 L_IN
                         │
                    10kΩ │
                     [====]
                         │
Speaker (-) ─────────────┴───────────→ PCM1808 GND

This gives: 
- 11:1 attenuation
- DC blocking (capacitor)
- High input impedance (doesn't load amplifier)
```

### Option 3: Sum Stereo to Mono for Subwoofer

If you have stereo pre-outs but want mono subwoofer:

```
Left RCA ──[10kΩ]──┐
                   ├──→ PCM1808 L_IN (and R_IN jumpered)
Right RCA ─[10kΩ]──┘
```

## PCM1808 to TAS5538 Wiring

### Full Connection Diagram

```
PCM1808 Module              Main Board TAS5538 (IC401)
──────────────────          ───────────────────────────
VIN (3.3V)   ────────────→  BK3.3V (from main board)
GND          ────────────→  GND (common ground)

LRCK (WS)    ────────────→  Pin 22 (LRCLK)
BCK  (SCK)   ────────────→  Pin 23 (SCLK)
DATA (DOUT)  ────────────→  Pin 24 (SDIN1)
MCLK (out)   ────────────→  Pin 11 (MCLK)

FMT          ────────────→  GND (I2S mode)
MD0          ────────────→  GND (48kHz)
MD1          ────────────→  GND (48kHz)

L_IN ←─ [From receiver/voltage divider]
R_IN ←─ [From receiver/voltage divider]
```

### Physical Installation

**Where to connect on main board:**

Looking at schematic page 9-2, the signals from CN204 (wireless module) go to:
- **MCLK** → Currently from wireless module pin (needs to be cut/lifted)
- **BCK** → Currently from wireless module
- **LRCK** → Currently from wireless module  
- **TSD0-3** → Data lines (only need TSD0/SDIN1)

**Access Points:**

1. **At IC401 (TAS5538) directly** - Solder to IC pins (advanced)
2. **At test points** - TP2 (MCLK), TP5 (BCK), TP6 (LRCK), TP18 (TSD0)
3. **At CN204 connector** - Remove wireless module, use connector pins

**Recommended**: Use test points with thin wire-wrap wire (30AWG)

### Switching Between Wireless and Wired

If you want to keep wireless functionality:

**Use an analog switch IC** (74HC4053 or similar):

```
                    ┌─────────────┐
Wireless Module ────┤             │
   (MCLK/BCK/LRCK)  │  74HC4053   │──→ TAS5538
                    │  Multiplexer│
PCM1808 Module ─────┤             │
   (MCLK/BCK/LRCK)  └──────┬──────┘
                           │
                    GPIO/Switch (select)
```

Or **mechanical switch** (simpler):
```
                    ┌──[Switch]──┐
Wireless ───────────┤            ├──→ TAS5538 MCLK
PCM1808 ────────────┘            │
                                 └──→ TAS5538 BCK, etc.
```

## Configuration

### PCM1808 Sample Rate Selection

**Mode Pins** (MD0, MD1):
| MD1 | MD0 | Sample Rate |
|-----|-----|-------------|
| 0   | 0   | 48 kHz      |
| 0   | 1   | 32 kHz      |
| 1   | 0   | 96 kHz      |
| 1   | 1   | 44.1 kHz    |

**Recommendation**: Use 48 kHz (both pins to GND) - matches most modern audio

### TAS5538 I2C Configuration

After wiring PCM1808, configure TAS5538 via I2C:

```python
#!/usr/bin/env python3
"""Configure TAS5538 for PCM1808 input"""

import smbus2
import time

# Connect via I2C
# Note: Address may change after removing DARR83
# Use logic analyzer to find actual address
bus = smbus2.SMBus(1)

# Scan for TAS5538
print("Scanning for TAS5538...")
for addr in [0x18, 0x1A, 0x1C, 0x1E, 0x2C, 0x2D, 0x2E, 0x2F]:
    try:
        val = bus.read_byte_data(addr, 0x01)
        print(f"Found at 0x{addr:02X}")
        TAS5538_ADDR = addr
        break
    except:
        pass

def write_reg(reg, val):
    """Write TAS5538 register"""
    bus.write_byte_data(TAS5538_ADDR, reg, val)
    time.sleep(0.01)

# Configuration for PCM1808 @ 48kHz, 24-bit I2S
print("Configuring TAS5538...")

write_reg(0x00, 0x00)  # Clock control: Use MCLK input
write_reg(0x03, 0x00)  # System control 1: Exit reset
write_reg(0x04, 0x05)  # Serial data interface: I2S, 24-bit
write_reg(0x05, 0x00)  # System control 2: Normal operation
write_reg(0x06, 0x00)  # Soft mute: All channels unmuted
write_reg(0x07, 0x30)  # Master volume: -24dB (safe start)

# Set all channel volumes
for ch in range(8):
    write_reg(0x08 + ch, 0x30)  # Each channel: -24dB

print("TAS5538 configured!")
print("Gradually increase volume from receiver to test")
```

## Salvaging Components from Head Units

### Pioneer DEH-2400UB

**Potentially useful components:**

1. **Power Supply Section**
   - Switching regulators (for 3.3V, 5V)
   - Filter capacitors
   - Inductors

2. **Audio Processing**
   - May have a dedicated ADC chip (look for 8-pin or 16-pin ICs)
   - DAC chips (can sometimes work in reverse)
   - Audio op-amps (for voltage divider circuit)

3. **Connectors**
   - RCA jacks
   - Speaker terminals
   - Wire harnesses

**How to identify ADC/DAC**:
- Look for ICs near audio connectors
- Common chips: PCM1808, PCM1802, AK4556, CS4271
- Check IC markings, search datasheets

**Schematic lookup**: Search "Pioneer DEH-2400UB service manual" - you may find component identification

### Toyota Scion Radio (PT546-00080)

**Less likely to have useful ADCs** (OEM radios often use integrated SoCs), but check for:
- Standalone audio codec ICs
- Power supply components
- Connectors and wire harnesses

### Salvaging Process

1. **Power off**, discharge capacitors (short with 1kΩ resistor)
2. **Take clear photos** before desoldering
3. **Desolder carefully** with solder wick or hot air
4. **Test components** before using:
   ```
   - Visual inspection (no cracks, burns)
   - Continuity test (IC pins)
   - Power-up test (if possible)
   ```

**Alternative**: Use the whole head unit!
- If DEH-2400UB powers on, use its line output → voltage divider → PCM1808
- Or use auxiliary input features

## Bill of Materials

### If Buying New

| Item | Quantity | Approx Cost | Source |
|------|----------|-------------|--------|
| PCM1808 Module | 1 | $3-5 | Amazon, eBay |
| 10kΩ Resistors (1/4W) | 4 | $0.50 | Any electronics store |
| 100kΩ Resistors | 2 | $0.50 | Any electronics store |
| 10µF Capacitors (25V) | 2 | $1 | Any electronics store |
| RCA jacks/connectors | 2 | $2 | Amazon |
| Wire (22-24 AWG) | - | $3 | Any electronics store |
| Breadboard (optional) | 1 | $3 | For testing |
| **Total** | - | **~$13-20** | |

### If Salvaging

| Item | Source |
|------|--------|
| ADC chip | Head unit audio section |
| Resistors | Head unit power/audio sections |
| Capacitors | Head unit (check voltage rating!) |
| Op-amps | Head unit audio section |
| Connectors | Head unit rear panel |
| Wire | Head unit wire harness |

## Testing Procedure

### Step 1: Bench Test PCM1808

```
1. Power PCM1808 with 3.3V from RPi or bench supply
2. Connect audio input (smartphone headphone out → voltage divider)
3. Monitor I2S outputs with oscilloscope or logic analyzer
4. Verify:
   - LRCK toggles at ~48 kHz
   - BCK runs at 64x LRCK (3.072 MHz)
   - DATA shows activity when audio plays
```

### Step 2: Connect to TAS5538 (Without Wireless Module)

```
1. Remove wireless module (or disconnect its I2S outputs)
2. Wire PCM1808 to TAS5538 via test points
3. Configure TAS5538 via I2C (use script above)
4. Connect speaker
5. Play audio through receiver
6. Start at LOW volume, gradually increase
```

### Step 3: Verify Audio Path

```
1. Play test tones (20Hz, 40Hz, 60Hz, 80Hz)
2. Check subwoofer response
3. Adjust TAS5538 volume via I2C
4. Test frequency response
5. Check for distortion
```

## Voltage Divider Calculator

For speaker level input, calculate required attenuation:

```python
def calculate_divider(v_in_max, v_out_target=2.0):
    """
    Calculate resistor values for voltage divider
    v_in_max: Maximum input voltage (Vrms)
    v_out_target: Target output voltage (Vrms)
    """
    attenuation = v_out_target / v_in_max
    
    # Use standard resistor values
    r2 = 1000  # 1kΩ (fixed)
    r1 = r2 * (1/attenuation - 1)
    
    print(f"Input: {v_in_max}Vrms")
    print(f"Output: {v_out_target}Vrms")
    print(f"Attenuation: {attenuation:.4f} ({20*log10(attenuation):.1f}dB)")
    print(f"R1 (series): {r1:.0f}Ω → Use {closest_standard(r1)}Ω")
    print(f"R2 (to GND): {r2}Ω")
    
    return r1, r2

# Example: 20W into 8Ω = √(20*8) = 12.6Vrms
r1, r2 = calculate_divider(12.6, 2.0)
```

**Common scenarios**:
| Receiver Output | R1 | R2 | Attenuation |
|-----------------|----|----|-------------|
| 10Vrms (12W@8Ω) | 3.9kΩ | 1kΩ | -13.8dB |
| 15Vrms (28W@8Ω) | 6.8kΩ | 1kΩ | -17.5dB |
| 20Vrms (50W@8Ω) | 10kΩ | 1kΩ | -20dB |

## Troubleshooting

### No Sound

1. **Check power**: PCM1808 powered? (LED if present)
2. **Check I2C**: Is TAS5538 configured? Run status script
3. **Check connections**: Verify with continuity tester
4. **Check input**: Connect headphones to ADC input, hear audio?
5. **Check volume**: TAS5538 and receiver both up?

### Distortion

1. **Input level too high**: Reduce with voltage divider
2. **Clipping at ADC**: Lower receiver volume
3. **TAS5538 volume too high**: Reduce via I2C
4. **Poor grounding**: Check ground connections

### Noise/Hum

1. **Ground loop**: Use single ground point
2. **Poor shielding**: Use shielded cable for audio
3. **EMI**: Add ferrite beads to I2S lines
4. **Power supply noise**: Add decoupling capacitors

### One Channel Only

1. **Check stereo summing**: If using, verify resistor network
2. **Check PCM1808 mode**: Ensure both L and R inputs connected
3. **Check TAS5538 config**: May be in mono mode

## Advanced: Digital Volume Control

Instead of analog volume at receiver, control digitally:

```python
def set_volume_db(db):
    """
    Set TAS5538 volume in dB
    Range: 0dB to -127.5dB (mute)
    """
    # TAS5538 uses 0.5dB steps
    # 0x00 = 0dB, 0xFF = -127.5dB
    
    if db > 0:
        db = 0
    if db < -127.5:
        db = -127.5
    
    reg_val = int(abs(db) * 2)  # Convert to 0.5dB steps
    
    # Write to master volume
    bus.write_byte_data(TAS5538_ADDR, 0x07, reg_val)
    print(f"Volume set to {db}dB (reg value: 0x{reg_val:02X})")

# Usage:
set_volume_db(-20)  # -20dB
set_volume_db(-10)  # -10dB
set_volume_db(0)    # Max (0dB)
```

Could even make a web interface or Bluetooth remote control!

## Next Steps

1. ✅ **Set up Pico 2W logic analyzer** (do this first!)
2. ✅ **Capture I2C traffic** to see how DARR83 talks to TAS5538
3. ✅ **Order PCM1808 module** (or salvage from head unit)
4. ✅ **Build voltage divider** for speaker-level input
5. ✅ **Bench test** PCM1808 separately
6. ✅ **Wire to TAS5538** and test
7. ✅ **Enjoy hardwired subwoofer!** 🎵

The logic analyzer will be critical for steps 2-6, so get that working first!
