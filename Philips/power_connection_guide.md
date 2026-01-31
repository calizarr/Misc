# Safe Power Connection Guide for Philips Fidelio Subwoofer

## Power Requirements

From the schematic analysis:

### Main Board Power Rails
- **+24V** (29V from power board) - Main power for amplifier
- **+12V** - Secondary rail
- **BK3.3V** (+3.3V) - Digital logic (currently from RPi)
- **GND** - Common ground

### Power Board Outputs (from Section 10-2)
Looking at the power board circuit diagram:
- **Primary AC Input**: 100-240V AC (universal)
- **Secondary DC Outputs**:
  - **29V** (labeled as +29V on PCB) - Main amplifier power
  - **BK3V3** - 3.3V digital logic
  - **GND** - Common ground

## Connection Options

### Option 1: Full Power with AC (RECOMMENDED for full testing)

**What You Get:**
- ✅ Full wireless receiver functionality
- ✅ TAS5538 audio DSP operational
- ✅ Amplifier power stage active
- ✅ All features testable
- ⚠️ **WARNING**: Power amplifier will be live!

**Safety Considerations:**
1. **DO NOT connect speaker** during I2C testing
2. **Keep volume at minimum** when testing
3. **The TAS5342 amplifier can output 90W** - enough to damage equipment
4. **Have a way to quickly disconnect power** (power strip with switch)

**Connections:**
```
Power Board (J-series connectors):
  J916 (29V)  ────→  CN501 or power input on main board
  J917 (GND)  ────→  GND on main board
  J918 (BK3V3)────→  BK3.3V on main board (or leave to RPi)
  
AC Input:
  CN901 (L, N, GND) ──→ AC mains with fuse (T4AH 250V)
```

**Testing Procedure:**
1. Connect all cables EXCEPT AC power
2. Verify all connections with multimeter (continuity)
3. Double-check polarity
4. Disconnect or disable amplifier outputs (see below)
5. Connect RPi I2C last
6. Plug in AC power
7. Measure voltages immediately:
   - +29V rail should be ~29V DC
   - BK3.3V should be ~3.3V DC

### Option 2: Bench Power Supply (SAFER for initial testing)

**What You Get:**
- ✅ Wireless receiver should work
- ✅ TAS5538 should respond
- ✅ Safer - adjustable current limit
- ⚠️ Amplifier may not fully operate

**Required:**
- Bench power supply with:
  - 24-29V @ 2A (minimum)
  - 3.3V @ 500mA (if not using RPi)
  - Current limiting capability

**Connections:**
```
Bench PSU Channel 1 (24-29V):
  (+) ────→  +24V input on main board
  (-) ────→  GND
  
Bench PSU Channel 2 (3.3V):
  (+) ────→  BK3.3V
  (-) ────→  GND
  
OR keep RPi providing 3.3V only
```

**Safety Settings:**
- **Current limit on 24V**: Start at 500mA, increase if needed
- **Current limit on 3.3V**: 200mA max
- **Monitor current draw**: Should be <200mA idle

### Option 3: Hybrid - AC Power + RPi I2C (BEST COMPROMISE)

Use the actual power board for power, but keep RPi for I2C control:

```
Power Board ──[29V]──→ Main Board +24V
Power Board ──[GND]──→ Main Board GND
Power Board ──[3.3V]─→ Main Board BK3.3V
                  │
                  └──→ RPi 3.3V (optional, for comparison)

RPi ──[SDA]──→ Main Board SDA
RPi ──[SCL]──→ Main Board SCL
RPi ──[GND]──→ Main Board GND (common ground!)
```

**Common Ground is CRITICAL!**

## Disabling the Amplifier (for safer testing)

If you want to test I2C without risk of speaker damage:

### Method 1: Disconnect Power to TAS5342
Looking at schematic section 9-2:
- The TAS5342 (IC501) is powered from +24V1
- **Disconnect**: Remove inductor L501 or L502
- This keeps digital I2C alive but disables power stage

### Method 2: Keep TAS5342 in Shutdown
- The TAS5342 has SD (shutdown) pin (pin 5)
- Pull this LOW to keep amplifier disabled
- Add a jumper wire from SD (pin 5) to GND

### Method 3: Don't Connect Outputs
- Simply leave CN501 (speaker connector) disconnected
- No load = no damage
- Amplifier may still run but outputs nothing

## Power-On Sequence Testing

### Before First Power-On

**Checklist:**
- [ ] All connections verified with multimeter (continuity mode)
- [ ] No short circuits (resistance >1kΩ between power rails)
- [ ] Amplifier disabled or outputs disconnected
- [ ] RPi I2C disconnected during first power-up
- [ ] Current limits set on bench supply (if using)
- [ ] Emergency shutoff accessible

### First Power-On (no RPi)

1. **Apply power** (AC or bench supply)
2. **Immediately measure voltages**:
   ```
   +24V rail: Should be 24-29V DC
   +12V rail: Should be ~12V DC
   BK3.3V:    Should be ~3.3V DC
   ```
3. **Check current draw**:
   ```
   Idle: <500mA total
   If >1A: SHUTDOWN and investigate
   ```
4. **Look for**:
   - Smoke (NONE expected!)
   - Hot components (NONE expected in first 10 seconds)
   - Strange sounds (clicking relays is normal)
   - LEDs (LD201 should light if working)

5. **If all good**: Power off, wait 10 seconds for capacitors to discharge

### Second Power-On (with RPi I2C)

1. **Power board ON, RPi OFF**
2. **Connect RPi I2C** (SDA, SCL, GND only - not power)
3. **Power on RPi**
4. **Run i2cdetect**:
   ```bash
   i2cdetect -y 1
   ```
5. **Should see 0x40 and 0x41**

6. **Run your scripts**:
   ```bash
   python3 subwoofer_control.py
   ```

## Monitoring During Testing

### Critical Parameters to Watch

**Voltages** (use multimeter):
- +24V rail: 24-29V (stable)
- BK3.3V: 3.25-3.35V (stable)
- If voltage drops >10%: Current draw too high, investigate

**Currents** (if using bench supply):
- Idle: 100-500mA @ 24V
- Active (audio processing): 500mA-1A
- Amplifier active: 1-3A (depends on volume)
- **If >3A**: Something wrong!

**Temperature**:
- Feel IC401 (TAS5538): Should be cool to warm
- Feel IC501 (TAS5342): Should be cool (if idle)
- If too hot to touch: SHUTDOWN

### Test Progression

**Level 1**: Power + I2C Reading
- Only read registers
- No configuration writes
- Verify communication
- **Expected current**: <500mA

**Level 2**: Basic Configuration
- Write safe registers (volume, mute)
- Test pairing
- Read status
- **Expected current**: <500mA

**Level 3**: Audio DSP Active
- Configure TAS5538
- Enable audio paths
- **Expected current**: 500mA-1A

**Level 4**: Amplifier Testing (only if needed)
- Connect small speaker (8Ω, <10W)
- Set volume to MINIMUM
- Send test tone
- **Expected current**: 1-3A

## Emergency Shutdown Procedure

If anything goes wrong:

1. **Immediate**: Unplug AC power or turn off bench supply
2. **Wait**: 30 seconds for capacitors to discharge
3. **Inspect**: Look for damage, smell for burning
4. **Measure**: Check resistances between power rails
5. **Diagnose**: Before applying power again

## Pin-by-Pin Connection Reference

### Main Board Connectors

**CN501** (Subwoofer Output):
```
Pin 1: SUB+ (speaker positive)
Pin 2: SUB- (speaker negative)
```
**Leave disconnected for I2C testing**

**CN202** (Power Input) - 6-pin:
```
Pin 1: +24V (from power board J916)
Pin 2: +24V
Pin 3: GND (from power board J917)
Pin 4: GND
Pin 5: BK3.3V (from power board J918)
Pin 6: BK3.3V
```

**CN203** (Debug Header) - 4-pin:
```
Pin 1: 3.3V (can connect to RPi 3.3V for monitoring)
Pin 2: GND (MUST connect to RPi GND)
Pin 3: SDA (connect to RPi GPIO 2)
Pin 4: SCL (connect to RPi GPIO 3)
```

### Power Board Connectors

**CN901** (AC Input):
```
L (Line):   Hot wire (usually brown/black)
N (Neutral): Neutral wire (usually blue/white)
PE (Ground): Earth ground (usually green/yellow)
```
**Use proper AC cable with correct rating!**

**J916, J917, J918** (DC Outputs):
```
J916: +29V output
J917: GND
J918: BK3V3 (3.3V output)
```

## Safety Equipment

### Recommended

- **Multimeter** - Voltage, current, continuity
- **Current-limited power supply** - Prevents damage
- **Fire extinguisher** - Class C (electrical)
- **Safety glasses** - Capacitor failure protection
- **Insulated tools** - Prevent shorts

### Nice to Have

- **Oscilloscope** - Monitor power rails
- **Thermal camera** - Spot hot components
- **Isolation transformer** - AC mains safety

## Troubleshooting Power Issues

### No Voltage on Rails

1. Check AC input fuse (T4AH 250V)
2. Verify AC input voltage at CN901
3. Check bridge rectifier (BD901)
4. Test main transformer (T901, T902)
5. Check switching controller (IC902, IC903)

### Voltage Too Low

1. Excessive current draw (short circuit?)
2. Power supply overload
3. Faulty regulator

### Voltage Too High

1. Feedback loop failure
2. Zener diode failure (ZD902, ZD903)
3. Regulator fault

### I2C Stops Working with Full Power

1. Ground loops - ensure single common ground point
2. EMI from switching supply - add ferrite beads on I2C
3. Voltage droop - check 3.3V rail under load

## Recommended Testing Sequence

### Day 1: Low Risk
1. ✅ Bench supply at 3.3V only
2. ✅ Verify I2C communication
3. ✅ Read all registers
4. ✅ Test basic commands

### Day 2: Medium Risk
1. ✅ Add 24V from bench supply (current limited)
2. ✅ Test TAS5538 communication
3. ✅ Try pairing commands
4. ✅ Monitor current and temperature

### Day 3: Full Power (if needed)
1. ✅ Connect AC power board
2. ✅ Monitor all voltages
3. ✅ Test wireless functionality
4. ✅ Configure audio DSP

### Day 4: Audio Testing (optional)
1. ✅ Connect small test speaker
2. ✅ Minimum volume testing
3. ✅ Full system verification

## Final Safety Reminder

⚠️ **YOU ARE WORKING WITH**:
- AC Mains voltage (can kill)
- High current DC (can cause fires)
- Power amplifier (can damage speakers/equipment)

**ALWAYS**:
- Work with one hand when possible
- Keep workspace dry
- Have emergency shutoff accessible
- Double-check before applying power
- Start with lowest risk configuration
- Increase capability gradually

**NEVER**:
- Work on live AC circuits without training
- Leave powered equipment unattended
- Bypass safety features
- Test at high volume initially
