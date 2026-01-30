#!/usr/bin/env python3
"""
TAS5538 Digital Audio Processor Control
Via DARR83 I2C Master Interface

The TAS5538 is controlled through the DARR83's I2C master bus
"""

import time
from darr83_control import DARR83

class TAS5538:
    """
    TAS5538 8-Channel Digital Audio PWM Processor Controller
    Controlled via DARR83 I2C master interface
    """
    
    # Common TAS5538 I2C addresses (determined by hardware strapping)
    POSSIBLE_ADDRESSES = [0x18, 0x1A, 0x1C, 0x1E, 0x2C, 0x2D, 0x2E, 0x2F]
    
    # Register addresses from TAS5538 datasheet
    REG_CLOCK_CTRL = 0x00
    REG_DEVICE_ID = 0x01
    REG_ERROR_STATUS = 0x02
    REG_SYSTEM_CTRL_1 = 0x03
    REG_SERIAL_DATA_IF = 0x04
    REG_SYSTEM_CTRL_2 = 0x05
    REG_SOFT_MUTE = 0x06
    REG_MASTER_VOL = 0x07
    REG_CH1_VOL = 0x08
    REG_CH2_VOL = 0x09
    REG_CH3_VOL = 0x0A
    REG_CH4_VOL = 0x0B
    REG_CH5_VOL = 0x0C
    REG_CH6_VOL = 0x0D
    REG_CH7_VOL = 0x0E
    REG_CH8_VOL = 0x0F
    REG_HP_VOL = 0x10
    REG_VOL_CONFIG = 0x11
    REG_MODULATION = 0x12
    REG_IC_DELAY_CH1 = 0x13
    REG_IC_DELAY_CH2 = 0x14
    REG_IC_DELAY_CH3 = 0x15
    REG_IC_DELAY_CH4 = 0x16
    REG_START_STOP_PERIOD = 0x1A
    REG_OSC_TRIM = 0x1B
    REG_BKND_ERR = 0x1C
    
    # Volume control constants
    VOL_MIN = 0xFF  # -127.5 dB (mute)
    VOL_MAX = 0x00  # 0 dB
    VOL_MUTE = 0xFF
    
    def __init__(self, darr83, address=None):
        """
        Initialize TAS5538 controller
        
        Args:
            darr83: DARR83 instance for I2C master communication
            address: TAS5538 I2C address (if known), otherwise will scan
        """
        self.darr = darr83
        self.address = address
        
        if self.address is None:
            print("TAS5538 address not specified, scanning...")
            self.address = self.find_address()
            if self.address:
                print(f"Found TAS5538 at address 0x{self.address:02X}")
            else:
                print("Warning: TAS5538 not found!")
    
    def find_address(self):
        """
        Scan possible TAS5538 addresses
        Returns: Address if found, None otherwise
        """
        print("Scanning for TAS5538...")
        for addr in self.POSSIBLE_ADDRESSES:
            print(f"  Trying 0x{addr:02X}...", end=" ")
            # Try to read device ID
            dev_id = self.read_register(addr, self.REG_DEVICE_ID)
            if dev_id is not None:
                print(f"Found! Device ID: 0x{dev_id:02X}")
                return addr
            print("No response")
        return None
    
    def read_register(self, address, register):
        """Read a register from TAS5538 via DARR83 master I2C"""
        return self.darr.i2c_master_read(address, register)
    
    def write_register(self, register, value):
        """Write a register to TAS5538 via DARR83 master I2C"""
        if self.address is None:
            print("Error: TAS5538 address not set!")
            return False
        self.darr.i2c_master_write(self.address, register, value)
        return True
    
    def get_device_id(self):
        """Read TAS5538 device ID"""
        return self.read_register(self.address, self.REG_DEVICE_ID)
    
    def get_error_status(self):
        """Read error status register"""
        return self.read_register(self.address, self.REG_ERROR_STATUS)
    
    def set_master_volume(self, volume):
        """
        Set master volume
        
        Args:
            volume: 0-255 (0 = 0dB max, 255 = mute, each step is 0.5dB)
        """
        return self.write_register(self.REG_MASTER_VOL, volume & 0xFF)
    
    def set_channel_volume(self, channel, volume):
        """
        Set individual channel volume
        
        Args:
            channel: Channel number (1-8)
            volume: 0-255 (0 = 0dB, 255 = mute)
        """
        if channel < 1 or channel > 8:
            print(f"Error: Invalid channel {channel}")
            return False
        
        reg = self.REG_CH1_VOL + (channel - 1)
        return self.write_register(reg, volume & 0xFF)
    
    def mute(self, enable=True):
        """
        Mute/unmute all channels
        
        Args:
            enable: True to mute, False to unmute
        """
        if enable:
            # Set all mute bits
            return self.write_register(self.REG_SOFT_MUTE, 0xFF)
        else:
            # Clear all mute bits
            return self.write_register(self.REG_SOFT_MUTE, 0x00)
    
    def soft_mute_channel(self, channel, enable=True):
        """
        Soft mute/unmute individual channel
        
        Args:
            channel: Channel number (1-8)
            enable: True to mute, False to unmute
        """
        current = self.read_register(self.address, self.REG_SOFT_MUTE)
        if current is None:
            return False
        
        if enable:
            # Set bit for this channel
            new_val = current | (1 << (channel - 1))
        else:
            # Clear bit for this channel
            new_val = current & ~(1 << (channel - 1))
        
        return self.write_register(self.REG_SOFT_MUTE, new_val)
    
    def reset(self):
        """Software reset of TAS5538"""
        # System control register reset
        return self.write_register(self.REG_SYSTEM_CTRL_1, 0x00)
    
    def power_down(self, enable=True):
        """
        Power down TAS5538
        
        Args:
            enable: True to power down, False to power up
        """
        current = self.read_register(self.address, self.REG_SYSTEM_CTRL_2)
        if current is None:
            return False
        
        if enable:
            new_val = current | 0x40  # Set power down bit
        else:
            new_val = current & ~0x40  # Clear power down bit
        
        return self.write_register(self.REG_SYSTEM_CTRL_2, new_val)
    
    def dump_status(self):
        """Print comprehensive TAS5538 status"""
        print("\n" + "="*60)
        print("TAS5538 Status Dump")
        print("="*60)
        
        if self.address is None:
            print("Error: TAS5538 address not set!")
            return
        
        print(f"\nI2C Address: 0x{self.address:02X}")
        
        dev_id = self.get_device_id()
        if dev_id is not None:
            print(f"Device ID: 0x{dev_id:02X}")
        
        error = self.get_error_status()
        if error is not None:
            print(f"Error Status: 0x{error:02X} (binary: {error:08b})")
            if error & 0x01:
                print("  - Clock Error")
            if error & 0x02:
                print("  - Overcurrent")
            if error & 0x04:
                print("  - DC Detect")
        
        # Read volume registers
        master_vol = self.read_register(self.address, self.REG_MASTER_VOL)
        if master_vol is not None:
            db = (master_vol - 255) * 0.5
            print(f"\nMaster Volume: 0x{master_vol:02X} ({db:+.1f} dB)")
        
        print("\nChannel Volumes:")
        for ch in range(1, 9):
            vol = self.read_register(self.address, self.REG_CH1_VOL + ch - 1)
            if vol is not None:
                db = (vol - 255) * 0.5
                print(f"  CH{ch}: 0x{vol:02X} ({db:+.1f} dB)")
        
        mute = self.read_register(self.address, self.REG_SOFT_MUTE)
        if mute is not None:
            print(f"\nMute Status: 0x{mute:02X} (binary: {mute:08b})")
            for ch in range(1, 9):
                is_muted = bool(mute & (1 << (ch - 1)))
                print(f"  CH{ch}: {'MUTED' if is_muted else 'Active'}")


def main():
    """Test TAS5538 control via DARR83"""
    print("TAS5538 Control via DARR83")
    print("="*60)
    
    # Initialize DARR83
    darr = DARR83(address=0x40)
    print("\nConnected to DARR83 at 0x40")
    
    # Initialize TAS5538
    tas = TAS5538(darr)
    
    if tas.address:
        # Dump status
        tas.dump_status()
        
        print("\n" + "="*60)
        print("Would you like to test volume control? (y/n): ", end="")
        response = input().strip().lower()
        
        if response == 'y':
            print("\nTesting volume control...")
            print("Setting master volume to -20dB...")
            tas.set_master_volume(40)  # 40 * 0.5dB = 20dB attenuation
            time.sleep(1)
            
            print("Muting...")
            tas.mute(True)
            time.sleep(1)
            
            print("Unmuting...")
            tas.mute(False)
            time.sleep(1)
            
            print("Restoring volume to 0dB...")
            tas.set_master_volume(0)
    
    darr.close()
    print("\nDone!")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
