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

    output logic rx,  // seen from host side 
    input  logic tx,

    input BtnT btn
);

  logic clk;

  logic [31:0] r_count;
  logic locked;

  always_comb begin
    for (integer k = 0; k < LedWidth; k++) begin
      // if (k != 0 || k != 1) led_r[k] = 0;  // used for clock
      // if (k != 0) led_r[k] = 0;  // used for clock
      led_g[k] = 0;
      led_b[k] = 0;
    end
  end

  logic CAPTURE;
  logic DRCK;
  logic RESET;
  logic RUNTEST;
  logic SEL;
  logic SHIFT;
  logic TCK;
  logic TDI;
  logic TMS;
  logic UPDATE;
  logic TDO;

  assign TDO = 0;

  assign led_r[1] = TCK;
  assign led_r[2] = TDI;
  assign led_r[3] = TMS;

  BSCANE2 #(
      .JTAG_CHAIN(4)  // Value for USER command.
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

  clk_wiz_0 clk_gen (
      // Clock in ports
      .clk_in1(sysclk),
      // Clock out ports
      .clk_out1(clk),
      // Status and control signals
      .reset(sw[0]),
      .locked
  );

  // clock devider
  always @(posedge clk) begin
    r_count  <= r_count + 1;
    led_r[0] <= r_count[22];
  end

endmodule
