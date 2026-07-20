module mfa_fsm #(
    parameter TIMEOUT_LIMIT = 6     // cycles allowed to complete each step
)(
    input        CLK,
    input        RST,
    input        PWD_OK,
    input        OTP_OK,
    input        BIO_OK,
    output       ACCESS,
    output       ERROR,
    output       TIMEOUT
);

    // 4 states, as required
    localparam INIT      = 2'b00,
               PWD_CHECK  = 2'b01,
               OTP_CHECK  = 2'b10,
               BIO_CHECK  = 2'b11;

    reg [1:0] state;
    reg [3:0] timer;

    reg access_reg;
    reg error_reg;
    reg timeout_reg;

    always @(posedge CLK) begin
        if (RST) begin
            state       <= INIT;
            timer       <= 0;
            access_reg  <= 1'b0;
            error_reg   <= 1'b0;
            timeout_reg <= 1'b0;
        end else begin
            // default: error/timeout are single-cycle pulses
            error_reg   <= 1'b0;
            timeout_reg <= 1'b0;

            case (state)

                INIT: begin
                    state      <= PWD_CHECK;
                    timer      <= 0;
                    access_reg <= 1'b0;   // clear access at the start of a fresh attempt
                end

                PWD_CHECK: begin
                    if (PWD_OK) begin
                        state <= OTP_CHECK;
                        timer <= 0;
                    end else if (timer == TIMEOUT_LIMIT - 1) begin
                        state       <= INIT;
                        timer       <= 0;
                        error_reg   <= 1'b1;
                        timeout_reg <= 1'b1;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                OTP_CHECK: begin
                    if (OTP_OK) begin
                        state <= BIO_CHECK;
                        timer <= 0;
                    end else if (timer == TIMEOUT_LIMIT - 1) begin
                        state       <= INIT;
                        timer       <= 0;
                        error_reg   <= 1'b1;
                        timeout_reg <= 1'b1;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                BIO_CHECK: begin
                    if (BIO_OK) begin
                        state      <= INIT;
                        timer      <= 0;
                        access_reg <= 1'b1;   // access granted pulse
                    end else if (timer == TIMEOUT_LIMIT - 1) begin
                        state       <= INIT;
                        timer       <= 0;
                        error_reg   <= 1'b1;
                        timeout_reg <= 1'b1;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                default: state <= INIT;

            endcase
        end
    end

    assign ACCESS  = access_reg;
    assign ERROR   = error_reg;
    assign TIMEOUT = timeout_reg;

endmodule
