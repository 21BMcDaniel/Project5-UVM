# Scoreboard Explanation

## Overview
The **scoreboard** in this project is responsible for **checking whether the DUT (Design Under Test)** behaves correctly by **comparing the expected data** with the **actual data** output from the DUT.

In the `testbench.sv`, the scoreboard listens to signals captured by the **monitor** (such as `addr`, `data_in`, `data_out`, `wr_en`, `rd_en`, etc.) through the `dut_if1` interface.

The scoreboard keeps an **internal reference model**:
- It stores expected values based on **write operations** (`wr_en`).
- It checks expected values during **read operations** (`rd_en`).

## How it Works

### 1. Write Phase (`wr_en` is active)
- When a **write enable** (`wr_en`) signal is asserted, the monitor captures the address (`addr`) and data (`data_in`).
- The scoreboard saves the `data_in` at the given `addr` in a **reference memory model** (e.g., `mem[addr] = data_in`).

### 2. Read Phase (`rd_en` is active)
- When a **read enable** (`rd_en`) signal is asserted, the monitor checks if there is a value stored at that address in the reference model.
- If found, the scoreboard **compares**:
  - The **expected value** (from the internal memory model)
  - Versus the **actual output** (`data_out`) from the DUT.

### 3. Result Handling
- If the expected and actual values **match**, the scoreboard prints/logs a "pass" message.
- If they **mismatch**, the scoreboard logs an **error** or failure.

### 4. Special Cases
- If no value was written yet at the address (no prior `wr_en`), the scoreboard **prints a warning** like:

![Screenshot 2025-04-28 215148](https://github.com/user-attachments/assets/b62ceba8-6b86-4c90-96e2-33a8fdb7dc13)

### 5. Example of Scoreboard Output

![Screenshot 2025-04-28 213828](https://github.com/user-attachments/assets/0b66dce3-8ad4-4b81-b8df-17c4a82d8276)
