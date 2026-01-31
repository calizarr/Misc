# Hardwiring the Philips Fidelio Subwoofer - Complete Guide

## Signal Path Summary

From your schematic analysis:

```
┌─────────────────────────────────────────────────────────────┐
│  DWHP83 Wireless Module (CN204 - 26 pins)                   │
│  ┌──────────────────────────────────────────────────┐       │
│  │  DARR83 Chip                                      │       │
│  │  - Receives wireless audio                        │       │
│  │  - Decodes to I2S digital format                 │       │
│  │  - Controls TAS5538 via I2C master               │       │
│  └────────────┬─────────────────────────────────────┘       │
└───────────────┼──────────────────────────────────────────────┘
                │
                │ I2S Digital Audio Signals:
                │ • MCLK (Master Clock) - 12.288 MHz
                │ • BCK (Bit Clock)
                │ • LRCK (Left/Right Clock)
                │ • TSD0, TSD1, TSD2, TSD3 (Data lines)
                │
                │ I2C Control:
                │ • AMP_SDA, AMP_SCL
                │
┌───────────────▼──────────────────────────────────────────────┐
│  Main Board                                                   │
│  ┌────────────────────────────────────────────────┐          │
│  │  TAS5538 DSP (IC401)                           │          │
│  │  - Receives I2S audio                          │          │
│  │  - Processes (EQ, volume, crossover)           │          │
│  │  - Outputs PWM to amplifier                    │          │
│  └────────────┬───────────────────────────────────┘          │
│               │                                               │
│               │ PWM Signals                                   │
│               │                                               │
│  ┌────────────▼───────────────────────────────────┐          │
│  │  TAS5342 Amplifier (IC501)                     │          │
│  │  - Converts PWM to analog power                │          │
│  │  - 90W output                                  │          │
│  └────────────┬───────────────────────────────────┘          │
└───────────────┼──────────────────────────────────────────────┘
                │
                └─→ Subwoofer Speaker
```

## ⚠️ Critical Discovery

**Pin 26 on CN204 is NOT analog audio!**

Looking at the schematic page 9-2, the signals going to CN204 are:
- **Digital I2S audio** (MCLK, BCK, LRCK, TSD0-3)
- **I2C control** (M-SDA, M-SCL)
- **Power** (+3.3V, +24V, GND)
- **Control signals** (RESET, MUTE, etc.)

**You cannot directly connect analog audio to pin 26** - it's expecting digital I2S!

## Hardwiring Options

### Option 1: Keep DARR83, Bypass Wireless (EASIEST)

**Concept**: Feed I2S digital audio directly to the DARR83's audio input (before wireless decoding)

**Difficulty**: ⭐⭐ Medium
**Pros**: 
- Minimal hardware changes
- DARR83 still controls TAS5538
- Professional digital audio path
**Cons**: 
- Need I2S source (not common RCA/3.5mm)
- DARR83 module stays in place
- Need to understand DARR83 pinout

**Implementation**:
The DARR83 likely has an I2S input that normally receives data from the wireless receiver section. You would need to:

1. Find the I2S input pins on the DARR83 chip itself
2. Inject external I2S audio there
3. Keep the DARR83 powered and configured via I2C

**Problem**: DARR83 datasheet shows it's a receiver chip - it may not have external I2S input pins accessible.

### Option 2: Bypass DARR83, Feed TAS5538 Directly (RECOMMENDED)

**Concept**: Remove wireless module, feed I2S directly to TAS5538

**Difficulty**: ⭐⭐⭐ Medium-Hard
**Pros**:
- Can remove wireless module entirely
- Direct control of audio path
- Standard I2S input
**Cons**:
- Need to configure TAS5538 via I2C
- Need I2S audio source
- Some wiring/modification needed

**Implementation**:

#### Step 1: Identify TAS5538 I2S Input Pins

From schematic (page 9-2), TAS5538 IC401 has:
- **Pin 11**: MCLK (Master Clock Input) - 12.288 MHz
- **Pin 23**: SCLK (Serial Clock / BCK)
- **Pin 22**: LRCLK (Word Select / Frame Sync)
- **Pin 24**: SDIN1 (Serial Data Input 1)
- **Pin 25**: SDIN2 (Serial Data Input 2)
- **Pin 26**: SDIN3 (Serial Data Input 3)
- **Pin 27**: SDIN4 (Serial Data Input 4)

#### Step 2: I2S Source Options

**A. Raspberry Pi as I2S Source**
```
Raspberry Pi GPIO:
  GPIO18 (Pin 12) → BCK
  GPIO19 (Pin 35) → LRCK
  GPIO21 (Pin 40) → SDIN (data)
  
Plus you need MCLK:
  - Generate from PWM (GPIO4)
  - Or use external oscillator (12.288 MHz)
```

**B. DAC with I2S Output**
- PCM5102A module (~$5 on Amazon)
- Takes analog or S/PDIF input
- Outputs I2S
- Has built-in MCLK oscillator

**C. ESP32 I2S Output**
- ESP32 has native I2S output
- Can stream from Bluetooth/WiFi
- Can generate MCLK

#### Step 3: Wiring

```
I2S Source          TAS5538 (IC401)
──────────────────  ────────────────
MCLK (12.288MHz) ─→ Pin 11 (MCLK)
BCK  (Bit Clock) ─→ Pin 23 (SCLK)
LRCK (L/R Clock) ─→ Pin 22 (LRCLK)
DATA (Audio)     ─→ Pin 24 (SDIN1)
GND              ─→ GND
```

**Note**: You must also trace where these signals currently come from (CN204) and either:
- Cut traces and wire directly
- Remove wireless module and solder to pads
- Use test points if available

#### Step 4: Configure TAS5538 via I2C

The TAS5538 needs configuration even with I2S input:
```python
from darr83_control import DARR83

# Since DARR83 is removed, TAS5538 I2C address changes!
# It's no longer behind the DARR83 I2C master
# You'll need to find the TAS5538's direct I2C address

# Typical configuration:
tas.write_register(0x03, 0x00)  # Power up, clear reset
tas.write_register(0x04, 0x05)  # I2S format, 24-bit
tas.write_register(0x07, 0x00)  # Volume: 0dB
tas.write_register(0x06, 0x00)  # Unmute
```

**Critical Issue**: With DARR83 removed, the TAS5538 I2C bus changes!

Looking at schematic:
- Currently: RPi → DARR83 (0x40) → I2C Master → TAS5538 (unknown addr)
- After removal: RPi → ??? → TAS5538

You'll need to check if TAS5538 is directly on the same I2C bus or if it was only accessible through DARR83's master interface.

### Option 3: Replace TAS5538+TAS5342 with Amp Module (NUCLEAR OPTION)

**Concept**: Remove all DSP, use complete amplifier module

**Difficulty**: ⭐⭐⭐⭐⭐ Very Hard
**Pros**:
- Simple analog input (RCA, 3.5mm)
- Self-contained solution
**Cons**:
- Extensive modification
- Expensive
- Loses original DSP quality

**Not recommended unless you want a complete redesign.**

### Option 4: Add Analog-to-I2S Converter (PRACTICAL MIDDLE GROUND)

**Concept**: Keep everything, add converter module before TAS5538

**Difficulty**: ⭐⭐⭐ Medium-Hard
**Pros**:
- Standard analog input (3.5mm, RCA)
- Minimal permanent modification
- Can still use wireless if needed
**Cons**:
- Requires additional module
- More complex wiring

**Implementation**:

Use a PCM1808 or PCM2912 ADC module:

```
Analog Input (RCA/3.5mm)
    ↓
PCM1808 ADC Module ($3-5)
    ↓ I2S Output
    ├→ MCLK (12.288 MHz from onboard oscillator)
    ├→ BCK
    ├→ LRCK  
    └→ DATA
       ↓
TAS5538 (via multiplexer or direct injection)
```

You could add a **multiplexer** to switch between:
- Original wireless (DARR83)
- Hardwired analog input

## 🎯 Recommended Approach

Based on your goals, here's what I recommend:

### Best Option: Raspberry Pi I2S → TAS5538 (Option 2 variant)

**Why**: 
- You already have RPi connected for I2C
- RPi can output I2S natively
- Professional audio quality
- No additional hardware needed
- Can control everything via software

**Steps**:

1. **First, with Pico logic analyzer, capture**:
   - How DARR83 talks to TAS5538
   - What I2C address TAS5538 actually uses
   - Initialization sequence for TAS5538

2. **Physical modification**:
   - Keep CN204 connector in place (or remove cleanly)
   - Identify TAS5538 I2S input pins (IC401)
   - Wire RPi GPIO to these pins
   - Ensure common ground

3. **Software**:
   - Configure RPi I2S output
   - Configure TAS5538 via I2C
   - Stream audio from RPi

## 🔧 Detailed: Raspberry Pi I2S Implementation

### Hardware Connections

```
Raspberry Pi 4B              Main Board
────────────────             ──────────────────────
GPIO2 (SDA)      ────────→  Debug header SDA
GPIO3 (SCL)      ────────→  Debug header SCL
GND              ────────→  GND
                  
GPIO18 (PCM_CLK) ────────→  TAS5538 Pin 23 (SCLK)
GPIO19 (PCM_FS)  ────────→  TAS5538 Pin 22 (LRCLK)
GPIO21 (PCM_DOUT)────────→  TAS5538 Pin 24 (SDIN1)

For MCLK (needed):
GPIO4 (PWM)      ────────→  TAS5538 Pin 11 (MCLK)
```

### MCLK Generation

TAS5538 needs 12.288 MHz master clock. Generate from RPi:

```bash
# Enable PWM on GPIO4
sudo nano /boot/config.txt

# Add:
dtoverlay=pwm,pin=4,func=4

# Reboot
sudo reboot
```

Then in Python:
```python
import RPi.GPIO as GPIO
import time

# Generate 12.288 MHz on GPIO4
GPIO.setmode(GPIO.BCM)
GPIO.setup(4, GPIO.OUT)

# Use hardware PWM
p = GPIO.PWM(4, 12288000)  # 12.288 MHz
p.start(50)  # 50% duty cycle
```

### I2S Audio Output Configuration

```bash
# Edit ALSA config
sudo nano /etc/asound.conf
```

Add:
```
pcm.!default {
    type hw
    card 0
    device 0
}

ctl.!default {
    type hw
    card 0
}
```

Enable I2S in config:
```bash
sudo nano /boot/config.txt
```

Add:
```
dtparam=i2s=on
dtoverlay=hifiberry-dac
```

### TAS5538 I2C Configuration

```python
#!/usr/bin/env python3
"""Configure TAS5538 for I2S input from Raspberry Pi"""

import smbus2
import time

# After removing DARR83, scan for TAS5538 address
bus = smbus2.SMBus(1)

# TAS5538 possible addresses after DARR83 removal
for addr in [0x18, 0x1A, 0x1C, 0x1E, 0x2C, 0x2D, 0x2E, 0x2F]:
    try:
        # Try to read device ID
        val = bus.read_byte_data(addr, 0x01)
        print(f"Found device at 0x{addr:02X}: ID=0x{val:02X}")
    except:
        pass

# Once found, configure (example with 0x2C):
TAS5538_ADDR = 0x2C

def write_reg(reg, val):
    bus.write_byte_data(TAS5538_ADDR, reg, val)

# Configuration sequence
write_reg(0x00, 0x00)  # Clock control
write_reg(0x03, 0x00)  # System control 1: Exit standby
write_reg(0x04, 0x05)  # Serial interface: I2S, 24-bit
write_reg(0x05, 0x00)  # System control 2: Normal operation
write_reg(0x06, 0x00)  # Soft mute: All unmuted
write_reg(0x07, 0x30)  # Master volume: -24dB (safe start)
write_reg(0x08, 0x30)  # CH1 volume
# ... configure other channels

print("TAS5538 configured for I2S input")
```

### Playing Audio

```bash
# Test with speaker-test
speaker-test -t wav -c 2

# Play audio file
aplay test.wav

# Stream from Bluetooth
# (use pulseaudio or pipewire)
```

## 🔍 What the Logic Analyzer Will Tell You

Capture these scenarios with full power:

1. **Power-on sequence** → TAS5538 initialization
2. **Audio playing** → I2S signal characteristics
3. **Volume change** → Which registers change
4. **DARR83 I2C master traffic** → How it talks to TAS5538

This will give you:
- ✅ Exact TAS5538 I2C address
- ✅ Required initialization sequence
- ✅ Register values that work
- ✅ I2S timing requirements

## 🎭 Alternative: Keep it Simple

If all this seems complex, here's the **simplest approach**:

### Option 5: External Bluetooth Receiver + RCA to Subwoofer

1. Get a Bluetooth receiver with subwoofer output (~$20)
2. Connect to the **existing speaker terminals** (CN501)
3. Keep the main board powered but unused

**Pros**: Zero modification, reversible, works immediately
**Cons**: Extra box, not integrated, bypasses all the nice DSP

## 📋 Decision Matrix

| Option | Difficulty | Quality | Cost | Reversible | Uses Existing DSP |
|--------|-----------|---------|------|------------|-------------------|
| 1. Keep DARR83 + I2S | Medium | High | $0-20 | Yes | Yes |
| 2. RPi I2S → TAS5538 | Med-Hard | High | $0 | Partial | Yes |
| 3. Replace amp | Very Hard | Medium | $50+ | No | No |
| 4. Add ADC module | Medium | High | $10 | Yes | Yes |
| 5. External BT RX | Easy | Medium | $20 | Yes | No |

## My Recommendation

**Start with logic analyzer captures**, then:

**If TAS5538 is directly on I2C bus** (not behind DARR83 master):
→ Go with **Option 2** (RPi I2S → TAS5538)
- Best quality
- Free
- Full control

**If TAS5538 is only accessible via DARR83 I2C master**:
→ Go with **Option 4** (Add ADC module)
- Keep DARR83 for I2C control
- Standard analog input
- Minimal complexity

**If you just want it working quickly**:
→ Go with **Option 5** (External receiver)
- Works immediately
- Fully reversible
- No risk

## 🚦 Next Steps

1. ✅ Set up Pico 2 W logic analyzer
2. ✅ Capture power-on with full AC power
3. ✅ Analyze I2C traffic to TAS5538
4. ✅ Determine if TAS5538 is directly accessible
5. ✅ Choose your hardwiring approach based on findings
6. ✅ Test with minimal risk first

Let me know what the logic analyzer shows - that will determine the best path forward!
