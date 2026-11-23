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

5. Build and upload FPGA first, then the ESP32 application, using the
   instructions below. The example sets steady red, not a cycling pattern.

## Upload through the on-board loader

The board must already contain the resident Papilio ESP bootloader and its
factory/OTA partition layout. Normal uploads do not install or replace that
loader. No desktop Papilio Loader, MCP, Node.js, or globally installed
flashing tools are required.

### USB serial (default)

```bash
pio run -e fpga -t upload
pio run -e esp32 -t upload
```

Set `upload_port` in each environment if automatic detection is ambiguous,
or pass `--upload-port` on the CLI. Close serial monitors first.

FPGA uses `papilio_serial`; ESP uses PlatformIO's `custom` protocol with
`custom_papilio_transport = serial`. The ESP
[upload hook](./scripts/papilio_upload.py) runs the same managed uploader
as the FPGA platform, installed through `platform_packages`.

The uploader verifies board layout and factory identity, backs up OTA
selection records under `.pio/build/<environment>/papilio-backups/`, clears
only those records if factory entry is needed, then resets into the loader.
This intentionally clears the old OTA selection/rollback history, not the
factory firmware, partition table, loader WiFi settings, or app images.
The loader remembers its last application slot separately.

The FPGA loader installs its flash bridge itself and programs external FPGA
flash at `0x0`. The ESP application is uploaded to the loader-selected OTA
slot, never to ESP flash at `0x0`. The
[partition configuration](./partitions_papilio.csv) provides two 1.5 MB
application slots. `board_build.app_partition_name = ota_0` supplies the
build size limit; it does not force the runtime upload slot.

For consecutive FPGA/ESP uploads, optionally set
`custom_papilio_stay_in_loader = yes` in the FPGA environment to avoid
resuming the app between uploads. Standalone FPGA uploads resume by default.

### Network HTTP

Change these settings in [platformio.ini](./platformio.ini):

```ini
[env:esp32]
; Keep upload_protocol = custom and the existing package/hook declarations.
custom_papilio_transport = ota
custom_papilio_host = 192.168.1.100

[env:fpga]
upload_protocol = papilio_ota
custom_papilio_host = 192.168.1.100
custom_papilio_stay_in_loader = yes
```

Use your board's IP/hostname; port 3232 is the default. Run the same upload
commands as above. FPGA uses `/fpga-update`; ESP uses `/update` after showing
the selected target. Both use positive loader identity checks.

If the loader is already running, HTTP uploads need no USB. Compatible
FPGA-Companion apps can hand off through `/goto-loader`. The template app
has no such network service, so set `custom_papilio_enter_via_usb = yes`
for the first upload if it needs USB-assisted factory entry. Specify
`custom_papilio_usb_port` if necessary. Do not set that option for a
network-only board; manually enter its factory loader instead.

The uploader fails on protocol errors, missing acknowledgements, and HTTP
errors; it does not blindly retry a partially written image. If USB reset
wedges, follow its RESET/BOOT guidance. Windows hardware tests passed for
both transports; Linux/macOS hardware tests remain pending.

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
