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

  // 3.14.2. Debug Module Control (dmcontrol, at 0x10)
  typedef struct packed {
    logic haltreq;  // msb
    logic resumereq;
    logic hartreset;
    logic ackhavereset;
    logic ackunavail;
    logic hasel;
    logic [25:16] hartsello;
    logic [15:6] hartselhi;
    logic setkeepalive;
    logic clrkeepalive;
    logic setresethaltreq;
    logic clrresethaltreq;
    logic ndmreset;
    logic dmactive;  // lsb
  } dmcontrol_t;

  // 6.1.4. DTM Control and Status (dtmcs, at 0x10)
  typedef struct packed {
    logic [31:21] zero;  // msb
    logic [20:18] errinfo;
    logic dtmhardreset;
    logic dmireset;
    logic zero_;
    logic [14:12] idle;
    logic [11:10] dmistat;
    logic [9:4] abits;
    logic [3:0] version;  // lsb
  } dtmcs_t;

  // A.3. Debug Module Interface Signals
  typedef struct packed {
    logic        REQ_VALID;    // msb     // Valid request pending
    logic [5:0]  REQ_ADDRESS;  // Requested address in DMI
    logic [31:0] REQ_DATA;     // Requested data at DMI address
    logic [1:0]  REQ_OP;       // Same as dmi_error_e
    logic        RSP_READY;    // lsb     // Able to process a respond
  } dtm_interface_signals_t;

  typedef struct packed {
    logic        REQ_READY;  // msb       // Able to process a request
    logic        RSP_VALID;  // Valid respond pending
    logic [31:0] RSP_DATA;   // Response data
    logic [1:0]  RSP_OP;     // lsb       // Same as dmi_error_e
  } dm_interface_signals_t;

  typedef enum logic [1:0] {
    DMINop = 'b00,
    DMIRead = 'b01,
    DMIWrite = 'b10,
    DMIReserved = 'b11
  } dmi_op_e;

  typedef enum logic [1:0] {
    DMINoError = 2'h0,
    DMIReservedError = 2'h1,
    DMIOPFailed = 2'h2,
    DMIBusy = 2'h3
  } dmi_error_e;


  // 6.1.4. DTM Control and Status (dtmcs, at 0x10)
  // dtmcs errinfo

  typedef enum logic [2:0] {
    DTMNoImpl = 3'h0,
    DMIErr    = 3'h1,
    CommErr   = 3'h2,
    DeviceErr = 3'h3,
    Unknown   = 3'h4
  } dtmcs_errinfo_e;
endpackage
