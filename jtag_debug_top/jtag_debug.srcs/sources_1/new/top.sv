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
  import debug_pkg::*;
  localparam JDATA_WIDTH = 32;

  (* KEEP = "TRUE" *) reg [JDATA_WIDTH-1:0] jtag_data;

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
      .locked
  );

  // clock divider
  always @(posedge clk) begin
    r_count <= r_count + 1;
  end

  always_comb begin
    if (sw[1]) begin
      for (integer k = 0; k < LedWidth; k++) begin
        led_r[k] = 0;
        led_g[k] = 0;
        led_b[k] = 0;
      end
    end else begin
      led_r[0] <= r_count[22];
      led_r[1] = DT_TCK;
      led_r[2] = DT_TDI;
      led_r[3] = DT_TMS;
    end
  end

  (* KEEP = "TRUE" *)logic DT_CAPTURE;
  (* KEEP = "TRUE" *)logic DT_DRCK;
  (* KEEP = "TRUE" *)logic DT_RESET;
  (* KEEP = "TRUE" *)logic DT_RUNTEST;
  (* KEEP = "TRUE" *)logic DT_SEL;
  (* KEEP = "TRUE" *)logic DT_SHIFT;
  (* KEEP = "TRUE" *)logic DT_TCK;
  (* KEEP = "TRUE" *)logic DT_TDI;
  (* KEEP = "TRUE" *)logic DT_TMS;
  (* KEEP = "TRUE" *)logic DT_UPDATE;
  (* KEEP = "TRUE" *)logic DT_TDO;


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

  (* KEEP = "TRUE" *)logic DM_CAPTURE;
  (* KEEP = "TRUE" *)logic DM_DRCK;
  (* KEEP = "TRUE" *)logic DM_RESET;
  (* KEEP = "TRUE" *)logic DM_RUNTEST;
  (* KEEP = "TRUE" *)logic DM_SEL;
  (* KEEP = "TRUE" *)logic DM_SHIFT;
  (* KEEP = "TRUE" *)logic DM_TCK;
  (* KEEP = "TRUE" *)logic DM_TDI;
  (* KEEP = "TRUE" *)logic DM_TMS;
  (* KEEP = "TRUE" *)logic DM_UPDATE;
  (* KEEP = "TRUE" *)logic DM_TDO;

  assign DM_TDO = 0;

  // DMI
  BSCANE2 #(
      .JTAG_CHAIN(4)  // Value for USER command.
  ) bse2_dmi_inst (
      .CAPTURE(DM_CAPTURE),  // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DM_DRCK),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
      // SHIFT are asserted.

      .RESET(DM_RESET),  // 1-bit output: Reset output for TAP controller.
      .RUNTEST(DM_RUNTEST), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(DM_SHIFTSEL),  // 1-bit output: USER instruction active output.
      .SHIFT(DM_SHIFT),  // 1-bit output: SHIFT output from TAP controller.
      .TCK(DM_TCK),  // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(DM_TDI),  // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(DM_TMS),  // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(DM_UPDATE),  // 1-bit output: UPDATE output from TAP controller
      .TDO(DM_TDO)  // 1-bit input: Test Data Output (TDO) input for USER function.
  );

  dmi_error_e error_d, error_q;
  dtmcs_t dtmcs_d, dtmcs_q;


  logic dmi_clear;  // Functional (warm) reset of the entire DMI

  assign dmi_clear = DT_RESET || (DT_SEL && DT_UPDATE && dtmcs_q.dmihardreset);

  // Debug Module Control and Status
  always_comb begin
    dtmcs_d = dtmcs_q;
    if (DT_CAPTURE) begin
      if (DT_SEL) begin
        dtmcs_d = '{
            zero         : '0,
            errinfo      : '0,
            dtmhardreset : 1'b0,
            dmireset     : 1'b0,
            zero_        : '0,
            idle         : 3'd1,  // 1: Enter Run-Test/Idle and leave it immediately
            dmistat      : error_q,  // 0: No error, 2: Op failed, 3: too fast
            abits        : 6'd7,  // The size of address in dmi
            version      : 4'd1  // Version described in spec version 0.13 (and later?)
        };
      end
    end

    if (DT_SHIFT) begin
      if (DT_SEL) dtmcs_d = {DT_TDI, 31'(dtmcs_q >> 1)};
    end
  end

  always_ff @(posedge DT_TCK) begin
    dtmcs_q <= dtmcs_d;
  end

  // Debug Module Interface

  logic      dmi_select;
  logic      dmi_tdo;

  dmi_req_t  dmi_req;
  logic      dmi_req_ready;
  logic      dmi_req_valid;

  dmi_resp_t dmi_resp;
  logic      dmi_resp_valid;
  logic      dmi_resp_ready;

  state_e state_d, state_q;

  dmi_t dr_d, dr_q;
  logic [6:0] address_d, address_q;
  logic [31:0] data_d, data_q;

  dmi_t dmi;

  assign dmi          = (dr_q);
  assign dmi_req.addr = address_q;
  assign dmi_req.data = data_q;







  // logic [$bits(dmi_t)-1:0] dr_d, dr_q;
  // logic [6:0] address_d, address_q;
  // logic [31:0] data_d, data_q;

  // dmi_t  dmi;
  // assign dmi          = dmi_t'(dr_q);
  // assign dmi_req.addr = address_q;
  // assign dmi_req.data = data_q;
  // assign dmi_req.op   = (state_q == Write) ? dm::DTM_WRITE : dm::DTM_READ;
  // // We will always be ready to accept the data we requested.
  // assign dmi_resp_ready = 1'b1;

  // logic error_dmi_busy;
  // logic error_dmi_op_failed;

  // always_comb begin : p_fsm
  //   error_dmi_busy = 1'b0;
  //   error_dmi_op_failed = 1'b0;
  //   // default assignments
  //   state_d   = state_q;
  //   address_d = address_q;
  //   data_d    = data_q;
  //   error_d   = error_q;

  //   dmi_req_valid = 1'b0;

  //   if (dmi_clear) begin
  //     state_d   = Idle;
  //     data_d    = '0;
  //     error_d   = DMINoError;
  //     address_d = '0;
  //   end else begin
  //     unique case (state_q)
  //       Idle: begin
  //         // make sure that no error is sticky
  //         if (dmi_select && update && (error_q == DMINoError)) begin
  //           // save address and value
  //           address_d = dmi.address;
  //           data_d = dmi.data;
  //           if (dm::dtm_op_e'(dmi.op) == dm::DTM_READ) begin
  //             state_d = Read;
  //           end else if (dm::dtm_op_e'(dmi.op) == dm::DTM_WRITE) begin
  //             state_d = Write;
  //           end
  //           // else this is a nop and we can stay here
  //         end
  //       end

  //       Read: begin
  //         dmi_req_valid = 1'b1;
  //         if (dmi_req_ready) begin
  //           state_d = WaitReadValid;
  //         end
  //       end

  //       WaitReadValid: begin
  //         // load data into register and shift out
  //         if (dmi_resp_valid) begin
  //           unique case (dmi_resp.resp)
  //             dm::DTM_SUCCESS: begin
  //               data_d = dmi_resp.data;
  //             end
  //             dm::DTM_ERR: begin
  //               data_d = 32'hDEAD_BEEF;
  //               error_dmi_op_failed = 1'b1;
  //             end
  //             dm::DTM_BUSY: begin
  //               data_d = 32'hB051_B051;
  //               error_dmi_busy = 1'b1;
  //             end
  //             default: begin
  //               data_d = 32'hBAAD_C0DE;
  //             end
  //           endcase
  //           state_d = Idle;
  //         end
  //       end

  //       Write: begin
  //         dmi_req_valid = 1'b1;
  //         // request sent, wait for response before going back to idle
  //         if (dmi_req_ready) begin
  //           state_d = WaitWriteValid;
  //         end
  //       end

  //       WaitWriteValid: begin
  //         // got a valid answer go back to idle
  //         if (dmi_resp_valid) begin
  //           unique case (dmi_resp.resp)
  //             dm::DTM_ERR: error_dmi_op_failed = 1'b1;
  //             dm::DTM_BUSY: error_dmi_busy = 1'b1;
  //             default: ;
  //           endcase
  //           state_d = Idle;
  //         end
  //       end

  //       default: begin
  //         // just wait for idle here
  //         if (dmi_resp_valid) begin
  //           state_d = Idle;
  //         end
  //       end
  //     endcase

  //     // update means we got another request but we didn't finish
  //     // the one in progress, this state is sticky
  //     if (update && state_q != Idle) begin
  //       error_dmi_busy = 1'b1;
  //     end

  //     // if capture goes high while we are in the read state
  //     // or in the corresponding wait state we are not giving back a valid word
  //     // -> throw an error
  //     if (capture && state_q inside {Read, WaitReadValid}) begin
  //       error_dmi_busy = 1'b1;
  //     end

  //     if (error_dmi_busy && error_q == DMINoError) begin
  //       error_d = DMIBusy;
  //     end

  //     if (error_dmi_op_failed && error_q == DMINoError) begin
  //       error_d = DMIOPFailed;
  //     end

  //     // clear sticky error flag
  //     if (update && dtmcs_q.dmireset && dtmcs_select) begin
  //       error_d = DMINoError;
  //     end
  //   end
  // end

  // // shift register
  // assign dmi_tdo = dr_q[0];

  // always_comb begin : p_shift
  //   dr_d    = dr_q;
  //   if (dmi_clear) begin
  //     dr_d = '0;
  //   end else begin
  //     if (capture) begin
  //       if (dmi_select) begin
  //         if (error_q == DMINoError && !error_dmi_busy) begin
  //           dr_d = {address_q, data_q, DMINoError};
  //           // DMI was busy, report an error
  //         end else if (error_q == DMIBusy || error_dmi_busy) begin
  //           dr_d = {address_q, data_q, DMIBusy};
  //         end
  //       end
  //     end

  //     if (shift) begin
  //       if (dmi_select) begin
  //         dr_d = {tdi, dr_q[$bits(dr_q)-1:1]};
  //       end
  //     end
  //   end
  // end

  // always_ff @(posedge tck or negedge trst_ni) begin
  //   if (!trst_ni) begin
  //     dr_q      <= '0;
  //     state_q   <= Idle;
  //     address_q <= '0;
  //     data_q    <= '0;
  //     error_q   <= DMINoError;
  //   end else begin
  //     dr_q      <= dr_d;
  //     state_q   <= state_d;
  //     address_q <= address_d;
  //     data_q    <= data_d;
  //     error_q   <= error_d;
  //   end
  // end

endmodule
