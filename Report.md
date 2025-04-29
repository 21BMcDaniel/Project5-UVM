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
  -# UVM Topology Construction Points

 - # 1. **Transaction Item** (Leaf Node)
```systemverilog
class memory_transaction extends uvm_sequence_item;
    `uvm_object_utils(memory_transaction)  // Registers transaction type
    // ... transaction fields and methods ...
endclass
...
typedef uvm_sequencer #(memory_transaction) memory_sequencer;
// Built automatically when driver connects
...
lass memory_sequence extends uvm_sequence #(memory_transaction);
    `uvm_object_utils(memory_sequence)  // Registers sequence type
    // ... sequence body ...
endclass
...
class memory_driver extends uvm_driver #(memory_transaction);
    `uvm_component_utils(memory_driver)  // Registers driver component
    // ... driver phases ...
endclass
...
class memory_driver extends uvm_driver #(memory_transaction);
    `uvm_component_utils(memory_driver)  // Registers driver component
    // ... driver phases ...
endclass
...
class memory_monitor extends uvm_component;
    `uvm_component_utils(memory_monitor)  // Registers monitor component
    // ... monitor phases ...
endclass
...
class memory_scoreboard extends uvm_component;
    `uvm_component_utils(memory_scoreboard)  // Registers scoreboard
    // ... analysis implementation ...
endclass
...
class memory_agent extends uvm_agent;
    `uvm_component_utils(memory_agent)  // Registers agent
    // Builds:
    // - driver
    // - sequencer 
    // - monitor
endclass
...
class memory_env extends uvm_env;
    `uvm_component_utils(memory_env)  // Registers environment
    // Builds:
    // - agent
    // - scoreboard
endclass
...
class memory_test extends uvm_test;
    `uvm_component_utils(memory_test)  // Registers test
    // Builds:
    // - environment
    // Starts sequences
endclass
...
```     
  - The testbench uses a flat hierarchy with a top module that instantiates:
     - The design under test (DUT)
     - The DUT interface (dut_if1)
     - A Monitor that observes the interface signals
     - A Scoreboard that checks data correctness
    ```scss
    top
    ├── dut (DUT)
    ├── dut_if1 (Interface)
    ├── monitor (connected to dut_if1 signals)
    └── scoreboard (checks data)
    ```
![image](https://github.com/user-attachments/assets/1ebc79f4-5e28-4a5f-881c-c801c3cdd5c1)
![image](https://github.com/user-attachments/assets/4ca55fcf-871e-42fe-9f35-664a5133a1f1)


## 4. Monitor Functionality

The **monitor** is responsible for:

- Observing DUT interface signals (read/write/address/data).
- Packaging observed signals into UVM transactions.
- Sending transactions to the scoreboard for checking.
- Non-intrusively capturing data (does not drive any signals).

  ![UVM Hierarchy Screenshot](https://github.com/user-attachments/assets/8fa63b63-1d4c-464f-9df4-60862041e4e7)

## 5. Conclusion

Through this exercise, I:

- Gained experience debugging VCD waveform generation issues.
- Learned about UVM simulation component interactions (driver, monitor, scoreboard).
- Verified that the memory model was working correctly through simulation and waveform analysis.
