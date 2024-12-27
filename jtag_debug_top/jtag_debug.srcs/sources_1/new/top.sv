// fpga_arty
`timescale 1ns / 1ps

import arty_pkg::*;

module top (
    input sysclk,

    output LedT led,
    output LedT led_r,
    output LedT led_g,
    output LedT led_b,
    input  SwT  sw,

    output logic rx,  // host rx input 
    input  logic tx,  // host tx output

    input BtnT btn
);
  logic clk;
  logic [31:0] r_count;
  logic locked;

  clk_wiz_0 clk_gen (
      // Clock in ports
      .clk_in1(sysclk),
      // Clock out ports
      .clk_out1(clk),
      // Status and control signals
      .reset(sw[0]),
      .locked(locked)
  );

  // clock divider
  always @(posedge clk) begin
    r_count <= r_count + 1;
  end

  // logic old_sel;
  logic has_update = 0;
  logic has_reset = 0;

  always_comb begin
    rx = 0;
    led[0] = SEL;
    led[1] = UPDATE;
    led[2] = has_reset;
    led[3] = has_update;  // UPDATE;

    for (integer k = 0; k < LedWidth; k++) begin
      led_r[k] = 0;
      led_g[k] = 0;
      led_b[k] = 0;
    end

    if (sw[1]) begin
      led_b[0] = r_count[26];
      led_b[1] = r_count[25];
      led_b[2] = r_count[24];
      led_b[3] = r_count[23];
    end
  end

  // BSCANE2: Boundary-Scan User Instruction
  //          Artix-7
  // Xilinx HDL Language Template, version 2024.2

  BSCANE2 #(
      .JTAG_CHAIN(3)  // Value for USER3 command, 0x22
      // .JTAG_CHAIN(1)  // Value for USER3 command, 0x02
  ) BSCANE2_inst (
      .CAPTURE(CAPTURE),  // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DRCK),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                         // SHIFT are asserted.

      .RESET(RESET),  // 1-bit output: Reset output for TAP controller.
      .RUNTEST(RUNTEST), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(SEL),  // 1-bit output: USER instruction active output.
      .SHIFT(SHIFT),  // 1-bit output: SHIFT output from TAP controller.
      .TCK(TCK),  // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(TDI),  // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(TMS),  // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(UPDATE),  // 1-bit output: UPDATE output from TAP controller
      .TDO(TDO)  // 1-bit input: Test Data Output (TDO) input for USER function.
  );

  // End of BSCANE2_inst instantiation

  logic [7:0] bs_shift;
  logic [2:0] bs_count; // wrapping 3 bit counter
  logic [7:0] bs_tmp;
  
  MemType       bs_mem = { 8'hde, 8'had, 8'hbe, 8'hef, 8'h8b, 8'had, 8'hf0, 8'h0f };
  MemAddr       bs_addr = 0;
  MemAddr       bs_next;
  
  assign TDO = bs_shift[0];

  always @(posedge DRCK) begin
    if (CAPTURE & ~SHIFT) begin
      bs_count <= 0;
      bs_shift <= bs_mem[bs_addr];
    end

    if (SHIFT) begin
      bs_tmp = {TDI, bs_shift[7:1]};
      bs_shift <= bs_tmp;  // shift data out
      bs_count <= bs_count+1; // wrapping 3 bit counter
      // last bit in byte
      if (bs_count == 7) begin
         bs_next = bs_addr+1;
         bs_mem[bs_addr] <= bs_tmp; // update current address in memory
         bs_shift <= bs_mem[bs_next]; // load next address to shift register
         bs_addr <= bs_next;  // update address
      end
    end
  end

  always @(posedge TCK) begin
    if (UPDATE & SEL) begin
//      bs_address <= bs_shift[2:0];
//      bs_state[bs_shift[2:0]] <= bs_shift[39:8];
      has_update <= has_update ^ 1;
    end

    if (RESET) begin
      // bs_addr <= 0;
      has_update <= 0;
      has_reset  <= has_reset ^ 1;
      /*// dead beef
      bs_mem[0] <= 'hde;
      bs_mem[1] <= 'had;
      bs_mem[2] <= 'hbe;
      bs_mem[3] <= 'hef;
      // 8bad food
      bs_mem[4] <= 'h8b;
      bs_mem[5] <= 'had;
      bs_mem[6] <= 'hf0;
      bs_mem[7] <= 'h0d;*/  
      
    end
  end

endmodule

// openFPGALoader -b  arty jtag_debug/jtag_debug.runs/impl_1/top.bit
