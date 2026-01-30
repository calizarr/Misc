#!/usr/bin/env python3
"""
DARR83 Wireless Audio Receiver Control Library
Based on Microchip DARR83 datasheet

The DARR83 is used in the DWHP83/DWAM83 wireless audio modules
"""

import smbus2
import time
import struct

class DARR83:
    """
    DARR83 Wireless Audio Receiver Controller
    
    The DARR83 has both master and slave I2C interfaces:
    - Slave I2C: Receives commands from host (your Raspberry Pi)
    - Master I2C: Controls downstream devices (TAS5538)
    """
    
    # Default I2C slave addresses
    ADDR_PRIMARY = 0x40
    ADDR_SECONDARY = 0x41
    
    # Common register addresses (based on typical SMSC/Microchip audio chips)
    # These need to be verified from actual datasheet
    REG_DEVICE_ID = 0x00
    REG_STATUS = 0x01
    REG_CONTROL = 0x02
    REG_LINK_STATUS = 0x03
    REG_SIGNAL_QUALITY = 0x04
    REG_VOLUME = 0x05
    REG_MUTE = 0x06
    REG_PAIRING = 0x07
    REG_ERROR = 0x08
    REG_CONFIG = 0x09
    REG_I2C_MASTER_ADDR = 0x0A
    REG_I2C_MASTER_REG = 0x0B
    REG_I2C_MASTER_DATA = 0x0C
    REG_I2C_MASTER_CTRL = 0x0D
    
    def __init__(self, bus_number=1, address=ADDR_PRIMARY):
        """
        Initialize DARR83 controller
        
        Args:
            bus_number: I2C bus number (default 1 for Raspberry Pi)
            address: I2C slave address (default 0x40)
        """
        self.bus = smbus2.SMBus(bus_number)
        self.address = address
        
    def read_register(self, register):
        """Read a single byte from a register"""
        try:
            return self.bus.read_byte_data(self.address, register)
        except Exception as e:
            print(f"Error reading register 0x{register:02X}: {e}")
            return None
    
    def write_register(self, register, value):
        """Write a single byte to a register"""
        try:
            self.bus.write_byte_data(self.address, register, value)
            return True
        except Exception as e:
            print(f"Error writing register 0x{register:02X}: {e}")
            return False
    
    def read_registers(self, start_register, count):
        """Read multiple consecutive registers"""
        try:
            return self.bus.read_i2c_block_data(self.address, start_register, count)
        except Exception as e:
            print(f"Error reading registers: {e}")
            return None
    
    def get_device_id(self):
        """Read device ID register"""
        return self.read_register(self.REG_DEVICE_ID)
    
    def get_status(self):
        """Read status register"""
        return self.read_register(self.REG_STATUS)
    
    def get_link_status(self):
        """
        Read wireless link status
        Returns: Status byte or None
        """
        return self.read_register(self.REG_LINK_STATUS)
    
    def get_signal_quality(self):
        """
        Read wireless signal quality/strength
        Returns: Signal quality value or None
        """
        return self.read_register(self.REG_SIGNAL_QUALITY)
    
    def set_volume(self, level):
        """
        Set volume level
        
        Args:
            level: Volume level (0-255, implementation dependent)
        """
        return self.write_register(self.REG_VOLUME, level & 0xFF)
    
    def set_mute(self, muted=True):
        """
        Mute/unmute audio
        
        Args:
            muted: True to mute, False to unmute
        """
        return self.write_register(self.REG_MUTE, 0x01 if muted else 0x00)
    
    def enter_pairing_mode(self):
        """
        Enter pairing mode to connect to transmitter
        Implementation varies by chip version
        """
        # Common pairing command - may need adjustment
        return self.write_register(self.REG_PAIRING, 0x01)
    
    def exit_pairing_mode(self):
        """Exit pairing mode"""
        return self.write_register(self.REG_PAIRING, 0x00)
    
    def i2c_master_write(self, target_addr, register, value):
        """
        Write to a device on the DARR83's master I2C bus
        This allows you to control the TAS5538 through the DARR83
        
        Args:
            target_addr: I2C address of target device (e.g., TAS5538)
            register: Register address on target device
            value: Value to write
        """
        # Set target device address
        self.write_register(self.REG_I2C_MASTER_ADDR, target_addr)
        # Set register address
        self.write_register(self.REG_I2C_MASTER_REG, register)
        # Set data value
        self.write_register(self.REG_I2C_MASTER_DATA, value)
        # Trigger write operation
        self.write_register(self.REG_I2C_MASTER_CTRL, 0x01)
        time.sleep(0.01)  # Wait for operation
        
    def i2c_master_read(self, target_addr, register):
        """
        Read from a device on the DARR83's master I2C bus
        
        Args:
            target_addr: I2C address of target device
            register: Register address to read
        Returns:
            Value read from target device
        """
        # Set target device address
        self.write_register(self.REG_I2C_MASTER_ADDR, target_addr)
        # Set register address
        self.write_register(self.REG_I2C_MASTER_REG, register)
        # Trigger read operation
        self.write_register(self.REG_I2C_MASTER_CTRL, 0x02)
        time.sleep(0.01)  # Wait for operation
        # Read result
        return self.read_register(self.REG_I2C_MASTER_DATA)
    
    def scan_registers(self, start=0, end=256):
        """
        Scan and display all readable registers
        
        Args:
            start: Starting register address
            end: Ending register address
        """
        print(f"\nScanning registers 0x{start:02X} to 0x{end-1:02X}:")
        print("Reg  | Value (hex) | Value (bin)     | Value (dec)")
        print("-" * 55)
        
        readable = []
        for reg in range(start, end):
            val = self.read_register(reg)
            if val is not None:
                print(f"0x{reg:02X} | 0x{val:02X}      | {val:08b} | {val:3d}")
                readable.append((reg, val))
        
        print(f"\nFound {len(readable)} readable registers")
        return readable
    
    def dump_status(self):
        """Print comprehensive status information"""
        print("\n" + "="*60)
        print("DARR83 Status Dump")
        print("="*60)
        
        print(f"\nI2C Address: 0x{self.address:02X}")
        
        dev_id = self.get_device_id()
        if dev_id is not None:
            print(f"Device ID: 0x{dev_id:02X} ({dev_id})")
        
        status = self.get_status()
        if status is not None:
            print(f"Status: 0x{status:02X} (binary: {status:08b})")
        
        link = self.get_link_status()
        if link is not None:
            print(f"Link Status: 0x{link:02X}")
            print(f"  Connected: {'Yes' if link & 0x01 else 'No'}")
        
        signal = self.get_signal_quality()
        if signal is not None:
            print(f"Signal Quality: {signal}/255 ({signal*100//255}%)")
    
    def close(self):
        """Close I2C bus"""
        self.bus.close()


def main():
    """Test and demonstrate DARR83 functionality"""
    print("DARR83 Wireless Audio Receiver - Control Interface")
    print("="*60)
    
    # Try both addresses
    for addr in [DARR83.ADDR_PRIMARY, DARR83.ADDR_SECONDARY]:
        print(f"\n\nTesting address 0x{addr:02X}:")
        print("-"*60)
        
        darr = DARR83(address=addr)
        
        # Dump status
        darr.dump_status()
        
        # Scan first 32 registers
        print("\nFirst 32 registers:")
        darr.scan_registers(0, 32)
        
        darr.close()
        
        input("\nPress Enter to continue...")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
