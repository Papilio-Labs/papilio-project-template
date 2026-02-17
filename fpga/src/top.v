/**
 * Papilio RetroCade - Wishbone System Template
 * ESP32-S3 + Gowin FPGA
 *
 * Getting started:
 *   1. Set NUM_SLOTS to the number of peripheral slots you need (1-32)
 *   2. Add SLOT_CONNECT lines for each peripheral
 *   3. Wire any extra I/O (e.g., LED outputs) after the macro call
 *   4. Add board-specific ports to the module declaration
 *   5. Build and upload!
 *
 * Slot Address Map:
 *   Slot 0: 0x0000-0x00FF  (system reserved)
 *   Slot 1: 0x0100-0x01FF
 *   Slot 2: 0x0200-0x02FF
 *   ...
 *   Slot N: 0x(N*0x100)-0x(N*0x100+0xFF)
 */

module top (
    input  wire clk_27mhz,      // 27 MHz system clock

    // SPI Interface (ESP32 communication via Wishbone bridge)
    input  wire spi_sclk,
    input  wire spi_mosi,
    output wire spi_miso,
    input  wire spi_cs_n

    // Add your board I/O ports here, for example:
    // output wire [2:0] rgb_led
);

    // =========================================================================
    // Bus Infrastructure (reset, SPI bridge, interconnect — all inside)
    // =========================================================================
    wire clk = clk_27mhz;
    localparam NUM_SLOTS = 8;
    wire rst;                      // Driven by pwb_wb_system.rst_o
    `include "pwb_bus_wires.vh"

    pwb_wb_system #(.NUM_SLOTS(NUM_SLOTS)) bus (
        .clk(clk),
        .rst_o(rst),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),
        `PWB_SLOT_PORTS
    );

    // =========================================================================
    // Peripheral Slot Assignments
    // =========================================================================
    // Each SLOT_CONNECT line wires a peripheral to one slot.
    // To swap a peripheral: change the module name. To add more: increase NUM_SLOTS.

    `SLOT_CONNECT(0, wb_register_block #(.ADDR_WIDTH(4), .DATA_WIDTH(8)), slot0_sys);

    // Add your peripherals below:
    // `SLOT_CONNECT(1, wb_rgb_led,        slot1_rgb);
    // `SLOT_CONNECT(2, wb_register_block #(.DATA_WIDTH(16)), slot2_regs);

    // =========================================================================
    // User Logic
    // =========================================================================
    // Wire extra I/O for peripherals that have external pins:
    // assign rgb_led = <output from slot1_rgb>;

endmodule
