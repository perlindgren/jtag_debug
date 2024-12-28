# JTAG DEBUG

This crate demonstrates the use of the AMD/Xilinx BSCANE2 IP for implementing a custom TAP.

The name JTAG DEBUG is currently misleading, but the end goal is to implement raw debugging functionality of the Hippomenes Real-Time RISC-V processor.

The first step is to implement a program loader for Hippo. This experiment shows the feasibility to do that, by emulating a memory (just 8 bytes, but it is sufficient as a proof of concept).

## Resources

- [ug470](https://docs.amd.com/v/u/en-US/ug470_7Series_Config) 7 Series FGPAs Configuration
- [xjtag](https://www.xjtag.com/about-jtag/jtag-a-technical-overview/) Technical Guide to JTAG

## BSCANE2

The BSCANE2 hooks into the TAP controller on the FGPA SoC, providing 4 user defined IRs.

| IR    | IR-bits | IR Hex |
| ----- | ------- | ------ |
| user1 | 00_0010 |   0x02 |
| user2 | 00_0011 |   0x03 |
| user3 | 10_0010 |   0x22 |
| user4 | 10_0011 |   0x23 |

The example targets the Digilent ARTY xc7a35ticsg324-1L SoC, but should work with minor modifications for any Artix 7. Support for Zynq should be possible as well, but is not yet tested.

## Demo

The demo application implements 8 byte sized data registers, accessible through the USER3 (0x22) IR.

The BCANE2 is instantiated as follows:

```SV
  BSCANE2 #(
      .JTAG_CHAIN(3)      // Value for USER3 command, 0x22
  ) BSCANE2_inst (
      .CAPTURE(CAPTURE),  // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DRCK),        // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or SHIFT are asserted.
      .RESET(RESET),      // 1-bit output: Reset output for TAP controller.
      .RUNTEST(),         // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(SEL),          // 1-bit output: USER instruction active output.
      .SHIFT(SHIFT),      // 1-bit output: SHIFT output from TAP controller.
      .TCK(TCK),          // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(TDI),          // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(),             // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(UPDATE),    // 1-bit output: UPDATE output from TAP controller
      .TDO(TDO)           // 1-bit input: Test Data Output (TDO) input for USER function.
  );
```

It is used as follows:

```SV
  // clocked registers
  logic [7:0] bs_shift_r;
  logic [2:0] bs_bit_count_r; 
  MemAddr     bs_addr_r;
  MemType     bs_mem_r;
 
  // temporaries
  logic [7:0] bs_tmp; 
  MemAddr     bs_addr_next;
  
  assign TDO = bs_shift_r[0];
  assign bs_tmp = {TDI, bs_shift_r[7:1]};
  assign bs_addr_next = bs_addr_r+1;
 
  always @(posedge DRCK) begin
    if (CAPTURE) begin
      bs_bit_count_r <= 0;
      bs_addr_r <= 0;
      bs_shift_r <= bs_mem_r[0];
    end

    if (SHIFT) begin
      bs_shift_r <= bs_tmp;                    // shift data out
      bs_bit_count_r <= bs_bit_count_r+1;      // wrapping 3 bit counter
    
      if (bs_bit_count_r == 7) begin           // at last bit
         bs_mem_r[bs_addr_r] <= bs_tmp;        // update current address in memory
         bs_shift_r <= bs_mem_r[bs_addr_next]; // load next address to shift register
         bs_addr_r <= bs_addr_next;            // update address
      end
    end
  end
```

The demo works as follows:
- Our state machine is clocked by `DRCK`, that is only when the custom TAP is selected.
- On `CAPTURE` we initialsize the adress and bit counter (`bs_addr_r <= 0`, and `b_bit_count_r <= 0`), and loads the shift register with data of the first address (`bs_shift_r <= bs_mem_r[0]`).
- On `SHIFT` 
  - recieve and send data LSB first.
  - update the bit shift counter.
  - if we have shifted the last bit (7), we incement the address, and load the shift register with the next data byte in memory.

So the idea is that a `user` would read/write the memory byte by byte. In this case up to 8 bytes, always starting from address 0.

The rest of the HDL code is just for setting up clock and some LEDs for monitoring the different states of the TAP controller.





