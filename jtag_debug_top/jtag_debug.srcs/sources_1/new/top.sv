// fpga_arty
`timescale 1ns / 1ps

import arty_pkg::*;

module top (
    input sysclk,

    output LedT led,
    output LedT led_b,
    input  SwT  sw
);
  logic clk;
  logic [31:0] r_count;

  clk_wiz_0 clk_gen (
      // Clock in ports
      .clk_in1(sysclk),
      // Clock out ports
      .clk_out1(clk),
      // Status and control signals
      .reset(sw[0]),
      .locked()
  );

  // clock divider
  always @(posedge clk) begin
    r_count <= r_count + 1;
  end

  // logic old_sel;
  logic has_update = 0;
  logic has_reset = 0;

  always_comb begin
    led[0] = SEL;
    led[1] = UPDATE;
    led[2] = has_reset;
    led[3] = has_update;  // UPDATE;

    if (sw[1]) begin
      led_b[0] = r_count[26];
      led_b[1] = r_count[25];
      led_b[2] = r_count[24];
      led_b[3] = r_count[23];
    end else begin
      led_b = 0;
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
      .RUNTEST(), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(SEL),  // 1-bit output: USER instruction active output.
      .SHIFT(SHIFT),  // 1-bit output: SHIFT output from TAP controller.
      .TCK(TCK),  // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(TDI),  // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(),  // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(UPDATE),  // 1-bit output: UPDATE output from TAP controller
      .TDO(TDO)  // 1-bit input: Test Data Output (TDO) input for USER function.
  );

  // End of BSCANE2_inst instantiation

  logic [7:0] bs_shift_r;
  logic [2:0] bs_bit_count_r; // wrapping 3 bit counter
  logic [7:0] bs_tmp;
  
  MemType       bs_mem = { 8'hde, 8'had, 8'hbe, 8'hef, 8'h8b, 8'had, 8'hf0, 8'h0f };
  MemAddr       bs_addr_r = 0;
  MemAddr       bs_addr_next;
  
  assign TDO = bs_shift_r[0];
  assign bs_tmp = {TDI, bs_shift_r[7:1]};
  assign bs_addr_next = bs_addr_r+1;
 
  always @(posedge DRCK) begin
    if (CAPTURE & ~SHIFT) begin
      bs_bit_count_r <= 0;
      bs_shift_r <= bs_mem[bs_addr_r];
    end

    if (SHIFT) begin
      bs_shift_r <= bs_tmp;  // shift data out
      bs_bit_count_r <= bs_bit_count_r+1; // wrapping 3 bit counter
      // last bit in byte
      if (bs_bit_count_r == 7) begin
         bs_mem[bs_addr_r] <= bs_tmp; // update current address in memory
         bs_shift_r <= bs_mem[bs_addr_next]; // load next address to shift register
         bs_addr_r <= bs_addr_next;  // update address
      end
    end
  end

  // just for debugging purpose
  always @(posedge TCK) begin
    if (UPDATE & SEL) begin
      has_update <= has_update ^ 1;
    end

    if (RESET) begin
      has_update <= 0;
      has_reset  <= has_reset ^ 1;
    end
  end

endmodule

// openFPGALoader -b  arty jtag_debug/jtag_debug.runs/impl_1/top.bit
