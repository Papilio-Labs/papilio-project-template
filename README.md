# Papilio RetroCade - Wishbone Auto-Builder Template

This is a ready-to-use project template for Papilio RetroCade featuring the **Papilio Automatic Library Builder**. Simply add Papilio Wishbone libraries to your dependencies and they will be automatically integrated into both your FPGA gateware and ESP32 firmware.

## Features

- **Automatic Library Integration**: Add libraries to `platformio.ini` and they're auto-wired
- **Wishbone Bus Infrastructure**: Standard 32-bit Wishbone bus ready for peripherals
- **SPI-to-Wishbone Bridge**: ESP32 communicates with FPGA peripherals over SPI
- **Non-conflicting Addresses**: Automatic address allocation prevents conflicts
- **Dual-Target Build**: Single `pio run` builds both ESP32 and FPGA
- **Marker-Based Injection**: Generated code is cleanly separated from your custom code

## Hardware

- **MCU**: ESP32-S3 SuperMini
- **FPGA**: Gowin GW2A-18 (Papilio RetroCade)
- **Communication**: SPI interface (ESP32 ↔ FPGA)
- **Wishbone**: 32-bit data, 16-bit address, classic protocol

## Quick Start

### 1. Add Papilio Libraries

Edit `platformio.ini` and add libraries to `lib_deps`:

```ini
lib_deps = 
    https://github.com/Papilio-Labs/papilio_spi_slave.git
    https://github.com/Papilio-Labs/papilio_wishbone_register.git
    https://github.com/Papilio-Labs/papilio_wishbone_rgb_led.git
```

### 2. Build the Project

```bash
# Build both ESP32 and FPGA
pio run

# Or build individually
pio run -e esp32  # ESP32 only
pio run -e fpga   # FPGA only
```

The auto-builder will:
- ✅ Discover libraries from `lib_deps`
- ✅ Generate FPGA module instantiations
- ✅ Create Wishbone interconnect logic
- ✅ Allocate non-conflicting addresses
- ✅ Generate ESP32 initialization code
- ✅ Add library HDL files to FPGA project

### 3. Upload and Run

```bash
# Upload both ESP32 firmware and FPGA bitstream
pio run -t upload

# Monitor serial output
pio device monitor
```

## How It Works

### Auto-Generation Markers

The template files contain special marker comments that define regions for auto-generated code:

**In `fpga/src/top.v`:**
```verilog
//# PAPILIO_AUTO_PORTS_BEGIN
// Generated port declarations appear here
//# PAPILIO_AUTO_PORTS_END
```

**In `src/main.cpp`:**
```cpp
//# PAPILIO_AUTO_INCLUDES_BEGIN
// Generated #includes appear here
//# PAPILIO_AUTO_INCLUDES_END
```

Your code outside these markers is **never modified** by the auto-builder.

### Marker Types

| Marker | Location | Purpose |
|--------|----------|---------|
| `PAPILIO_AUTO_PORTS` | top.v | External I/O port declarations |
| `PAPILIO_AUTO_WIRES` | top.v | Internal wire declarations |
| `PAPILIO_AUTO_MODULE_INST` | top.v | Module instantiations |
| `PAPILIO_AUTO_WISHBONE` | top.v | Wishbone interconnect logic |
| `PAPILIO_AUTO_INCLUDES` | main.cpp | Library header includes |
| `PAPILIO_AUTO_GLOBALS` | main.cpp | Peripheral object declarations |
| `PAPILIO_AUTO_INIT` | main.cpp | Initialization code in setup() |
| `PAPILIO_AUTO_CLI` | main.cpp | CLI command dispatcher |

## Available Papilio Libraries

### Core Infrastructure
- **papilio_spi_slave**: SPI to Wishbone bridge (required for ESP32 communication)

### Peripherals
- **papilio_wishbone_register**: General-purpose registers for status/control
- **papilio_wishbone_rgb_led**: WS2812B RGB LED controller
- **papilio_wishbone_bram**: Block RAM for data buffering

### More Coming Soon
Visit [Papilio Labs GitHub](https://github.com/Papilio-Labs) for the latest libraries.

## Address Map

The auto-builder allocates Wishbone addresses automatically:

| Address Range | Size | Typical Use |
|---------------|------|-------------|
| 0x0000-0x0FFF | 4KB | SPI Bridge (auto-assigned first) |
| 0x1000-0x1FFF | 4KB | Peripheral slot 1 |
| 0x2000-0x2FFF | 4KB | Peripheral slot 2 |
| 0x3000-0x3FFF | 4KB | Peripheral slot 3 |
| ... | | More slots as needed |

Addresses are allocated in 4KB (0x1000) increments by default.

## Customization

### Adding Custom Logic to FPGA

Edit `fpga/src/top.v` and add your code outside the marker regions:

```verilog
// User Logic section (end of file)
// Connect auto-generated peripherals to external pins
assign led_out = papilio_rgb_led_data;  // Example
```

### Adding Custom ESP32 Code

Edit `src/main.cpp` and add your code outside the marker regions:

```cpp
void loop() {
    // Your custom code here
    doCustomStuff();
    
    // Auto-generated CLI handling
    //# PAPILIO_AUTO_CLI_BEGIN
    //# PAPILIO_AUTO_CLI_END
}
```

### Disabling Auto-Generation

To take manual control of a section, simply remove its markers. The builder will skip that section.

### Pin Constraints

The auto-builder does **not** generate pin constraints. You must manually edit `fpga/constraints/pins.cst` to connect peripheral I/O to physical pins.

Constraint files from libraries are automatically included but only provide standard connections (SPI, clock, reset).

## Configuration Options

In `platformio.ini`:

```ini
[env:fpga]
; Enable/disable auto-builder (default: enabled)
board_build.papilio_auto_builder = 1

; Enable verbose output to see what's being generated
board_build.papilio_verbose = 1
```

## Project Structure

```
papilio_project_template/
├── platformio.ini          # Project configuration
├── README.md               # This file
├── fpga/
│   ├── project.gprj        # Gowin project (auto-updated)
│   ├── src/
│   │   └── top.v           # Top module with markers
│   └── constraints/
│       └── pins.cst        # Manual pin assignments
└── src/
    └── main.cpp            # ESP32 code with markers
```

## Building

```bash
# Build everything
pio run

# Build and upload
pio run -t upload

# Clean and rebuild
pio run -t clean
pio run

# Monitor serial output
pio device monitor

# Build with verbose auto-builder output
pio run -e fpga -v
```

## Troubleshooting

### "No Papilio libraries found"

Make sure libraries are added to `lib_deps` in `platformio.ini` and have proper `papilio` metadata in their `library.json`.

### Address Conflicts

The auto-builder detects address conflicts and will report errors. Check the `.papilio/address_map.txt` file to see allocated addresses.

### "Markers not found"

If you've removed markers, the auto-builder will skip those sections. Re-add markers from this template if you want auto-generation restored.

### Build Errors After Adding Library

Check that:
1. Library has valid `papilio` metadata in `library.json`
2. HDL files compile correctly (check syntax)
3. Pin constraints are added for any external I/O

## Examples

### Example 1: Add RGB LED Control

1. Add library to `platformio.ini`:
   ```ini
   lib_deps = 
       https://github.com/Papilio-Labs/papilio_spi_slave.git
       https://github.com/Papilio-Labs/papilio_wishbone_rgb_led.git
   ```

2. Build: `pio run`

3. Add pin constraint in `fpga/constraints/pins.cst`:
   ```
   IO_LOC "rgb_led_data" 42;
   IO_PORT "rgb_led_data" IO_TYPE=LVCMOS33;
   ```

4. Use in ESP32 code (auto-generated object is available):
   ```cpp
   rgbLed.setColor(0, 255, 0, 0);  // Red
   ```

### Example 2: Add Control Registers

```ini
lib_deps = 
    https://github.com/Papilio-Labs/papilio_spi_slave.git
    https://github.com/Papilio-Labs/papilio_wishbone_register.git
```

Auto-generated objects let you read/write registers:
```cpp
// Read register 0
uint32_t value = wbRegister.read(0);

// Write register 1
wbRegister.write(1, 0x12345678);
```

## Learn More

- [Papilio Labs GitHub](https://github.com/Papilio-Labs)
- [PlatformIO Documentation](https://docs.platformio.org)
- [Wishbone Bus Specification](https://opencores.org/howto/wishbone)

## License

This template is provided as-is for use with Papilio projects.
