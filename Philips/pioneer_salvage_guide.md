# Pioneer DEH-2400UB Component Salvage Guide
## For Hardwired Subwoofer Project

Based on the service manual analysis, here are the most useful components to salvage:

---

## 🎯 HIGHEST PRIORITY COMPONENTS

### 1. **IC231 - PCM1753DBQ** (Digital-to-Analog Converter)
**Location**: Main board, coordinates (A,144,57)
**Why it's perfect**:
- ✅ **This is a DAC, not an ADC** - converts digital I2S to analog audio
- ✅ 24-bit stereo DAC
- ✅ I2S input interface (BCK, LRCK, DATA)
- ✅ Line-level analog outputs (VOUTL, VOUTR)
- ❌ **Wait - this goes the wrong direction!**

**Correction**: You need an **ADC** (Analog-to-Digital), not DAC. The PCM1753 won't help directly.

---

## ⚠️ THE PROBLEM

Looking through the entire schematic, **the Pioneer DEH-2400UB does not have a dedicated ADC chip!**

Here's why:
- **Aux Input**: Goes through electronic volume IC201 (PML022A) → straight to DAC IC231
- **Tuner**: TDA7706 has built-in ADC → outputs I2S digital to IC231 DAC
- **CD**: Has its own DAC (in IC201 PE5791A)
- **USB**: Digital audio decoded by system microcomputer → I2S to DAC

The head unit only has **digital sources** and **analog playback** (DAC), not the reverse!

---

## 💡 WHAT YOU *CAN* SALVAGE

### Option A: Reverse the Signal Path (Use Components Differently)

#### 1. **IC201 - PML022A (Electronic Volume/Source Selector)**
**Location**: (A,98,112)
**Purpose**: Analog volume control and input switching
**Salvage Value**: ⭐⭐⭐

**What it does**:
- Takes multiple analog inputs (AUX, TUNER, CD)
- Electronic volume control (I2C controllable)
- Outputs line-level analog

**How to use it**:
```
Receiver analog out → PML022A input → (adjust volume via I2C) → Output to...
  → Then you'd still need an ADC to convert to I2S
```

**Verdict**: Useful for volume control, but doesn't solve the ADC problem.

---

#### 2. **IC231 - PCM1753DBQ (DAC)**
**Location**: (A,144,57)
**Purpose**: Digital-to-Analog Converter
**Salvage Value**: ⭐ (Wrong direction)

**What it does**:
- Converts I2S digital → analog audio
- The **opposite** of what you need

**Could you reverse it?**: No, DACs can't work as ADCs

---

### Option B: Salvage Supporting Components

#### 3. **Power Supply Components**
**Salvage Value**: ⭐⭐⭐⭐⭐

**IC501 - BD9008F** (A,20,113) - Step-down DC-DC converter
- Converts +12V battery → lower voltages
- Could power your PCM1808 ADC module

**IC510 - BD2232G-G** (A,107,30) - USB 5V regulator
- Generates clean 5V from 12V
- Perfect for powering modules

**IC912 - BA49182-V12** (A,145,28) - Voltage regulator
- Generates stable 12V rail
- Good for TAS5538 if needed

**IC651 - S-80827CNMC-B8M** (A,98,53) - Reset IC
- Provides stable power-on reset
- Useful for any digital circuits

**Recommended**: Salvage the entire power supply section!

---

#### 4. **Connectors and Cables**
**Salvage Value**: ⭐⭐⭐⭐

**JA251** - RCA jacks (pre-output)
- Clean RCA connectors
- Wire harness included

**JA901** - Power connector (CKM1586)
- 18-pin power input
- Heavy-duty wiring

**CN801** - Internal connector (CKS6288)
- 20-pin internal connection
- Can reuse for custom wiring

---

#### 5. **Passive Components**
**Salvage Value**: ⭐⭐⭐⭐

**Resistors** (for voltage divider):
- R255, R256, R257, R258: 22kΩ (1/16W chip)
- R251-R254: 820Ω (1/16W chip)
- Hundreds of other values available

**Capacitors**:
- C309: 3300µF/16V (filter cap)
- C922: 1000µF/16V (bulk storage)
- Many 0.1µF ceramic caps for decoupling
- C901: 3300µF/16V (main power filter)

**Inductors/Coils**:
- L501 (CTH1475): Power supply inductor
- L901 (CTH1432): 600µH choke coil
- Various RF coils (if you need them)

---

#### 6. **Op-Amps and Audio Components**
**Salvage Value**: ⭐⭐⭐

**IC301 - PAL007E** (A,78,141)
- Audio power amplifier (for speakers)
- Could repurpose for audio buffer/driver

**IC961 - NJM4558MD** (if present)
- Dual op-amp
- Useful for voltage divider buffer circuits

---

## 🛠️ PRACTICAL SALVAGE STRATEGY

### What to Desolder First:

1. **Power Supply Section** (Area 501-510)
   - IC501 (DC-DC converter)
   - IC510 (USB 5V regulator)
   - L501 (power inductor)
   - C503, C509 (filter caps)
   - D501, D502, D503 (protection diodes)

2. **Connectors**
   - JA251 (RCA jacks with wiring)
   - JA901 (power connector)
   - Any other useful connectors

3. **Large Capacitors**
   - C309 (3300µF/16V) - main filter
   - C922 (1000µF/16V)
   - C924, C925, C929 (220µF/6.3V)

4. **Useful Resistors** (if you need specific values)
   - De-solder entire sections to get assortments

### What to Skip:

- ❌ IC231 (PCM1753) - DAC, not ADC (wrong direction)
- ❌ IC601 (R5S7266ZD144FP) - System microcomputer (too complex, likely won't boot without full system)
- ❌ IC401 (TDA7706) - FM/AM tuner chip (has ADC but integrated for RF, not audio)
- ❌ CD mechanism components (mechanical, not useful)

---

## 💰 ACTUAL VALUE ASSESSMENT

### Components Worth Salvaging: ⭐⭐⭐

**Realistically**:
- Power supply ICs and circuit: **Useful** (avoid buying regulators)
- Connectors and wire harnesses: **Very useful**
- Passive components: **Moderately useful** (but cheap to buy new)
- Volume control IC: **Maybe useful** for future projects

**The Missing Piece**:
- You still need to **buy a PCM1808 ADC module** (~$3-5)
- The Pioneer doesn't have what you need for analog→I2S conversion

---

## 🎯 REVISED RECOMMENDATION

### Best Approach:

1. **Buy new**: PCM1808 ADC module (~$5)
   - It's cheap and does exactly what you need
   - Pre-built module with all support components

2. **Salvage from Pioneer**:
   - Power supply section (IC501, IC510, regulators)
   - RCA connectors (JA251)
   - Power connectors (JA901)
   - Large filter capacitors
   - Wire harnesses

3. **System Architecture**:
```
Receiver (RCA outputs)
    ↓
Voltage Divider (if speaker-level) [use salvaged resistors]
    ↓
PCM1808 ADC [bought new, ~$5]
    ↓ I2S (MCLK, BCK, LRCK, DATA)
Subwoofer Main Board - TAS5538
    ↓
TAS5342 Amplifier
    ↓
Speaker
```

### Why This Makes Sense:

- **PCM1808 module**: $5 and works perfectly
- **Pioneer salvage**: Free power supply components worth ~$10-15
- **Total savings**: Modest, but you get proven working parts
- **Time savings**: Don't waste hours desoldering useless ICs

---

## 📋 SPECIFIC PARTS TO SALVAGE

### Power Supply Section

| Component | Part Number | Location | Purpose |
|-----------|-------------|----------|---------|
| IC501 | BD9008F | (A,20,113) | DC-DC converter (input→output) |
| IC510 | BD2232G-G | (A,107,30) | USB 5V regulator |
| IC912 | BA49182-V12 | (A,145,28) | Voltage regulator |
| L501 | CTH1475 | (A,34,109) | Power inductor |
| D501 | RB160L-40 | (A,29,109) | Schottky diode |
| D502, D503 | CRG03 | Power section | Switching diodes |
| C503 | 220µF/6.3V | (A,32,119) | Filter cap |
| C509 | 1µF/16V | (A,24,109) | Filter cap |

### Connectors

| Component | Part Number | Location | Type |
|-----------|-------------|----------|------|
| JA251 | CKB1056/1099 | (A,19,137) | RCA jacks (2-channel) |
| JA901 | CKM1586 | (A,113,140) | 18-pin power connector |
| CN801 | CKS6288 | (A,109,3) | 20-pin internal |

### Bulk Storage

| Component | Value | Location | Purpose |
|-----------|-------|----------|---------|
| C309 | 3300µF/16V | (A,135,134) | Main filter |
| C901 | 3300µF/16V | (A,133,124) | Main filter |
| C922 | 1000µF/16V | (A,157,54) | Bulk storage |
| C924 | 220µF/6.3V | Power rail | Local filtering |
| C925 | 220µF/6.3V | Power rail | Local filtering |

### Voltage Divider Resistors (If Needed)

For speaker-level to line-level conversion:

| Resistors | Value | Quantity Available |
|-----------|-------|-------------------|
| R255-R258 | 22kΩ | 4 (use for R1 in divider) |
| R251-R254 | 820Ω | 4 (use for R2 in divider) |
| R303 | 10kΩ | Multiple available |
| R331-R334 | 470Ω | 4 available |

**Example Voltage Divider**:
```
Speaker Out (+) ─[22kΩ]─┬──[10µF]→ ADC Input
                        │
                    [820Ω]
                        │
Speaker Out (-)─────────┴────────→ ADC GND

Attenuation: 820/(22000+820) ≈ 1/27.8 ≈ -28.9dB
Perfect for typical 20-30W speaker output → 2Vrms line level
```

---

## ⚙️ SALVAGE PROCEDURE

### Tools Needed:
- Soldering iron (temperature controlled, 300-350°C)
- Solder wick or desoldering pump
- Flux pen
- Tweezers (for SMD components)
- Hot air station (optional, makes SMD easier)
- Isopropyl alcohol (for cleaning)

### Order of Operations:

1. **Take clear photos** of both sides before starting
2. **Mark polarity** on electrolytic capacitors before removal
3. **Start with large through-hole parts** (connectors, large caps)
4. **Move to SMD ICs** (hot air at 350°C, or careful iron work)
5. **Save chip resistors/caps only if you need specific values**
6. **Clean all pads** with solder wick and flux
7. **Test components** before using:
   - ICs: Visual inspection for damage
   - Caps: Measure with LCR meter if possible
   - Resistors: Measure with multimeter

### Safety:
- ⚠️ **Discharge large capacitors** before working (short with 1kΩ resistor)
- ⚠️ **Check for battery backup** (button cell) - remove first
- ⚠️ **Wear safety glasses** when desoldering (flux can spit)

---

## 🎬 CONCLUSION

### What the Pioneer Provides:
✅ **Power supply components** (regulators, inductors, diodes)  
✅ **Connectors and wiring** (RCA jacks, power connectors)  
✅ **Passive components** (caps, resistors) for voltage divider  
✅ **Experience** in desoldering and component identification  

### What It Doesn't Provide:
❌ **No ADC chip** suitable for audio conversion  
❌ **No I2S encoder** for analog-to-digital  

### Final Recommendation:
**Salvage**: Power supply section + connectors + passives  
**Buy new**: PCM1808 ADC module (~$5)  
**Total cost**: ~$5 + your salvage time  
**Total value**: ~$20 in components  

This is a great learning project and you'll get useful parts, but don't expect the Pioneer to provide the complete ADC solution you need!

---

## 📸 COMPONENT IDENTIFICATION PHOTOS GUIDE

When you open the Pioneer:

**Look for these on the PCB**:

1. **IC501** - 8-pin IC near power input, should have "BD9008" marking
2. **IC231** - Larger IC (16-pin) - this is the DAC (you can salvage for future projects)
3. **JA251** - The RCA jacks on the back panel
4. **C309/C901** - Large cylindrical capacitors (biggest ones on board)
5. **Power section** - Usually in top-left area near AC/DC input

**Quick test**: Measure continuity between power input and see which ICs are in that path - those are your power supply components!

Good luck salvaging! 🔧
