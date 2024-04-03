package debug_pkg;
  // 3.14.1. Debug Module Status (dmstatus, at 0x11)

  typedef struct packed {
    logic [31:25] zero;  // msb
    logic ndmresetpending;
    logic stickyunavail;
    logic impebreak;
    logic [21:20] zero_;
    logic allhavereset;
    logic anyhavereset;
    logic allresumeack;
    logic anyresumeack;
    logic allnonexistent;
    logic anynonexistent;
    logic allunavail;
    logic anyunavail;
    logic allrunning;
    logic anyrunning;
    logic anyhalted;
    logic authenticated;
    logic authbusy;
    logic hasresethaltreq;
    logic confstrptrvalid;
    logic [3:0] version;  // lsb
  } dmstatus_t;

  // 6.1.4. DTM Control and Status (dtmcs, at 0x10)
  typedef struct packed {
    logic [31:21] zero;  // msb
    logic errinfo;
    logic dtmhardreset;
    logic dmireset;
    logic zero_;
    logic [14:12] idle;
    logic [11:10] dmistat;
    logic [9:4] abits;
    logic [3:0] version;  // slb
  } dtmcs_t;

  typedef enum logic [1:0] {
    DMINoError = 2'h0,
    DMIReservedError = 2'h1,
    DMIOPFailed = 2'h2,
    DMIBusy = 2'h3
  } dmi_error_e;

endpackage
