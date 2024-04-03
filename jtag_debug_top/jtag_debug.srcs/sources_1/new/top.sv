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
  localparam JDATA_WIDTH = 32;

  (* KEEP = "TRUE" *) reg [JDATA_WIDTH-1:0] jtag_data;

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

  logic DT_CAPTURE;
  logic DT_DRCK;
  logic DT_RESET;
  logic DT_RUNTEST;
  logic DT_SEL;
  logic DT_SHIFT;
  logic DT_TCK;
  logic DT_TDI;
  logic DT_TMS;
  logic DT_UPDATE;
  logic DT_TDO;


  assign led_r[1] = DT_TCK;
  assign led_r[2] = DT_TDI;
  assign led_r[3] = DT_TMS;

  assign DT_TDO = jtag_data[0];
  assign dt_data_valid = DT_SHIFT & DT_SEL;

  initial begin
    jtag_data[JDATA_WIDTH-1:0] = 'h10e31913;
  end

  always @(posedge DT_TCK) begin
    if (dt_data_valid) begin
      jtag_data[JDATA_WIDTH-1:0] <= {DT_TDI, jtag_data[JDATA_WIDTH-1:1]};
      // jtag_data[JDATA_WIDTH-1:0] <= {jtag_data[0], jtag_data[JDATA_WIDTH-1:1]};
    end
  end

  // DTMCS
  BSCANE2 #(
      .JTAG_CHAIN(3)  // USER3 0x22
  ) bse2_dtmcs_inst (
      .CAPTURE(DT_CAPTURE),  // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DT_DRCK),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
      // SHIFT are asserted.

      .RESET(DT_RESET),  // 1-bit output: Reset output for TAP controller.
      .RUNTEST(DT_RUNTEST), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(DT_SEL),  // 1-bit output: USER instruction active output.
      .SHIFT(DT_SHIFT),  // 1-bit output: SHIFT output from TAP controller.
      .TCK(DT_TCK),  // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(DT_TDI),  // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(DT_TMS),  // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(DT_UPDATE),  // 1-bit output: UPDATE output from TAP controller
      .TDO(DT_TDO)  // 1-bit input: Test Data Output (TDO) input for USER function.
  );


  // logic DM_CAPTURE;
  // logic DM_DRCK;
  // logic DM_RESET;
  // logic DM_RUNTEST;
  // logic DM_SEL;
  // logic DM_SHIFT;
  // logic DM_TCK;
  // logic DM_TDI;
  // logic DM_TMS;
  // logic DM_UPDATE;
  // logic DM_TDO;

  // // DMI
  // BSCANE2 #(
  //     .JTAG_CHAIN(4)  // Value for USER command.
  // ) bse2_dmi_inst (
  //     .CAPTURE(CAPTURE),  // 1-bit output: CAPTURE output from TAP controller.
  //     .DRCK(DRCK),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
  //                        // SHIFT are asserted.

  //     .RESET(RESET),  // 1-bit output: Reset output for TAP controller.
  //     .RUNTEST(RUNTEST), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
  //     .SEL(SEL),  // 1-bit output: USER instruction active output.
  //     .SHIFT(SHIFT),  // 1-bit output: SHIFT output from TAP controller.
  //     .TCK(TCK),  // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
  //     .TDI(TDI),  // 1-bit output: Test Data Input (TDI) output from TAP controller.
  //     .TMS(TMS),  // 1-bit output: Test Mode Select output. Fabric connection to TAP.
  //     .UPDATE(UPDATE),  // 1-bit output: UPDATE output from TAP controller
  //     .TDO(TDO)  // 1-bit input: Test Data Output (TDO) input for USER function.
  // );

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
