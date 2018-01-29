module usb_fs_mux (
  input clk,
  output reg reset,

  // raw usb d+/d- lines
  inout dp,
  inout dn,

  // output enable
  input oe,

  // transmit value when output enabled
  input dp_tx,
  input dn_tx,

  // receive value when output disabled
  output dp_rx,
  output dn_rx
);
  // reset detection
  reg [16:0] reset_timer;

  always @(posedge clk) begin
    reset <= 0;

    if (!dp_rx && !dn_rx) begin
      // SE0 detected from host
      if (reset_timer > 30000) begin
        // timer expired, assert reset
        reset <= 1;
      end else begin
        // timer not expired yet, keep counting
        reset_timer <= reset_timer + 1;
      end

    end else begin
      reset_timer <= 0;
    end
  end

  // SE0 assert on FPGA initialization
  reg [1:0] force_disc_state;
  reg [1:0] force_disc_state_next;

  localparam START = 0;
  localparam FORCE_DISC = 1;
  localparam CONNECTED = 2;

  reg [15:0] se0_timer;
  reg ready;
  reg drive_fpga_init_se0;

  always @(posedge clk) begin
    if (ready) begin
      if (se0_timer < 12000) begin
        se0_timer <= se0_timer + 1;
        drive_fpga_init_se0 <= 1;
      end else begin
        drive_fpga_init_se0 <= 0;
      end
    end else begin
      ready <= 1;
      se0_timer <= 0;
      drive_fpga_init_se0 <= 1;
    end
  end

  wire dp_raw_do, dn_raw_do;
  wire dp_raw_di, dn_raw_di;

  assign dp_raw_do = drive_fpga_init_se0 ? 1'b0 : (oe ? dp_tx : 1'b0);
  assign dn_raw_do = drive_fpga_init_se0 ? 1'b0 : (oe ? dn_tx : 1'b0);
  assign dp_rx = (oe || drive_fpga_init_se0) ? 1 : dp_raw_di;
  assign dn_rx = (oe || drive_fpga_init_se0) ? 0 : dn_raw_di;


  //(* PULLUP_STRENGTH = "3P3K" *)
  SB_IO #(
    .PIN_TYPE(6'b101001),
    .PULLUP(1'b0)
  ) dp_io (
    .PACKAGE_PIN(dp),
    .OUTPUT_ENABLE(oe),
    .D_OUT_0(dp_raw_do),
    .D_IN_0(dp_raw_di)
  );

  SB_IO #(
    .PIN_TYPE(6'b101001),
    .PULLUP(1'b0)
  ) dn_io (
    .PACKAGE_PIN(dn),
    .OUTPUT_ENABLE(oe),
    .D_OUT_0(dn_raw_do),
    .D_IN_0(dn_raw_di)
  );

endmodule
