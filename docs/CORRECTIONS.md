# RTL corrections and verification scope

This revision corrects functional mismatches in the publicly released prototype. The original release remains available at commit `d0f60f25b68f2616ebe23ea5ba25466dae8233ef`. No updated area, frequency, power or latency measurements are reported by this revision. Earlier manuscript measurements must not be treated as measurements of this corrected RTL without re-evaluation.

## Corrections

- Candidate allocations use all 72 magnitude bits from each 80-bit lane word; the remaining byte supplies the sign.
- Two RCDT constants match Falcon specification table 3.1 again.
- Assistance direction follows the accepted logical target.
- `pair_result_bank` retains completion and acceptance flags when the two comparison units finish on different cycles. Logical accepted results remain immutable while the lanes are reused. A fixed left-lane priority selects between two accepted helper candidates.
- Signed proposals travel with their pre-loop arithmetic and are latched for the evaluated round. Final addition uses `b + (2*b - 1)*z0`, including negative values and +19, rather than the unsigned base magnitude.
- The positive-proposal fixed-point construction adds one at bit 72 instead of the unbased all-ones literal.
- Binary64 center decomposition handles signed and subunit centers. The fractional component is rounded down to the prototype's 72-bit grid. This does not prove cryptographic numerical conformance.
- Combinational multipliers assign their intermediate product on all branches. Clocked random-input registers use nonblocking assignments.

## ChaCha20 provenance

The quarter-round and two-stage round logic is the same as `YiOuyang1/FalconSign/sampler/chacha20.sv` at `ecf98314201a0dcf4bdfce1fa4286e8ef103172e`, apart from whitespace, comments and import placement. The wrapper differs: it exposes 1024 output bits rather than 512, changes the buffer-index advance and rollover trigger, and changes initialization control. These wrapper adaptations are not validated merely by reuse of the round functions. The round functions are unchanged in this revision.

Candidate randomness is assigned by separate lane ports and bit slices; the prototype does not store per-word destination/purpose tags. Speculatively prepared unused candidates may be retargeted by rebuilding their arithmetic for the remaining center.

## Running the checks

Install Python 3, Icarus Verilog and Verilator, then run:

```
python3 tests/run_functional_checks.py
```

The checks cover:

- all 18 RCDT constants, 55 boundary points, 160 single-bit input-routing cases and both asymmetric direction expressions;
- 12 normal and 24 helper result-bank cases, including staggered completion, retries, result retention and fixed priority;
- 114 signed final-addition input pairs, using a test-only behavioral floating-point adder;
- positive, negative, subunit, integral, large and sub-grid center decomposition;
- the RFC 8439 quarter-round vector and 32 independently computed double-round states;
- top-level elaboration/lint with the test-only floating-point model. Existing width/style warnings remain.

`tests/DW_fp_addsub_sim.sv` is a test-only model for the exact integral operands used by the directed tests. It is not synthesizable IP or a substitute for licensed DesignWare arithmetic. Production synthesis must use the actual `DW_fp_addsub` implementation.

## Remaining verification

These checks do not prove complete sampler integration, pseudorandom-stream freshness across all refills/restarts, numerical equivalence to Falcon reference arithmetic, distributional security, or full signing correctness. In particular, the adapted refill wrapper still needs a complete consumption/stream-continuity test. This branch should remain a draft until those integration checks are complete. Do not interpret the local test pass as approval for cryptographic deployment.
