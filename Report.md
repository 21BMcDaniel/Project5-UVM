# UVM Simulation Report: Memory Testbench

## 1. Introduction
This project involved simulating a memory module using a UVM (Universal Verification Methodology) testbench.  
I debugged issues related to VCD dumping and viewing waveforms, and verified the correct setup of UVM components like the monitor, scoreboard, driver, and environment.

## 2. Steps Taken

- **Simulation Setup**
  - Used Synopsys VCS toolchain.
  - Enabled waveform dumping by adding:
    ```systemverilog
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
    end
    ```
  - Recompiled and simulated with UVM test (`memory_test`).

- **Waveform Debugging**
  - Encountered no waveforms initially because interfaces cannot be selectively dumped.
  - Solved the issue by dumping **all signals** with `$dumpvars(0);`.
  - Opened `dump.vcd` in **EPWave**.
  - Appended all DUT and top-level signals manually into the viewing window.

- **UVM Warnings Observed**
  - Warnings related to illegal class handle usage (`!` operator) in Synopsys UVM library code — not critical for this simulation.
  - Interface selective VCD dumping warning resolved by dumping all signals.

## 3. UVM Hierarchy

The UVM hierarchy created during simulation includes:

- **uvm_root**
  - **uvm_test_top** (instance of `memory_test`)
    - **m_env** (instance of the environment)
      - **m_agent**
        - **m_driver** (drives transactions to the DUT)
        - **m_sequencer** (generates transactions)
        - **m_monitor** (captures DUT outputs and forwards them to scoreboard)
      - **m_scoreboard** (checks correctness of memory read/write)

## 4. Monitor Functionality

The **monitor** is responsible for:

- Observing DUT interface signals (read/write/address/data).
- Packaging observed signals into UVM transactions.
- Sending transactions to the scoreboard for checking.
- Non-intrusively capturing data (does not drive any signals).

## 5. Conclusion

Through this exercise, I:

- Gained experience debugging VCD waveform generation issues.
- Learned about UVM simulation component interactions (driver, monitor, scoreboard).
- Verified that the memory model was working correctly through simulation and waveform analysis.
