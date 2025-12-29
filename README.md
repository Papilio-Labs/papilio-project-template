# Papilio RetroCade Template Project

A PlatformIO template project for the Papilio RetroCade board featuring ESP32-S3 microcontroller and Gowin GW5A-25A FPGA. This template demonstrates communication between the ESP32 and FPGA via Wishbone SPI and includes RGB LED control using the WS2812B protocol.

## Features

- **Dual-Target Build**: Automatically builds both ESP32 firmware and FPGA bitstream
- **Wishbone SPI Bridge**: Communication between ESP32 and FPGA using Wishbone protocol
- **RGB LED Control**: WS2812B addressable RGB LED with pre-defined color cycling
- **Library Integration**: Uses papilio_wishbone_spi_master and papilio_wishbone_rgb_led libraries
- **Example Code**: Working example that cycles through multiple colors

## Hardware

- **Board**: Papilio RetroCade
- **MCU**: ESP32-S3 SuperMini
- **FPGA**: Gowin GW5A-25A (QFN88 package)
- **LED**: WS2812B addressable RGB LED
- **Clock**: 27MHz from ESP32 GPIO1

## Project Structure

```
papilio_project_template/
├── platformio.ini          # PlatformIO configuration
├── src/
│   └── main.cpp           # ESP32 application code
└── fpga/
    ├── project.gprj       # Gowin FPGA project file
    ├── src/
    │   ├── top.v          # FPGA top module
    │   ├── simple_spi_wb_bridge.v    # SPI to Wishbone bridge
    │   └── wb_simple_rgb_led.v       # RGB LED controller
    └── constraints/
        └── pins.cst       # Pin constraints for Papilio RetroCade
```

## Prerequisites

### Software

1. **PlatformIO**: Install from [platformio.org](https://platformio.org/)
2. **Gowin EDA**: Download from [Gowin Semiconductor](https://www.gowinsemi.com/)
   - Install to `C:\Gowin_V1.9.9` (or set `GOWIN_HOME` environment variable)
3. **pesptool** (for uploading): Automatically downloaded by PlatformIO on Windows
   - Linux/Mac: `pip install git+https://github.com/Papilio-Labs/pesptool.git`

### Hardware Setup

1. Connect the Papilio RetroCade board via USB-C
2. Identify the COM port (e.g., COM3 on Windows, /dev/ttyUSB0 on Linux)
3. Update `upload_port` in platformio.ini with your port

## Building

Build both ESP32 firmware and FPGA bitstream:

```bash
pio run
```

This will:
1. Compile the ESP32 C++ code
2. Build the FPGA bitstream using Gowin EDA
3. Generate `.pio/build/papilio_retrocade/firmware.bin` (ESP32)
4. Generate `.pio/build/papilio_retrocade/fpga_bitstream.bin` (FPGA)

## Uploading

Upload both ESP32 firmware and FPGA bitstream:

```bash
pio run -t upload
```

The upload process:
1. Uploads ESP32 firmware to address 0x0
2. Uploads FPGA bitstream to flash address 0x100000 (via pesptool)

**Note**: The Tang Primer bootloader must be pre-programmed at address 0x0 for FPGA upload to work.

## Monitoring

View serial output:

```bash
pio device monitor
```

Expected output:
```
====================================
  Papilio RetroCade Template
  ESP32-S3 + Gowin FPGA
====================================

Initializing SPI...
  SPI initialized
  CS:   GPIO10
  CLK:  GPIO12
  MOSI: GPIO11
  MISO: GPIO13

Initializing RGB LED...
Waiting for FPGA bootloader...
Waiting for FPGA to be ready...
FPGA ready after 0ms additional wait
  RGB LED initialized

Setting initial color: RED

Setup complete!
LED will cycle through colors every 2 seconds

Color: GREEN
Color: BLUE
Color: YELLOW
...
```

## Pin Mappings

### ESP32 to FPGA SPI

| ESP32 Pin | FPGA Pin | Signal | Description |
|-----------|----------|--------|-------------|
| GPIO10    | A10      | CS     | SPI Chip Select |
| GPIO11    | B11      | MOSI   | SPI Master Out Slave In |
| GPIO12    | B12      | SCLK   | SPI Clock |
| GPIO13    | C12      | MISO   | SPI Master In Slave Out |
| GPIO1     | A9       | CLK    | 27MHz Clock to FPGA |
| GPIO2     | L12      | RST_N  | Reset (active low) |

### FPGA Outputs

| FPGA Pin | Signal | Description |
|----------|--------|-------------|
| P9       | LED_OUT | WS2812B RGB LED Data |

## Customization

### Changing LED Colors

Edit the `colors[]` array in [src/main.cpp](src/main.cpp):

```cpp
const uint32_t colors[] = {
    RGBLed::COLOR_RED,
    RGBLed::COLOR_GREEN,
    RGBLed::COLOR_BLUE,
    // Add more colors...
};
```

Available color constants:
- `COLOR_OFF`, `COLOR_RED`, `COLOR_GREEN`, `COLOR_BLUE`
- `COLOR_YELLOW`, `COLOR_CYAN`, `COLOR_MAGENTA`
- `COLOR_WHITE`, `COLOR_ORANGE`, `COLOR_PURPLE`

Or create custom colors:
```cpp
uint32_t myColor = 0xGGRRBB;  // GRB format
RGBLed::setColor(myColor);

// Or using RGB components
RGBLed::setColorRGB(255, 128, 64);  // Red, Green, Blue
```

### Changing Color Cycle Speed

Modify the delay in [src/main.cpp](src/main.cpp) `loop()`:

```cpp
if (millis() - lastChange > 2000) {  // Change 2000 to desired milliseconds
```

### Adding FPGA Peripherals

1. Create new Verilog modules in [fpga/src/](fpga/src/)
2. Update [fpga/src/top.v](fpga/src/top.v) to instantiate your modules
3. Add pin constraints to [fpga/constraints/pins.cst](fpga/constraints/pins.cst)
4. Update [fpga/project.gprj](fpga/project.gprj) to include new files

### Adding Wishbone Peripherals

The template includes a simple direct connection between the Wishbone SPI bridge and the RGB LED controller. To add multiple peripherals:

1. Create a Wishbone address decoder
2. Assign address ranges to each peripheral
3. Update the FPGA top module to route Wishbone signals

Example address map:
```
0x00-0x03: RGB LED
0x04-0x07: Your peripheral
0x08-0x0B: Another peripheral
```

## Wishbone Register Map

### RGB LED (Address 0x00-0x03)

| Address | Register | Access | Description |
|---------|----------|--------|-------------|
| 0x00    | GREEN    | R/W    | Green value (0-255) |
| 0x01    | RED      | R/W    | Red value (0-255) |
| 0x02    | BLUE     | R/W    | Blue value (0-255) |
| 0x03    | STATUS   | R      | Bit 0: Busy flag |

Writing to any color register automatically triggers the WS2812B update.

## Troubleshooting

### Build Errors

**"gw_sh not found"**
- Install Gowin EDA or set `board_build.gowin_path` in platformio.ini

**"FPGA build failed"**
- Open `fpga/project.gprj` in Gowin IDE and try building manually
- Check for syntax errors in Verilog files

### Upload Errors

**"pesptool not found"**
- Windows: Should auto-download; check internet connection
- Linux/Mac: `pip install git+https://github.com/Papilio-Labs/pesptool.git`

**"Port not found"**
- Update `upload_port` in platformio.ini
- Check that the board is connected and drivers are installed

**"FPGA not responding"**
- Ensure Tang Primer bootloader is programmed
- Try increasing `bootloaderDelayMs` in main.cpp
- Check that GPIO1 provides 27MHz clock to FPGA

### Runtime Errors

**"FPGA may not be responding correctly"**
- FPGA bitstream may not be loaded correctly
- Try re-uploading with `pio run -t upload`
- Check SPI wiring and pin assignments

**LED not changing colors**
- Verify LED is connected to pin P9
- Check that FPGA bitstream was uploaded successfully
- Monitor serial output for error messages

## Libraries Used

- [papilio_wishbone_spi_master](https://github.com/Papilio-Labs/papilio_wishbone_spi_master): SPI to Wishbone bridge
- [papilio_wishbone_rgb_led](https://github.com/Papilio-Labs/papilio_wishbone_rgb_led): RGB LED controller API

## References

- [Papilio RetroCade Hardware](https://github.com/Papilio-Labs/papilio_retrocade_hardware)
- [Platform Gowin](https://github.com/Papilio-Labs/platform-gowin)
- [Gowin Semiconductor](https://www.gowinsemi.com/)
- [WS2812B Datasheet](https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf)

## License

This template project is provided as-is for use with Papilio RetroCade hardware.

## Support

For issues or questions:
- GitHub Issues: [platform-gowin](https://github.com/Papilio-Labs/platform-gowin/issues)
- Community: [Papilio Forums](https://papilio.cc/)
