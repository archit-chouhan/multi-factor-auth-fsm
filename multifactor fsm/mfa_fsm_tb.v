`timescale 1ns/1ps

module mfa_fsm_tb;

    localparam TIMEOUT_LIMIT = 6;

    reg CLK;
    reg RST;
    reg PWD_OK;
    reg OTP_OK;
    reg BIO_OK;

    wire ACCESS;
    wire ERROR;
    wire TIMEOUT;

    integer errors = 0;

    mfa_fsm #(.TIMEOUT_LIMIT(TIMEOUT_LIMIT)) dut (
        .CLK     (CLK),
        .RST     (RST),
        .PWD_OK  (PWD_OK),
        .OTP_OK  (OTP_OK),
        .BIO_OK  (BIO_OK),
        .ACCESS  (ACCESS),
        .ERROR   (ERROR),
        .TIMEOUT (TIMEOUT)
    );

    // 10ns clock period
    always #5 CLK = ~CLK;

    task check(input cond, input [255:0] msg);
        begin
            if (cond) begin
                $display("PASS: %0s", msg);
            end else begin
                $display("FAIL: %0s", msg);
                errors = errors + 1;
            end
        end
    endtask

    task apply_reset;
        begin
            RST    = 1'b1;
            PWD_OK = 1'b0;
            OTP_OK = 1'b0;
            BIO_OK = 1'b0;
            @(posedge CLK);
            @(posedge CLK);
            RST = 1'b0;
            @(posedge CLK); // one cycle in INIT -> moves to PWD_CHECK
        end
    endtask

    initial begin
        CLK    = 0;
        RST    = 0;
        PWD_OK = 0;
        OTP_OK = 0;
        BIO_OK = 0;

        // Test 1: full successful sequence (PWD -> OTP -> BIO -> ACCESS)
        apply_reset;

        PWD_OK = 1'b1;
        @(posedge CLK); #1;
        check(dut.state == dut.OTP_CHECK, "T1: moved to OTP_CHECK after correct password");
        PWD_OK = 1'b0;

        OTP_OK = 1'b1;
        @(posedge CLK); #1;
        check(dut.state == dut.BIO_CHECK, "T1: moved to BIO_CHECK after correct OTP");
        OTP_OK = 1'b0;

        BIO_OK = 1'b1;
        @(posedge CLK); #1;
        check(ACCESS == 1'b1, "T1: ACCESS asserted after correct biometric");
        check(ERROR == 1'b0 && TIMEOUT == 1'b0, "T1: no error/timeout during successful path");
        BIO_OK = 1'b0;

        @(posedge CLK); #1;
        check(dut.state == dut.PWD_CHECK, "T1: FSM auto-restarts to PWD_CHECK after granting access");

        // Test 2: timeout during PWD_CHECK (never enter correct password)
        apply_reset;

        repeat (TIMEOUT_LIMIT) @(posedge CLK); // let timer run out without PWD_OK
        #1;
        check(ERROR == 1'b1 && TIMEOUT == 1'b1, "T2: ERROR and TIMEOUT pulse when password step times out");
        @(posedge CLK); #1;
        check(dut.state == dut.PWD_CHECK, "T2: FSM returns to PWD_CHECK after timeout");

        // Test 3: timeout during OTP_CHECK
        apply_reset;
        PWD_OK = 1'b1;
        @(posedge CLK); #1;
        PWD_OK = 1'b0;
        check(dut.state == dut.OTP_CHECK, "T3: reached OTP_CHECK");

        repeat (TIMEOUT_LIMIT) @(posedge CLK); // let OTP step time out
        #1;
        check(ERROR == 1'b1 && TIMEOUT == 1'b1, "T3: ERROR and TIMEOUT pulse when OTP step times out");

        // Test 4: timeout during BIO_CHECK
        apply_reset;
        PWD_OK = 1'b1;
        @(posedge CLK); #1;
        PWD_OK = 1'b0;
        OTP_OK = 1'b1;
        @(posedge CLK); #1;
        OTP_OK = 1'b0;
        check(dut.state == dut.BIO_CHECK, "T4: reached BIO_CHECK");

        repeat (TIMEOUT_LIMIT) @(posedge CLK); // let biometric step time out
        #1;
        check(ERROR == 1'b1 && TIMEOUT == 1'b1, "T4: ERROR and TIMEOUT pulse when biometric step times out");

        // Test 5: RST works mid-sequence
        apply_reset;
        PWD_OK = 1'b1;
        @(posedge CLK); #1;
        PWD_OK = 1'b0;
        check(dut.state == dut.OTP_CHECK, "T5: mid-way through sequence before reset");

        RST = 1'b1;
        @(posedge CLK); #1;
        check(dut.state == dut.INIT, "T5: RST forces state back to INIT immediately");
        RST = 1'b0;

        // summary
        #20;
        if (errors == 0)
            $display("\n=== ACCESS GRANTED ===");
        else
            $display("\n=== %0d TEST(S) FAILED ===", errors);

        $finish;
    end

endmodule
