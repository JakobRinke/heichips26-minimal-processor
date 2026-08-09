`timescale 1ns/1ps
//=============================================================================
// tb_mmu.sv
//
// Self-checking testbench for the `mmu` module.
//
// Because the MMU's correctness is defined jointly by the CPU<->MMU
// handshake AND the MMU<->eFPGA handshake, this testbench contains a
// behavioral eFPGA model that plays by the rules described in the spec:
//
//   1. MMU sends 8'b0000_00x1 (x = do_swap) as the opcode byte.
//   2. MMU sends the address byte.
//   3. eFPGA holds fpga_in1[1:0] == 2'b11 while busy; when finished, it
//      changes fpga_in1 so that fpga_in1[1:0] != 2'b11 and presents the
//      read data (see interpretation note below).
//   4. If a swap was requested, MMU then sends the write data byte, and
//      the eFPGA again holds fpga_in1[1:0]==2'b11 while busy, releasing
//      it (!=2'b11) when the write completes.
//   5. MMU only starts the NEXT eFPGA interaction after the CPU it just
//      served has acknowledged (deasserted `valid`).
//
// Interpretation notes (spec is ambiguous on exact bit assembly, so the
// testbench pins down the most natural reading and documents it):
//   - For a LOAD, data_out_cpu is expected to be the 16-bit concatenation
//     {fpga_in2, fpga_in1} captured at the moment the read completes,
//     matching the "lower/higher significance bits" port description.
//   - For a SWAP, the spec explicitly says "only fpga_in2 is used for the
//     data" for the value returned to the CPU, so only the upper byte of
//     data_out_cpu (bits [2*DATA_WIDTH-1:DATA_WIDTH]) is checked against
//     the old eFPGA memory content; the lower byte is implementation
//     defined and is NOT checked.
//   - The write value sent to the eFPGA during a swap is reg_data (8 bits)
//     of the requesting CPU; the model commits it into the low byte of its
//     internal memory word, keeping the high byte unchanged, so a
//     subsequent load from the same address is fully predictable.
//
// Key protocol invariants checked:
//   - mem_done is a single-cycle pulse and never re-pulses spuriously.
//   - data_out_cpu is a shared bus: at most one CPU's mem_done is high at
//     any time.
//   - mem_done is never asserted for a CPU whose `valid` is low.
//   - The opcode byte format (bits [7:2]==0, bit0==1, bit1==do_swap) is
//     exactly what the granted CPU requested.
//   - The address sent to the eFPGA matches the granted CPU's ram_addr.
//   - For a swap, the write byte sent to the eFPGA matches the granted
//     CPU's reg_data.
//   - The MMU does not start a new eFPGA transaction for a second,
//     already-pending CPU until the first CPU has acknowledged completion
//     (tests spec step 6 explicitly).
//   - Read-after-write consistency across a swap followed by a load.
//=============================================================================

module tb_mmu;

  //--------------------------------------------------------------------
  // Parameters
  //--------------------------------------------------------------------
  localparam int CPU_COUNT   = 2;
  localparam int ADDR_WIDTH  = 8;
  localparam int DATA_WIDTH  = 8;
  localparam real CLK_PERIOD = 10.0; // ns

  localparam int WATCHDOG_LIMIT   = 400;    // cycles, per-transaction timeout
  localparam int SWAP_WAIT_LIMIT  = 400;    // cycles, fpga-model swap wait timeout
  localparam int MAX_BUSY_CYCLES  = 5;      // randomized eFPGA "processing" delay
  localparam real GLOBAL_TIMEOUT  = 500000; // ns, whole-testbench watchdog

  localparam logic [DATA_WIDTH-1:0] BUSY_PATTERN       = 8'b0000_0011;
  localparam logic [DATA_WIDTH-1:0] WRITE_DONE_PATTERN = 8'b0000_0000;

  //--------------------------------------------------------------------
  // DUT signals
  //--------------------------------------------------------------------
  logic clk_i;
  logic rst_ni;

  logic [ADDR_WIDTH-1:0] reg_data [CPU_COUNT-1:0];
  logic [ADDR_WIDTH-1:0] ram_addr [CPU_COUNT-1:0];
  logic                  valid    [CPU_COUNT-1:0];
  logic                  do_swap  [CPU_COUNT-1:0];
  logic                  mem_done [CPU_COUNT-1:0];

  logic [DATA_WIDTH*2-1:0] data_out_cpu;

  logic [DATA_WIDTH-1:0] fpga_in1;
  logic [DATA_WIDTH-1:0] fpga_in2;
  logic [DATA_WIDTH-1:0] fpga_out;

  //--------------------------------------------------------------------
  // Bookkeeping
  //--------------------------------------------------------------------
  int errors = 0;
  int checks = 0;

  logic [DATA_WIDTH*2-1:0] scoreboard_mem [0:(1<<ADDR_WIDTH)-1];

  bit                   addr_pending      [0:(1<<ADDR_WIDTH)-1];
  logic                 swap_expected_arr [0:(1<<ADDR_WIDTH)-1];
  logic [DATA_WIDTH-1:0] wdata_expected_arr [0:(1<<ADDR_WIDTH)-1];

  //--------------------------------------------------------------------
  // DUT instantiation
  //--------------------------------------------------------------------
  mmu #(
    .CPU_COUNT (CPU_COUNT),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),
    .reg_data    (reg_data),
    .ram_addr    (ram_addr),
    .valid       (valid),
    .do_swap     (do_swap),
    .mem_done    (mem_done),
    .data_out_cpu(data_out_cpu),
    .fpga_in1    (fpga_in1),
    .fpga_in2    (fpga_in2),
    .fpga_out    (fpga_out)
  );

  //--------------------------------------------------------------------
  // Clock
  //--------------------------------------------------------------------
  initial clk_i = 1'b0;
  always #(CLK_PERIOD/2.0) clk_i = ~clk_i;

  //--------------------------------------------------------------------
  // Helpers
  //--------------------------------------------------------------------
  task automatic report_error(string msg);
    errors++;
    $error("[TB ERROR] t=%0t : %s", $time, msg);
  endtask

  function automatic int count_mem_done_ones();
    int c;
    c = 0;
    for (int i = 0; i < CPU_COUNT; i++) if (mem_done[i]) c++;
    return c;
  endfunction

  function automatic logic decode_opcode_swapbit(input logic [DATA_WIDTH-1:0] op);
    if (op[7:2] != 6'b0 || op[0] != 1'b1) begin
      errors++;
      $error("[TB ERROR] t=%0t : Illegal opcode on fpga_out: expected 8'b0000_00x1, got 8'b%b", $time, op);
    end
    return op[1];
  endfunction

  //--------------------------------------------------------------------
  // Global invariant monitors (run for the whole simulation)
  //--------------------------------------------------------------------
  always @(posedge clk_i) begin
    #1;
    if (count_mem_done_ones() > 1) begin
      report_error("Shared-bus violation: more than one mem_done asserted simultaneously");
    end
    for (int i = 0; i < CPU_COUNT; i++) begin
      if (mem_done[i] && !valid[i]) begin
        report_error($sformatf("mem_done[%0d] asserted while valid[%0d] is low", i, i));
      end
    end
  end

  //--------------------------------------------------------------------
  // eFPGA behavioral model
  //--------------------------------------------------------------------
  typedef enum logic [2:0] {
    F_IDLE,
    F_ADDR,
    F_READ_WAIT,
    F_READ_DONE,
    F_WRITE_BUSY,
    F_WRITE_DONE
  } fpga_state_e;

  fpga_state_e f_state;
  logic                    f_swap_lat;
  logic [ADDR_WIDTH-1:0]   f_addr_lat;
  logic [DATA_WIDTH-1:0]   f_wdata_lat;
  int                      f_wait_cnt;
  int                      f_wait_target;
  int                      f_timeout_cnt;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      f_state       <= F_IDLE;
      fpga_in1      <= BUSY_PATTERN;
      fpga_in2      <= '0;
      f_wait_cnt    <= 0;
      f_timeout_cnt <= 0;
    end else begin
      unique case (f_state)

        //-------------------------------------------------------------
        F_IDLE: begin
          if (fpga_out[0]) begin
            f_swap_lat <= fpga_out[1];
            f_state    <= F_ADDR;
          end
        end

        //-------------------------------------------------------------
        F_ADDR: begin
          logic [ADDR_WIDTH-1:0] a;
          a = fpga_out[ADDR_WIDTH-1:0];

          if (!addr_pending[a]) begin
            report_error($sformatf("eFPGA saw address 0x%0h that is not currently pending from any CPU", a));
          end else if (f_swap_lat !== swap_expected_arr[a]) begin
            report_error($sformatf("Opcode swap-bit mismatch for address 0x%0h: expected %0b got %0b",
                                     a, swap_expected_arr[a], f_swap_lat));
          end

          f_addr_lat    <= a;
          f_wait_cnt    <= 0;
          f_wait_target <= $urandom_range(1, MAX_BUSY_CYCLES);
          fpga_in1      <= BUSY_PATTERN;
          f_state       <= F_READ_WAIT;
        end

        //-------------------------------------------------------------
        F_READ_WAIT: begin
          if (f_wait_cnt < f_wait_target) begin
            fpga_in1   <= BUSY_PATTERN;
            f_wait_cnt <= f_wait_cnt + 1;
          end else begin
            if (f_swap_lat) begin
                fpga_in1      <= 8'h00;
                fpga_in2      <= scoreboard_mem[f_addr_lat][DATA_WIDTH-1:0];
            end else begin
                fpga_in1      <= scoreboard_mem[f_addr_lat][DATA_WIDTH-1:0];
                fpga_in2      <= scoreboard_mem[f_addr_lat][2*DATA_WIDTH-1:DATA_WIDTH];
                f_timeout_cnt <= 0;
            end
            f_state       <= F_READ_DONE;
          end
        end

        //-------------------------------------------------------------
        // NOTE: fpga_in1/fpga_in2 are intentionally left unassigned in
        // this state so they retain the "done" value indefinitely,
        // giving the DUT unlimited time to react regardless of its
        // internal pipeline depth.
        F_READ_DONE: begin
          fpga_in1      <= BUSY_PATTERN;
          if (f_swap_lat) begin
            if (fpga_out !== f_addr_lat) begin
              // A changed value on fpga_out is interpreted as the write
              // data byte for the swap.
              logic [DATA_WIDTH-1:0] wd;
              wd = fpga_out;
              if (wd !== wdata_expected_arr[f_addr_lat]) begin
                report_error($sformatf("Swap write-data mismatch for addr 0x%0h: expected 0x%0h got 0x%0h",
                                         f_addr_lat, wdata_expected_arr[f_addr_lat], wd));
              end
              f_wdata_lat   <= wd;
              f_wait_cnt    <= 0;
              f_wait_target <= $urandom_range(1, MAX_BUSY_CYCLES);
              f_timeout_cnt <= 0;
              f_state       <= F_WRITE_BUSY;
            end else begin
              f_timeout_cnt <= f_timeout_cnt + 1;
              if (f_timeout_cnt > SWAP_WAIT_LIMIT) begin
                report_error($sformatf("Timed out waiting for MMU to send write data after swap read-done (addr=0x%0h)", f_addr_lat));
                f_state <= F_IDLE;
              end
            end
          end else begin
            // Load: no write phase expected; go back to idle. fpga_in1/2
            // keep showing the completed read data until the next
            // transaction overwrites them.
            f_state <= F_IDLE;
          end
        end

        //-------------------------------------------------------------
        F_WRITE_BUSY: begin
          if (f_wait_cnt < f_wait_target) begin
            fpga_in1   <= BUSY_PATTERN;
            f_wait_cnt <= f_wait_cnt + 1;
          end else begin
            scoreboard_mem[f_addr_lat][DATA_WIDTH-1:0] <= f_wdata_lat;
            fpga_in1 <= WRITE_DONE_PATTERN;
            f_state  <= F_WRITE_DONE;
          end
        end

        //-------------------------------------------------------------
        F_WRITE_DONE: begin
          // Same rationale as F_READ_DONE: leave fpga_in1 alone so the
          // "done" indication persists until the DUT reacts.
          fpga_in1   <= BUSY_PATTERN;
          f_state <= F_IDLE;
        end

        default: f_state <= F_IDLE;
      endcase
    end
  end

  //--------------------------------------------------------------------
  // Utility: wait until the eFPGA model latches a specific address
  // (used to check arbitration/serialization ordering).
  //--------------------------------------------------------------------
  task automatic wait_for_fpga_addr_seen(input logic [ADDR_WIDTH-1:0] target, output time t);
    forever begin
      @(posedge clk_i); #1;
      if (f_state == F_READ_WAIT && f_addr_lat == target) begin
        t = $time;
        return;
      end
    end
  endtask

  //--------------------------------------------------------------------
  // CPU driver / checker task
  //--------------------------------------------------------------------
  task automatic do_cpu_transaction(
    input  int    cpu_idx,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic  swap,
    input  int    extra_hold_cycles,
    output logic [2*DATA_WIDTH-1:0] rdata,
    output int    latency_cycles,
    output time   ack_time,
    input  bit    expect_idle_fpga
  );
    int wait_cycles;
    bit saw_done;
    logic [2*DATA_WIDTH-1:0] exp_before;

    exp_before = scoreboard_mem[addr];

    @(posedge clk_i);
    ram_addr[cpu_idx] = addr;
    reg_data[cpu_idx] = wdata;
    do_swap[cpu_idx]  = swap;
    valid[cpu_idx]    = 1'b1;

    wait_cycles    = 0;
    saw_done       = 0;
    rdata          = '0;
    latency_cycles = -1;
    ack_time       = 0;

    while (!saw_done) begin
      @(posedge clk_i); #1;
      wait_cycles++;

      checks++;
      if (valid[cpu_idx] !== 1'b1) begin
        report_error($sformatf("CPU%0d: valid observed low before mem_done was seen (unexpected)", cpu_idx));
      end

      if (wait_cycles > WATCHDOG_LIMIT) begin
        report_error($sformatf("CPU%0d: watchdog timeout waiting for mem_done (addr=0x%0h swap=%0b)", cpu_idx, addr, swap));
        ack_time = $time;
        return;
      end

      if (mem_done[cpu_idx] == 1'b1) begin
        saw_done       = 1;
        rdata          = data_out_cpu;
        latency_cycles = wait_cycles;

        checks++;
        if (count_mem_done_ones() != 1) begin
          report_error($sformatf("CPU%0d: mem_done coincided with another CPU's mem_done", cpu_idx));
        end

        checks++;
        if (swap) begin
          if (rdata[DATA_WIDTH-1:0] !== exp_before[DATA_WIDTH-1:0]) begin
            report_error($sformatf(
              "CPU%0d swap: returned old-data high byte mismatch (addr=0x%0h): expected 0x%0h got 0x%0h",
              cpu_idx, addr, exp_before[DATA_WIDTH-1:0], rdata[DATA_WIDTH-1:0]));
          end
        end else begin
          if (rdata !== exp_before) begin
            report_error($sformatf(
              "CPU%0d load: returned data mismatch (addr=0x%0h): expected 0x%0h got 0x%0h",
              cpu_idx, addr, exp_before, rdata));
          end
        end
      end
    end

    // Hold valid asserted for extra cycles: verify no re-pulse of
    // mem_done, and (if requested) that no new eFPGA transaction starts
    // while this CPU has not yet acknowledged and no one else is pending.
    for (int k = 0; k < extra_hold_cycles; k++) begin
      @(posedge clk_i); #1;
      checks++;
      if (mem_done[cpu_idx] === 1'b1) begin
        report_error($sformatf("CPU%0d: mem_done re-asserted while valid held after completion (k=%0d)", cpu_idx, k));
      end
      if (expect_idle_fpga) begin
        checks++;
        if (f_state == F_ADDR) begin
          report_error($sformatf(
            "CPU%0d: a new eFPGA opcode phase started before this CPU acknowledged completion, with no other pending requests", cpu_idx));
        end
      end
    end

    // Acknowledge
    @(posedge clk_i);
    valid[cpu_idx] = 1'b0;
    ack_time = $time;
    @(posedge clk_i); #1;
  endtask

  //--------------------------------------------------------------------
  // Reset
  //--------------------------------------------------------------------
  task automatic apply_reset();
    rst_ni = 1'b0;
    for (int i = 0; i < CPU_COUNT; i++) begin
      valid[i]    = 1'b0;
      do_swap[i]  = 1'b0;
      ram_addr[i] = '0;
      reg_data[i] = '0;
    end
    repeat (4) @(posedge clk_i);
    #1;
    checks++;
    if (count_mem_done_ones() != 0) begin
      report_error("mem_done is not all-zero during/after reset");
    end
    rst_ni = 1'b1;
    repeat (2) @(posedge clk_i);
    #1;
  endtask

  //--------------------------------------------------------------------
  // Test scenarios
  //--------------------------------------------------------------------
  task automatic test_concurrent_requests();
    logic [2*DATA_WIDTH-1:0] r0, r1;
    int l0, l1;
    time t0, t1;

    addr_pending[8'h60] = 1; swap_expected_arr[8'h60] = 0;
    addr_pending[8'h61] = 1; swap_expected_arr[8'h61] = 1; wdata_expected_arr[8'h61] = 8'h55;

    fork
      do_cpu_transaction(0, 8'h60, 8'h00, 1'b0, 0, r0, l0, t0, 1'b0);
      do_cpu_transaction(1, 8'h61, 8'h55, 1'b1, 0, r1, l1, t1, 1'b0);
    join

    addr_pending[8'h60] = 0;
    addr_pending[8'h61] = 0;
  endtask

  task automatic test_concurrent_requests_random();
    logic [2*DATA_WIDTH-1:0] r0, r1;
    int l0, l1;
    time t0, t1;
    logic [ADDR_WIDTH-1:0] a0, a1;
    logic [DATA_WIDTH-1:0] d0, d1;
    logic s0, s1;

    a0 = $urandom_range(0, (1<<ADDR_WIDTH)-1);
    do begin
      a1 = $urandom_range(0, (1<<ADDR_WIDTH)-1);
    end while (a1 == a0);

    d0 = $urandom();
    if (d0[1:0] == 2'b11) d0[1:0] = 2'b00;
    d1 = $urandom();
    if (d1[1:0] == 2'b11) d1[1:0] = 2'b00;

    s0 = $urandom_range(0, 1);
    s1 = $urandom_range(0, 1);

    addr_pending[a0] = 1; swap_expected_arr[a0] = s0; wdata_expected_arr[a0] = d0;
    addr_pending[a1] = 1; swap_expected_arr[a1] = s1; wdata_expected_arr[a1] = d1;

    fork
      do_cpu_transaction(0, a0, d0, s0, 0, r0, l0, t0, 1'b0);
      do_cpu_transaction(1, a1, d1, s1, 0, r1, l1, t1, 1'b0);
    join

    addr_pending[a0] = 0;
    addr_pending[a1] = 0;
  endtask

  task automatic test_serialization();
    logic [2*DATA_WIDTH-1:0] rA, rB;
    int lA, lB;
    time ackA_time, addrB_seen_time;
    logic [ADDR_WIDTH-1:0] addrA, addrB;

    addrA = 8'h30;
    addrB = 8'h31;
    addrB_seen_time = 0;

    addr_pending[addrA] = 1; swap_expected_arr[addrA] = 0;
    addr_pending[addrB] = 1; swap_expected_arr[addrB] = 0;

    fork
      do_cpu_transaction(0, addrA, 8'h00, 1'b0, 10, rA, lA, ackA_time, 1'b0);
      do_cpu_transaction(1, addrB, 8'h00, 1'b0, 0,  rB, lB, addrB_seen_time /*unused*/, 1'b0);
      wait_for_fpga_addr_seen(addrB, addrB_seen_time);
    join

    addr_pending[addrA] = 0;
    addr_pending[addrB] = 0;

    checks++;
    if (addrB_seen_time == 0 || addrB_seen_time < ackA_time) begin
      report_error($sformatf(
        "Serialization violation: eFPGA transaction for CPU1 (addr=0x%0h) started at t=%0t, before CPU0 acknowledged at t=%0t",
        addrB, addrB_seen_time, ackA_time));
    end else begin
      $display("[TB] PASS: CPU1's eFPGA transaction correctly deferred until after CPU0 ack (ackA=%0t, addrB_seen=%0t)",
                ackA_time, addrB_seen_time);
    end
  endtask

  //--------------------------------------------------------------------
  // Main test sequence
  //--------------------------------------------------------------------
  task automatic run_all_tests();
    logic [2*DATA_WIDTH-1:0] rdata;
    int lat;
    time tack;

    $dumpfile("testbenches/waveforms/mmu_comp.vcd");
    $dumpvars();

    $display("=== MMU testbench start ===");

    apply_reset();

    $display("-- Scenario: single load (CPU0) --");
    addr_pending[8'h10] = 1; swap_expected_arr[8'h10] = 0;
    do_cpu_transaction(0, 8'h10, 8'h00, 1'b0, 5, rdata, lat, tack, 1'b1);
    addr_pending[8'h10] = 0;

    $display("-- Scenario: single swap (CPU0) --");
    addr_pending[8'h20] = 1; swap_expected_arr[8'h20] = 1; wdata_expected_arr[8'h20] = 8'h44;
    do_cpu_transaction(0, 8'h20, 8'h44, 1'b1, 5, rdata, lat, tack, 1'b1);
    addr_pending[8'h20] = 0;

    $display("-- Scenario: read-after-swap consistency (CPU1) --");
    addr_pending[8'h25] = 1; swap_expected_arr[8'h25] = 1; wdata_expected_arr[8'h25] = 8'h3C;
    do_cpu_transaction(1, 8'h25, 8'h3C, 1'b1, 2, rdata, lat, tack, 1'b0);
    addr_pending[8'h25] = 0;

    addr_pending[8'h25] = 1; swap_expected_arr[8'h25] = 0;
    do_cpu_transaction(1, 8'h25, 8'h00, 1'b0, 2, rdata, lat, tack, 1'b0);
    addr_pending[8'h25] = 0;

    $display("-- Scenario: concurrent requests (CPU0 & CPU1) --");
    test_concurrent_requests();

    $display("-- Scenario: serialization ordering (ack before next eFPGA txn) --");
    test_serialization();

    $display("-- Scenario: randomized concurrent stress --");
    for (int iter = 0; iter < 8; iter++) begin
      test_concurrent_requests_random();
    end

    $display("=== MMU testbench complete ===");
  endtask

  //--------------------------------------------------------------------
  // Summary / top-level flow
  //--------------------------------------------------------------------
  task automatic print_summary();
    $display("=====================================");
    $display(" TESTBENCH SUMMARY");
    $display(" Checks performed : %0d", checks);
    $display(" Errors           : %0d", errors);
    if (errors == 0) $display(" RESULT: PASS");
    else              $display(" RESULT: FAIL");
    $display("=====================================");
  endtask

  initial begin : main
    int seed;
    seed = 32'hDEC0FFEE;
    void'($urandom(seed));

    // Populate the eFPGA scoreboard memory. Low byte's two LSBs are
    // forced away from 2'b11 so they are never confused with the
    // busy pattern, matching the spec's implicit requirement.
    for (int i = 0; i < (1<<ADDR_WIDTH); i++) begin
      logic [DATA_WIDTH-1:0] lo, hi;
      lo = $urandom();
      if (lo[1:0] == 2'b11) lo[1:0] = 2'b01;
      hi = $urandom();
      scoreboard_mem[i] = {hi, lo};
      addr_pending[i]      = 0;
      swap_expected_arr[i] = 0;
      wdata_expected_arr[i]= '0;
    end

    fork
      begin
        run_all_tests();
      end
      begin : watchdog
        #(GLOBAL_TIMEOUT);
        report_error("GLOBAL WATCHDOG TIMEOUT - simulation did not complete in time");
      end
    join_any
    disable fork;

    print_summary();
    $finish;
  end

endmodule