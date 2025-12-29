// Wishbone RGB LED Controller using WS2812B protocol
// Provides a simple register interface for controlling an RGB LED

module wb_simple_rgb_led (
    input wire clk,
    input wire rst,
    
    // 8-bit Wishbone Slave Interface (8-bit address, 8-bit data)
    input wire [7:0] wb_adr_i,
    input wire [7:0] wb_dat_i,
    output reg [7:0] wb_dat_o,
    input wire wb_we_i,
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    
    // WS2812B LED output
    output wire led_out
);

    // Color registers
    reg [7:0] led_green;
    reg [7:0] led_red;
    reg [7:0] led_blue;
    reg update_trigger;
    
    // Wishbone interface
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led_green <= 8'h00;
            led_red <= 8'h00;
            led_blue <= 8'h00;
            update_trigger <= 0;
            wb_ack_o <= 0;
            wb_dat_o <= 8'h00;
        end else begin
            wb_ack_o <= 0;
            update_trigger <= 0;
            
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1;
                
                if (wb_we_i) begin
                    case (wb_adr_i[1:0])
                        2'h0: begin
                            led_green <= wb_dat_i;
                            update_trigger <= 1;  // Auto-update on any color write
                        end
                        2'h1: begin
                            led_red <= wb_dat_i;
                            update_trigger <= 1;
                        end
                        2'h2: begin
                            led_blue <= wb_dat_i;
                            update_trigger <= 1;
                        end
                    endcase
                end else begin
                    // Read
                    case (wb_adr_i[1:0])
                        2'h0: wb_dat_o <= led_green;
                        2'h1: wb_dat_o <= led_red;
                        2'h2: wb_dat_o <= led_blue;
                        2'h3: wb_dat_o <= {7'b0, busy};
                    endcase
                end
            end
        end
    end
    
    // Trigger LED update after write
    reg start;
    reg [15:0] start_delay;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start <= 0;
            start_delay <= 0;
        end else begin
            start <= 0;
            if (update_trigger) begin
                start_delay <= 1000;  // ~37µs delay
            end else if (start_delay > 0) begin
                start_delay <= start_delay - 1;
                if (start_delay == 1) begin
                    start <= 1;
                end
            end
        end
    end
    
    // WS2812B controller
    wire busy;
    ws2812b_controller #(
        .CLOCK_FREQ(27000000)
    ) ws2812b_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .busy(busy),
        .led_data({led_green, led_red, led_blue}),
        .led_out(led_out)
    );

endmodule

// WS2812B LED Controller
module ws2812b_controller #(
    parameter CLOCK_FREQ = 27000000
)(
    input wire clk,
    input wire rst,
    input wire start,
    output reg busy,
    input wire [23:0] led_data,
    output reg led_out
);

    // WS2812B timing parameters (at 27MHz)
    // T0H: 0.4us = 11 cycles
    // T0L: 0.85us = 23 cycles
    // T1H: 0.8us = 22 cycles
    // T1L: 0.45us = 12 cycles
    // Total: 1.25us = 34 cycles per bit
    // Reset: >50us = 1350 cycles
    
    localparam CYCLES_PER_BIT = CLOCK_FREQ / 800000;
    localparam CYCLES_T0H = (CLOCK_FREQ * 4) / 10000000;  
    localparam CYCLES_T1H = (CLOCK_FREQ * 8) / 10000000;  
    
    reg [15:0] cycle_counter;
    reg [4:0] bit_index;
    reg current_bit;
    
    localparam IDLE = 0;
    localparam SEND_BIT = 1;
    localparam RESET = 2;
    
    reg [1:0] state;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            busy <= 1'b0;
            led_out <= 1'b0;
            cycle_counter <= 0;
            bit_index <= 0;
            current_bit <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    led_out <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        state <= SEND_BIT;
                        cycle_counter <= 0;
                        bit_index <= 23;  
                        current_bit <= led_data[23];
                    end
                end
                
                SEND_BIT: begin
                    if (cycle_counter == 0) begin
                        led_out <= 1'b1;
                        current_bit <= led_data[bit_index];
                    end else if (cycle_counter == CYCLES_T0H && !current_bit) begin
                        led_out <= 1'b0;
                    end else if (cycle_counter == CYCLES_T1H && current_bit) begin
                        led_out <= 1'b0;
                    end
                    
                    if (cycle_counter >= CYCLES_PER_BIT - 1) begin
                        cycle_counter <= 0;
                        
                        if (bit_index == 0) begin
                            state <= RESET;
                        end else begin
                            bit_index <= bit_index - 1;
                        end
                    end else begin
                        cycle_counter <= cycle_counter + 1;
                    end
                end
                
                RESET: begin
                    led_out <= 1'b0;
                    if (cycle_counter >= (CLOCK_FREQ / 10000)) begin
                        cycle_counter <= 0;
                        state <= IDLE;
                        busy <= 1'b0;
                    end else begin
                        cycle_counter <= cycle_counter + 1;
                    end
                end
            endcase
        end
    end

endmodule
