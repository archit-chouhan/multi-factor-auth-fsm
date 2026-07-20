# multi-factor-auth-fsm
FSM-based multi-factor authentication controller in Verilog
# Multi-Factor Authentication FSM (Verilog)

A finite state machine that controls a multi-factor authentication flow, performing sequential verification of a password, OTP, and biometric input, with timeout and error handling built in.

## Overview

The FSM enforces a strict sequential check: password → OTP → biometric. Access is only granted after all three steps succeed in order. If a user takes too long on any step, or the step fails to complete, the FSM raises an error/timeout and restarts the flow automatically.

## States

| State       | Description                          |
|-------------|---------------------------------------|
| `INIT`      | Idle/reset state, auto-advances to password check |
| `PWD_CHECK` | Waiting for correct password (`PWD_OK`) |
| `OTP_CHECK` | Waiting for correct OTP (`OTP_OK`)     |
| `BIO_CHECK` | Waiting for correct biometric match (`BIO_OK`) |

## Ports

| Signal     | Direction | Description                                  |
|------------|-----------|------------------------------------------------|
| `CLK`      | input     | Clock                                          |
| `RST`      | input     | Synchronous reset                              |
| `PWD_OK`   | input     | Password verification result                   |
| `OTP_OK`   | input     | OTP verification result                         |
| `BIO_OK`   | input     | Biometric verification result                   |
| `ACCESS`   | output    | Pulses high for one cycle when all three checks succeed |
| `ERROR`    | output    | Pulses high for one cycle when a step fails/times out |
| `TIMEOUT`  | output    | Pulses high for one cycle when a step exceeds the allowed time |

## Behavior

- Each verification step has a configurable timeout window (`TIMEOUT_LIMIT` parameter, default 6 clock cycles).
- If a step doesn't succeed within that window, `ERROR` and `TIMEOUT` both pulse, and the FSM returns to `INIT`.
- After success, failure, or timeout, the FSM automatically returns to `INIT` and restarts the flow — no external "start" signal needed, so a user can retry immediately without a manual reset.
- `RST` can be asserted at any time to force the FSM back to `INIT`.

## Files

- `mfa_fsm.v` — FSM design
- `mfa_fsm_tb.v` — self-checking testbench

## Simulation

### Using Icarus Verilog
```bash
iverilog -o mfa_sim mfa_fsm.v mfa_fsm_tb.v
vvp mfa_sim
```

### Using Vivado
1. Create a new RTL project.
2. Add `mfa_fsm.v` as a design source.
3. Add `mfa_fsm_tb.v` as a simulation source.
4. Run Behavioral Simulation.

## Test Coverage

The testbench verifies:
1. Full successful sequence (password → OTP → biometric → access granted)
2. Timeout during password verification
3. Timeout during OTP verification
4. Timeout during biometric verification
5. Manual reset mid-sequence
