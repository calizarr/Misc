#!/usr/bin/env python3
"""
Philips Fidelio Subwoofer - Interactive Control Interface
Complete control of DARR83 wireless module and TAS5538 DSP
"""

import sys
import time
from darr83_control import DARR83
from tas5538_control import TAS5538

class SubwooferController:
    """Complete subwoofer control interface"""
    
    def __init__(self):
        self.darr = None
        self.tas = None
        
    def connect(self):
        """Connect to both DARR83 and TAS5538"""
        print("Connecting to Philips Fidelio Subwoofer...")
        print("-" * 60)
        
        # Try both DARR83 addresses
        for addr in [0x40, 0x41]:
            try:
                print(f"\nTrying DARR83 at 0x{addr:02X}...", end=" ")
                darr = DARR83(address=addr)
                dev_id = darr.get_device_id()
                if dev_id is not None:
                    print(f"✓ Connected! (ID: 0x{dev_id:02X})")
                    self.darr = darr
                    break
                else:
                    print("✗ No response")
                    darr.close()
            except Exception as e:
                print(f"✗ Error: {e}")
        
        if self.darr is None:
            print("\n✗ Failed to connect to DARR83")
            return False
        
        # Connect to TAS5538 through DARR83
        print("\nSearching for TAS5538...", end=" ")
        self.tas = TAS5538(self.darr)
        
        if self.tas.address:
            print("✓ Connected!")
            return True
        else:
            print("✗ Not found (may be normal if TAS5538 uses different addressing)")
            return True  # Still return True as DARR83 is connected
    
    def disconnect(self):
        """Disconnect from devices"""
        if self.darr:
            self.darr.close()
    
    def show_status(self):
        """Display complete system status"""
        print("\n" + "="*60)
        print("SYSTEM STATUS")
        print("="*60)
        
        if self.darr:
            self.darr.dump_status()
        
        if self.tas and self.tas.address:
            self.tas.dump_status()
        
        print()
    
    def interactive_menu(self):
        """Interactive control menu"""
        while True:
            print("\n" + "="*60)
            print("PHILIPS FIDELIO SUBWOOFER CONTROL")
            print("="*60)
            print("\n[DARR83 Wireless Module]")
            print("  1. Show status")
            print("  2. Scan all DARR83 registers")
            print("  3. Read link status")
            print("  4. Read signal quality")
            print("  5. Enter pairing mode")
            print("  6. Exit pairing mode")
            
            if self.tas and self.tas.address:
                print("\n[TAS5538 Audio DSP]")
                print("  11. Show TAS5538 status")
                print("  12. Set master volume")
                print("  13. Mute/Unmute")
                print("  14. Set channel volume")
                print("  15. Test volume sweep")
                print("  16. Scan TAS5538 registers")
            
            print("\n[System]")
            print("  90. Refresh connection")
            print("  91. Read raw register")
            print("  92. Write raw register")
            print("  0. Exit")
            
            print("\nChoice: ", end="")
            try:
                choice = input().strip()
                
                if choice == '0':
                    print("\nExiting...")
                    break
                elif choice == '1':
                    self.show_status()
                elif choice == '2':
                    if self.darr:
                        self.darr.scan_registers(0, 128)
                elif choice == '3':
                    if self.darr:
                        link = self.darr.get_link_status()
                        if link is not None:
                            print(f"\nLink Status: 0x{link:02X} (binary: {link:08b})")
                            print(f"Connected: {'Yes' if link & 0x01 else 'No'}")
                elif choice == '4':
                    if self.darr:
                        quality = self.darr.get_signal_quality()
                        if quality is not None:
                            print(f"\nSignal Quality: {quality}/255 ({quality*100//255}%)")
                elif choice == '5':
                    if self.darr:
                        print("\nEntering pairing mode...")
                        self.darr.enter_pairing_mode()
                        print("Done! Watch for pairing LED.")
                elif choice == '6':
                    if self.darr:
                        print("\nExiting pairing mode...")
                        self.darr.exit_pairing_mode()
                        print("Done!")
                
                elif choice == '11':
                    if self.tas and self.tas.address:
                        self.tas.dump_status()
                elif choice == '12':
                    if self.tas and self.tas.address:
                        print("\nEnter volume (0=max, 255=mute): ", end="")
                        vol = int(input().strip())
                        self.tas.set_master_volume(vol)
                        print(f"Set volume to {vol}")
                elif choice == '13':
                    if self.tas and self.tas.address:
                        print("\nMute? (y/n): ", end="")
                        mute = input().strip().lower() == 'y'
                        self.tas.mute(mute)
                        print("Muted!" if mute else "Unmuted!")
                elif choice == '14':
                    if self.tas and self.tas.address:
                        print("\nChannel (1-8): ", end="")
                        ch = int(input().strip())
                        print("Volume (0=max, 255=mute): ", end="")
                        vol = int(input().strip())
                        self.tas.set_channel_volume(ch, vol)
                        print(f"Set CH{ch} volume to {vol}")
                elif choice == '15':
                    if self.tas and self.tas.address:
                        print("\nRunning volume sweep test...")
                        for vol in range(0, 100, 10):
                            print(f"Volume: {vol}")
                            self.tas.set_master_volume(vol)
                            time.sleep(0.5)
                        print("Sweep complete!")
                elif choice == '16':
                    if self.tas and self.tas.address:
                        print("\nScanning TAS5538 registers...")
                        for reg in range(0x00, 0x30):
                            val = self.tas.read_register(self.tas.address, reg)
                            if val is not None:
                                print(f"Reg 0x{reg:02X}: 0x{val:02X} ({val})")
                
                elif choice == '90':
                    print("\nRefreshing connection...")
                    self.disconnect()
                    self.connect()
                elif choice == '91':
                    if self.darr:
                        print("\nDevice (0=DARR83, 1=TAS5538): ", end="")
                        dev = int(input().strip())
                        print("Register address (hex): ", end="")
                        reg = int(input().strip(), 16)
                        
                        if dev == 0:
                            val = self.darr.read_register(reg)
                        else:
                            if not self.tas or not self.tas.address:
                                print("TAS5538 not connected!")
                                continue
                            val = self.tas.read_register(self.tas.address, reg)
                        
                        if val is not None:
                            print(f"\nValue: 0x{val:02X} ({val}) binary: {val:08b}")
                elif choice == '92':
                    if self.darr:
                        print("\nWARNING: Writing to wrong registers can damage hardware!")
                        print("Device (0=DARR83, 1=TAS5538): ", end="")
                        dev = int(input().strip())
                        print("Register address (hex): ", end="")
                        reg = int(input().strip(), 16)
                        print("Value (0-255): ", end="")
                        val = int(input().strip())
                        
                        print(f"\nWrite 0x{val:02X} to register 0x{reg:02X}? (yes/no): ", end="")
                        confirm = input().strip().lower()
                        
                        if confirm == 'yes':
                            if dev == 0:
                                self.darr.write_register(reg, val)
                            else:
                                if not self.tas or not self.tas.address:
                                    print("TAS5538 not connected!")
                                    continue
                                self.tas.write_register(reg, val)
                            print("Written!")
                else:
                    print("\nInvalid choice!")
                
                input("\nPress Enter to continue...")
                
            except ValueError as e:
                print(f"\nInvalid input: {e}")
                input("\nPress Enter to continue...")
            except KeyboardInterrupt:
                print("\n\nInterrupted!")
                break
            except Exception as e:
                print(f"\nError: {e}")
                import traceback
                traceback.print_exc()
                input("\nPress Enter to continue...")


def main():
    """Main entry point"""
    print("\n" + "="*60)
    print("PHILIPS FIDELIO HTL9100 SUBWOOFER CONTROL")
    print("I2C Control via Raspberry Pi")
    print("="*60)
    
    controller = SubwooferController()
    
    if not controller.connect():
        print("\n✗ Failed to connect to subwoofer")
        return 1
    
    try:
        controller.interactive_menu()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
    finally:
        controller.disconnect()
    
    print("\nGoodbye!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
