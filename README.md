# Papilio RetroCade Wishbone Project Template

Build ESP32-S3 Arduino firmware and Gowin GW2A-18 gateware in one PlatformIO
project. The ESP32 talks to FPGA peripherals over the SPI-to-Wishbone bridge.

**PlatformIO includes the libraries; you write the code that uses them.** Add
dependencies once under `[env:esp32]` in [platformio.ini](./platformio.ini).
The FPGA environment reuses that list and adds library HDL to the Gowin project
and header search paths. It does not add peripheral instances, initialize
drivers, assign addresses, add library pin constraints, or rewrite your source.

## Build the starter project

Install [PlatformIO](https://docs.platformio.org/en/latest/core/installation/)
and the [Gowin EDA toolchain](https://github.com/Papilio-Labs/platform-gowin#install-gowin-eda-toolchain).
Then run `pio run` for both targets, or `pio run -e fpga` and
`pio run -e esp32` separately. The FPGA build does not require a prior ESP32 build.

| File | What you edit |
| --- | --- |
| [platformio.ini](./platformio.ini) | Dependencies and board configuration |
| [fpga/src/top.v](./fpga/src/top.v) | Peripheral instances and wiring |
| [fpga/constraints/papilio_retrocade_base.cst](./fpga/constraints/papilio_retrocade_base.cst) | Physical pin assignments |
| [src/main.cpp](./src/main.cpp) | Driver instances and application logic |

## Example: Add the onboard RGB LED

1. Uncomment `papilio_wishbone_rgb_led` in `lib_deps`. Leave the core
   dependencies in place.
2. In [top.v](./fpga/src/top.v), enable the `output wire rgb_led` port
   (including its leading comma) and the slot 1 connection:

   ```verilog
   `SLOT_CONNECT(1, wb_simple_rgb_led, slot1_rgb),
       .led_out(rgb_led)
   );
   ```

3. Add the RetroCade pin assignment to the project's constraint file:

   ```text
   IO_LOC "rgb_led" P9;
   IO_PORT "rgb_led" IO_TYPE=LVCMOS33 PULL_MODE=NONE DRIVE=8;
   ```

4. In [main.cpp](./src/main.cpp), add the driver and pass it the same slot
   number used in `SLOT_CONNECT`:

   ```cpp
   #include <PapilioRGBLed.h>

   auto rgbLed = PapilioRGBLed::fromSlot(1);
   ```

   In `setup()`, after `wishboneInit(...)`, add:

   ```cpp
   if (rgbLed.begin()) {
       rgbLed.setColor(PapilioRGBLed::COLOR_RED);
   }
   ```

5. Build both targets. On a RetroCade with the resident Papilio ESP Bootloader,
   use [Papilio Loader](https://papilioworks.com/loader/) to load the FPGA
   bitstream (`.pio/build/fpga/fpga_bitstream.bin`) and then the ESP32 app
   (`.pio/build/esp32/firmware.bin`) without replacing the factory loader or
   partition table.

## Slot addresses

Each standard slot occupies 256 bytes, so its base address is `slot * 0x100`.
Slot 0 (`0x0000`) is reserved for system control; the starter design uses a
placeholder register block there, not a device directory. Slot 1 starts at
`0x0100`, slot 2 at `0x0200`, and so on. Give each peripheral a distinct slot
and pass that same slot number to drivers that provide `fromSlot()`. For a
driver that only takes a byte address, use the corresponding base address.

The optional extended tier spans `0x2000` to `0xFFFF`. See
[top.v](./fpga/src/top.v) for single- and multi-peripheral wiring examples.

If libraries provide duplicate HDL modules, exclude the unwanted file with
`board_build.fpga_exclude_sources`.
