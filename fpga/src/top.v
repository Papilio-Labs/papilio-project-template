/**
 * Papilio RetroCade Top Module
 * 
 * This top module integrates:
 * - SPI to Wishbone bridge (for ESP32 communication)
 * - Wishbone address decoder (routes to peripherals)
 * - RGB LED controller (WS2812B)
 * 
 * The ESP32 can control the RGB LED through Wishbone registers
 * accessed via SPI.
 */

module top (
    // Clock input from ESP32 (27MHz)
    input wire clk,
    
    // Reset from ESP32
    input wire rst_n,
    
    // SPI interface from ESP32
    input wire spi_sclk,
    input wire spi_mosi,
    output wire spi_miso,
    input wire spi_cs_n,
    
    // RGB LED output (WS2812B)
    output wire led_out
);

    // Active high reset
    wire rst = !rst_n;
    
    // Wishbone master bus (from SPI bridge)
    wire [15:0] wb_adr;
    wire [7:0] wb_dat_m2s;
    wire [7:0] wb_dat_s2m;
    wire wb_we;
    wire wb_cyc;
    wire wb_stb;
    wire wb_ack;
    
    // =========================================================================
    // SPI to Wishbone Bridge
    // =========================================================================
    // Converts SPI transactions from ESP32 to Wishbone bus cycles
    simple_spi_wb_bridge spi_bridge (
        .clk(clk),
        .rst(rst),
        
        // SPI interface
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),
        
        // Wishbone master interface
        .wb_adr_o(wb_adr),
        .wb_dat_o(wb_dat_m2s),
        .wb_dat_i(wb_dat_s2m),
        .wb_we_o(wb_we),
        .wb_cyc_o(wb_cyc),
        .wb_stb_o(wb_stb),
        .wb_ack_i(wb_ack)
    );
    
    // =========================================================================
    // Wishbone Slave: RGB LED Controller (at address 0x00-0x03)
    // =========================================================================
    // Address map:
    //   0x00: LED Green value (8-bit)
    //   0x01: LED Red value (8-bit)
    //   0x02: LED Blue value (8-bit)
    //   0x03: Control/Status (bit 0 = busy)
    
    wb_simple_rgb_led rgb_led (
        .clk(clk),
        .rst(rst),
        
        // Wishbone slave interface
        .wb_adr_i(wb_adr[7:0]),
        .wb_dat_i(wb_dat_m2s),
        .wb_dat_o(wb_dat_s2m),
        .wb_we_i(wb_we),
        .wb_cyc_i(wb_cyc),
        .wb_stb_i(wb_stb),
        .wb_ack_o(wb_ack),
        
        // WS2812B LED output
        .led_out(led_out)
    );
    
endmodule
