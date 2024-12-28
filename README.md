# JTAG BSCANE2

This crate demonstrates the use of the AMD/Xilinx BSCANE2 IP for implementing a custom TAP.

The BSCANE2 hooks into the TAP controller on the FGPA SoC, providing 4 user defined IRs.

| IR    | IR-bits | IR Hex |
| user1 | 00_0010 | 0x02   |
| user2 | 00_0011 | 0x03   |
| user3 | 10_0010 | 0x22   |
| user4 | 10_0011 | 0x23   |

The example targets the Digilent ARTY xc7a35ticsg324-1L SoC, but should work with minor modifications for any Artix 7. Support for Zynq should be possible as well, but is not yet tested.



