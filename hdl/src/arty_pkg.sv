// arty_pkg
`timescale 1ns / 1ps

package arty_pkg;
  // Led
  localparam integer unsigned LedWidth = 4;
  localparam type LedT = logic [LedWidth-1:0];

  // Buttons
  localparam integer unsigned BtnWidth = 4;
  localparam type BtnT = logic [BtnWidth-1:0];

  // Switches
  localparam integer unsigned SwWidth = 2;
  localparam type SwT = logic [SwWidth-1:0];

endpackage
