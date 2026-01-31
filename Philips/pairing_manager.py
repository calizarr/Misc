#!/usr/bin/env python3
"""
DARR83/DWHP83 Pairing Management Tool

This tool helps you:
1. Clear existing pairing
2. Enter pairing mode
3. Save/restore pairing configurations
4. Monitor pairing status

Based on typical SMSC/Microchip wireless audio chip behavior
"""

import smbus2
import time
import sys
import json
from datetime import datetime

class PairingManager:
    """Manage DARR83 wireless pairing"""
    
    def __init__(self, address=0x40, bus_number=1):
        self.bus = smbus2.SMBus(bus_number)
        self.address = address
        
        # Typical pairing-related registers (may need adjustment)
        self.REG_PAIRING_CONTROL = 0x07
        self.REG_PAIRING_STATUS = 0x03
        self.REG_PAIRING_KEY_START = 0x10  # Pairing key storage (typical range 0x10-0x1F)
        self.REG_DEVICE_ID = 0x20  # Device ID storage
        self.REG_FACTORY_RESET = 0xFF  # Factory reset trigger (if exists)
        
    def read_reg(self, reg):
        """Safe register read"""
        try:
            return self.bus.read_byte_data(self.address, reg)
        except Exception as e:
            return None
    
    def write_reg(self, reg, value):
        """Safe register write"""
        try:
            self.bus.write_byte_data(self.address, reg, value)
            return True
        except Exception as e:
            print(f"Write error: {e}")
            return False
    
    def read_pairing_key(self):
        """
        Read the current pairing key
        Typically 16 bytes stored in consecutive registers
        """
        print("\nReading pairing key...")
        key_bytes = []
        
        for offset in range(16):
            reg = self.REG_PAIRING_KEY_START + offset
            val = self.read_reg(reg)
            if val is not None:
                key_bytes.append(val)
            else:
                print(f"  Register 0x{reg:02X}: No response")
                key_bytes.append(0x00)
        
        print("\nPairing Key (16 bytes):")
        print("Offset | Hex  | Dec | Char")
        print("-" * 35)
        for i, byte in enumerate(key_bytes):
            char = chr(byte) if 32 <= byte < 127 else '.'
            print(f"  {i:2d}   | 0x{byte:02X} | {byte:3d} | '{char}'")
        
        # Display as hex string
        key_hex = ''.join(f'{b:02X}' for b in key_bytes)
        print(f"\nKey (hex): {key_hex}")
        
        return key_bytes
    
    def write_pairing_key(self, key_bytes):
        """
        Write a new pairing key
        
        Args:
            key_bytes: List of 16 bytes
        """
        if len(key_bytes) != 16:
            print(f"Error: Key must be 16 bytes, got {len(key_bytes)}")
            return False
        
        print("\nWriting pairing key...")
        success = True
        
        for offset, byte in enumerate(key_bytes):
            reg = self.REG_PAIRING_KEY_START + offset
            if self.write_reg(reg, byte):
                print(f"  0x{reg:02X} = 0x{byte:02X} ✓")
            else:
                print(f"  0x{reg:02X} = 0x{byte:02X} ✗")
                success = False
        
        return success
    
    def clear_pairing(self):
        """
        Clear/reset pairing data
        Sets pairing key to all zeros
        """
        print("\n" + "="*60)
        print("CLEAR PAIRING DATA")
        print("="*60)
        print("\nThis will erase the current pairing key.")
        print("The device will need to be paired again.\n")
        
        response = input("Continue? (type 'yes' to confirm): ").strip().lower()
        
        if response != 'yes':
            print("Cancelled.")
            return False
        
        # Write zeros to pairing key registers
        zero_key = [0x00] * 16
        
        print("\nClearing pairing key...")
        if self.write_pairing_key(zero_key):
            print("✓ Pairing key cleared!")
            
            # Verify
            print("\nVerifying...")
            new_key = self.read_pairing_key()
            if all(b == 0 for b in new_key):
                print("✓ Verification successful!")
                return True
            else:
                print("⚠ Verification failed - key not fully cleared")
                return False
        else:
            print("✗ Failed to clear pairing key")
            return False
    
    def enter_pairing_mode(self, duration=30):
        """
        Enter pairing mode
        
        Args:
            duration: Seconds to stay in pairing mode
        """
        print("\n" + "="*60)
        print("ENTER PAIRING MODE")
        print("="*60)
        
        # Common pairing mode sequences
        pairing_commands = [
            (self.REG_PAIRING_CONTROL, 0x01, "Method 1: Set pairing bit"),
            (self.REG_PAIRING_CONTROL, 0xFF, "Method 2: Set all bits"),
            (self.REG_PAIRING_CONTROL, 0x80, "Method 3: Set MSB"),
        ]
        
        print("\nTrying different pairing methods...")
        for reg, val, desc in pairing_commands:
            print(f"\n{desc}")
            if self.write_reg(reg, val):
                print("  ✓ Command sent")
                
                # Check status
                time.sleep(0.5)
                status = self.read_reg(self.REG_PAIRING_STATUS)
                if status is not None:
                    print(f"  Status: 0x{status:02X} (binary: {status:08b})")
                    
                    # Look for pairing mode indicator (typically bit 0 or 7)
                    if status & 0x01 or status & 0x80:
                        print("  ✓ Appears to be in pairing mode!")
                        print(f"\nPairing mode active for {duration} seconds...")
                        print("Pair your transmitter now!")
                        
                        # Monitor status during pairing
                        start_time = time.time()
                        while time.time() - start_time < duration:
                            remaining = duration - int(time.time() - start_time)
                            status = self.read_reg(self.REG_PAIRING_STATUS)
                            print(f"\r  Time: {remaining}s | Status: 0x{status:02X if status else 0:02X}  ", end="")
                            time.sleep(1)
                        
                        print("\n\n✓ Pairing window closed")
                        return True
            else:
                print("  ✗ Command failed")
        
        print("\n⚠ Could not enter pairing mode with standard methods")
        print("You may need to:")
        print("  1. Use the physical pairing button")
        print("  2. Check if full power is needed")
        print("  3. Try different register addresses")
        return False
    
    def exit_pairing_mode(self):
        """Exit pairing mode"""
        print("\nExiting pairing mode...")
        return self.write_reg(self.REG_PAIRING_CONTROL, 0x00)
    
    def save_pairing_config(self, filename=None):
        """
        Save current pairing configuration to file
        
        Args:
            filename: Output filename (default: pairing_backup_TIMESTAMP.json)
        """
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"pairing_backup_{timestamp}.json"
        
        print(f"\nSaving pairing configuration to {filename}...")
        
        # Read all pairing-related registers
        config = {
            'timestamp': datetime.now().isoformat(),
            'device_address': self.address,
            'pairing_key': self.read_pairing_key(),
            'pairing_control': self.read_reg(self.REG_PAIRING_CONTROL),
            'pairing_status': self.read_reg(self.REG_PAIRING_STATUS),
        }
        
        # Read extended config (registers 0x00-0x30)
        config['extended_config'] = {}
        for reg in range(0x00, 0x31):
            val = self.read_reg(reg)
            if val is not None:
                config['extended_config'][f'0x{reg:02X}'] = val
        
        try:
            with open(filename, 'w') as f:
                json.dump(config, f, indent=2)
            print(f"✓ Configuration saved to {filename}")
            return True
        except Exception as e:
            print(f"✗ Error saving: {e}")
            return False
    
    def restore_pairing_config(self, filename):
        """
        Restore pairing configuration from file
        
        Args:
            filename: Input filename
        """
        print(f"\nRestoring pairing configuration from {filename}...")
        
        try:
            with open(filename, 'r') as f:
                config = json.load(f)
            
            print(f"Backup from: {config.get('timestamp', 'unknown')}")
            print(f"Device address: 0x{config.get('device_address', 0):02X}")
            
            response = input("\nContinue with restore? (type 'yes'): ").strip().lower()
            if response != 'yes':
                print("Cancelled.")
                return False
            
            # Restore pairing key
            if 'pairing_key' in config:
                print("\nRestoring pairing key...")
                self.write_pairing_key(config['pairing_key'])
            
            # Restore other registers
            if 'extended_config' in config:
                print("\nRestoring extended configuration...")
                for reg_str, val in config['extended_config'].items():
                    reg = int(reg_str, 16)
                    if 0x10 <= reg <= 0x1F:  # Skip pairing key area (already restored)
                        continue
                    self.write_reg(reg, val)
                    print(f"  0x{reg:02X} = 0x{val:02X}")
            
            print("\n✓ Configuration restored!")
            return True
            
        except Exception as e:
            print(f"✗ Error restoring: {e}")
            return False
    
    def scan_for_pairing_registers(self):
        """
        Scan all registers and try to identify pairing-related ones
        """
        print("\n" + "="*60)
        print("SCANNING FOR PAIRING REGISTERS")
        print("="*60)
        
        # Read all registers
        initial = {}
        print("\nReading initial state...")
        for reg in range(0x00, 0x100):
            val = self.read_reg(reg)
            if val is not None:
                initial[reg] = val
        
        print(f"Found {len(initial)} readable registers")
        
        # Try toggling pairing mode and see what changes
        print("\nTrying to enter pairing mode...")
        self.write_reg(self.REG_PAIRING_CONTROL, 0x01)
        time.sleep(1)
        
        print("Reading changed state...")
        changed = {}
        for reg in range(0x00, 0x100):
            val = self.read_reg(reg)
            if val is not None:
                changed[reg] = val
        
        print("\nExiting pairing mode...")
        self.write_reg(self.REG_PAIRING_CONTROL, 0x00)
        
        # Find differences
        print("\n" + "="*60)
        print("REGISTERS THAT CHANGED (likely pairing-related):")
        print("="*60)
        print("\nReg  | Initial | Changed | Diff")
        print("-" * 40)
        
        found_changes = False
        for reg in sorted(set(initial.keys()) | set(changed.keys())):
            init_val = initial.get(reg, None)
            chng_val = changed.get(reg, None)
            
            if init_val != chng_val:
                found_changes = True
                diff = ""
                if init_val is not None and chng_val is not None:
                    diff = f"0x{init_val:02X} -> 0x{chng_val:02X}"
                    # Binary diff
                    xor = init_val ^ chng_val
                    diff += f" (XOR: {xor:08b})"
                print(f"0x{reg:02X} | {init_val or '--':>7} | {chng_val or '--':>7} | {diff}")
        
        if not found_changes:
            print("No changes detected - pairing registers may be different")
            print("or device may need full power to respond to pairing commands")
    
    def close(self):
        """Close I2C bus"""
        self.bus.close()


def main():
    """Interactive pairing management"""
    print("\n" + "="*60)
    print("DARR83/DWHP83 PAIRING MANAGEMENT TOOL")
    print("="*60)
    
    # Try both addresses
    mgr = None
    for addr in [0x40, 0x41]:
        try:
            test_mgr = PairingManager(address=addr)
            if test_mgr.read_reg(0x00) is not None:
                mgr = test_mgr
                print(f"\n✓ Connected to DARR83 at 0x{addr:02X}")
                break
            test_mgr.close()
        except:
            pass
    
    if mgr is None:
        print("\n✗ Could not connect to DARR83")
        return 1
    
    try:
        while True:
            print("\n" + "="*60)
            print("PAIRING MANAGEMENT MENU")
            print("="*60)
            print("\n1. Read current pairing key")
            print("2. Clear pairing (reset to zeros)")
            print("3. Enter pairing mode")
            print("4. Exit pairing mode")
            print("5. Save pairing configuration")
            print("6. Restore pairing configuration")
            print("7. Scan for pairing registers")
            print("8. Generate random pairing key")
            print("0. Exit")
            
            choice = input("\nChoice: ").strip()
            
            if choice == '0':
                break
            elif choice == '1':
                mgr.read_pairing_key()
            elif choice == '2':
                mgr.clear_pairing()
            elif choice == '3':
                duration = input("Pairing mode duration (seconds, default 30): ").strip()
                duration = int(duration) if duration else 30
                mgr.enter_pairing_mode(duration)
            elif choice == '4':
                mgr.exit_pairing_mode()
            elif choice == '5':
                filename = input("Filename (press Enter for auto): ").strip()
                mgr.save_pairing_config(filename if filename else None)
            elif choice == '6':
                filename = input("Filename to restore: ").strip()
                if filename:
                    mgr.restore_pairing_config(filename)
            elif choice == '7':
                mgr.scan_for_pairing_registers()
            elif choice == '8':
                import random
                random_key = [random.randint(0, 255) for _ in range(16)]
                print("\nGenerated random key:")
                print(''.join(f'{b:02X}' for b in random_key))
                if input("Write this key? (yes/no): ").strip().lower() == 'yes':
                    mgr.write_pairing_key(random_key)
            
            input("\nPress Enter to continue...")
            
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
    finally:
        mgr.close()
    
    print("\nGoodbye!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
