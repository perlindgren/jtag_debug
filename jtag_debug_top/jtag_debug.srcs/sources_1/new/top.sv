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

  logic [32:0] bs_shift;
  logic [31:0] bs_state = 'h12345678;  // initial value?

  assign TDO = bs_shift[0];

  always @(posedge DRCK) begin
    if (CAPTURE & ~SHIFT) begin
      bs_shift[31:0] <= bs_state[31:0];
    end

    if (SHIFT) begin
      bs_shift[32:0] <= {TDI, bs_shift[32:1]};  // shift data out
    end
  end

  always @(posedge TCK) begin
    if (UPDATE & SEL) begin
      bs_state[31:0] <= bs_shift[31:0];
      has_update <= has_update ^ 1;
    end

    if (RESET) begin
      bs_state   <= 'hffffffff;
      has_update <= 0;
      has_reset  <= has_reset ^ 1;
    end
  end

endmodule

// openFPGALoader -b  arty jtag_debug/jtag_debug.runs/impl_1/top.bit
