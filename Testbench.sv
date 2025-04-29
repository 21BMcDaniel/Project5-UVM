`include "uvm_macros.svh"
package memory_pkg;
    import uvm_pkg::*;
    class memory_transaction extends uvm_sequence_item;
        // Register with object utils 
        `uvm_object_utils(memory_transaction)

        // Data for transaction (class attributes)
        // rand bit clk,      // Clock
        // rand bit rst_n,    // Active-low reset
        rand bit rst_n;
        rand bit wr_en;    // Write enable
        rand bit rd_en;    // Read enable
        rand int addr;     // Address
        rand int data_in;  // Data input
        int data_out;

        // Constraints:
        constraint c_rd_wr {
            // Read and write are separate
            wr_en != rd_en;
        }
      
        constraint c_addr { addr >= 0; addr < 256; }
        constraint c_data_in { data_in >= 0; data_in < 32'h7FFFFFFF; }

        // Constructor:
        // transaction does not have parent since it's not a component
        function new(string name = "");
            super.new(name);
        endfunction

        // Helper function to visualize a transaction:
        function string convert2string;
          return $sformatf("wr_en=%b, rd_en=%b, addr=%0h, data_in=%0h, data_out=%0h", wr_en, rd_en, addr, data_in, data_out);
        endfunction

        // Copy transaction data from some object:
        function void do_copy(uvm_object rhs);
            memory_transaction tx;
            $cast(tx, rhs);
            wr_en = tx.wr_en;
            rd_en = tx.rd_en;
            addr = tx.addr;
            data_in = tx.data_in;
            data_out=tx.data_out;
        endfunction

        // Compare transaction data:
        function bit do_compare(uvm_object rhs, uvm_comparer comparer);
            memory_transaction tx;
            bit status = 1;
            $cast(tx, rhs);
            // Checking that everything matches
            status &= (wr_en == tx.wr_en);
            status &= (rd_en == tx.rd_en);
            status &= (addr == tx.addr);
            status &= (data_in == tx.data_in);
            return status;
        endfunction
    endclass: memory_transaction

    typedef uvm_sequencer #(memory_transaction) memory_sequencer;

	class memory_sequence extends uvm_sequence #(memory_transaction);

        `uvm_object_utils(memory_sequence)

        function new (string name = "");
            super.new(name);
        endfunction

        // Body task:
        task body;
            if (starting_phase != null) 
                starting_phase.raise_objection(this);
            
                
            // Create n transactions
            repeat(1000)
            begin
                req = memory_transaction::type_id::create("req");
                start_item(req);

                if (!req.randomize()) 
                    `uvm_error("", "Randomize Failed")
                

                finish_item(req);
            end

            if (starting_phase != null) 
                starting_phase.drop_objection(this);
            
        endtask
    endclass: memory_sequence

    class memory_driver extends uvm_driver #(memory_transaction);
        `uvm_component_utils(memory_driver)

        // Virtual, replacable interface
        virtual dut_if dut_virt;

        // Constructor:
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        ////////////////////////////
        // Build Phase
        ////////////////////////////
        function void build_phase(uvm_phase phase);
            if (!uvm_config_db #(virtual dut_if)::get(this, "", "dut_if", dut_virt))
                `uvm_error("", "uvm_config_db::get failed")
        endfunction

        ////////////////////////////
        // Run Phase
        ////////////////////////////
        task run_phase(uvm_phase phase);
            // Apply reset:
            dut_virt.rst_n = 0;
            repeat(5) @(posedge dut_virt.clk);
            dut_virt.rst_n = 1;
            @(posedge dut_virt.clk);

            // begin processing:

            forever begin
                // Send random values to DUT on clock edges?
                // seq_item_port, req -- built into UVM driver base class, we're extending
                seq_item_port.get_next_item(req); // blocking call

                // Wiggles pins on the DUT
                @(posedge dut_virt.clk);
                dut_virt.wr_en   = req.wr_en;
                dut_virt.rd_en   = req.rd_en;
                dut_virt.addr    = req.addr;
                dut_virt.data_in = req.data_in;

                seq_item_port.item_done();
            end
        endtask
    endclass: memory_driver

    class memory_monitor extends uvm_component;
        `uvm_component_utils(memory_monitor)

        virtual dut_if vif;
        uvm_analysis_port #(memory_transaction) ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            if (!uvm_config_db #(virtual dut_if)::get(this, "", "dut_if", vif))
                `uvm_fatal("MON", "Failed to get interface")
        endfunction

        task run_phase(uvm_phase phase);
            memory_transaction tx;
            forever begin
                @(posedge vif.clk);
                
                    tx = memory_transaction::type_id::create("tx");
                    tx.rd_en = vif.rd_en;
                    tx.addr = vif.addr;
                    tx.data_in = vif.data_in;
                    tx.wr_en = vif.wr_en;
                    tx.data_out = vif.data_out;
                  	//`uvm_info("MONITOR", $sformatf("Observed WRITE: %0h -> addr %0d", tx.data_in, tx.addr), UVM_MEDIUM)
                    // Capture output here if needed (from top-level output)
                    ap.write(tx);
                //end
                
            end
        endtask
    endclass:memory_monitor

    class memory_scoreboard extends uvm_component;
      `uvm_component_utils(memory_scoreboard)

      uvm_analysis_imp #(memory_transaction, memory_scoreboard) analysis_export;

      bit [31:0] expected_mem [int]; 

      function new(string name, uvm_component parent);
          super.new(name, parent);
          analysis_export = new("analysis_export", this);
      endfunction

      virtual function void write(memory_transaction tx);
          if (tx.wr_en) begin
            //`uvm_info("SCOREBOARD", $sformatf("Writing %0h @ %0d", tx.data_in, tx.addr), UVM_MEDIUM)
              expected_mem[tx.addr] = tx.data_in;
          end else if (tx.rd_en) begin
              if (expected_mem.exists(tx.addr)) begin
                `uvm_info("SCOREBOARD", $sformatf("SUCCESS: Read @ %0h, expected: %0h", tx.data_out, expected_mem[tx.addr]), UVM_MEDIUM)
              end 
              else if (tx.data_out != expected_mem[tx.addr]) begin
              `uvm_error("SCOREBOARD", $sformatf("FAIL: Read @ %0h, expected: %0h", tx.data_out, expected_mem[tx.addr]))
              end
            
              else begin
                `uvm_info("SCOREBOARD", $sformatf("No value written to addr %0d yet", tx.addr), UVM_MEDIUM)
              end
          end
      endfunction
  endclass: memory_scoreboard
          
    class memory_env extends uvm_env;
        // Register class 
        `uvm_component_utils(memory_env);

        // Components
        memory_sequencer m_sequencer;
        memory_driver m_driver;
        memory_monitor m_monitor;
        memory_scoreboard m_scoreboard;
        
        // Constructor
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        ////////////////////////////
        // Build Phase
        ////////////////////////////
        function void build_phase(uvm_phase phase);
            m_sequencer = memory_sequencer::type_id::create("m_sequencer", this);
            m_driver = memory_driver::type_id::create("m_driver", this);
            m_monitor = memory_monitor::type_id::create("m_monitor", this);
            m_scoreboard = memory_scoreboard::type_id::create("m_scoreboard", this);
        endfunction

        ////////////////////////////
        // Connect Phase
        ////////////////////////////
        function void connect_phase(uvm_phase phase);
            // Connect the driver port to the sequencer export (where it sends its data from)
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
            // Connect monitor to analysis port:
            m_monitor.ap.connect(m_scoreboard.analysis_export);
        endfunction

    endclass: memory_env


    class memory_test extends uvm_test;
        // Register test with UVM
        `uvm_component_utils(memory_test)

        // Environment object attribute
        memory_env m_env;

        // Constructor
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        ////////////////////////////
        // Build Phase
        ////////////////////////////
        function void build_phase(uvm_phase phase);
            // create environment:
            m_env = memory_env::type_id::create("m_env", this);
        endfunction

        ////////////////////////////
        // Run Phase
        ////////////////////////////
        task run_phase(uvm_phase phase);
            // Signal to start test
            // phase.raise_objection(this);
            // // Generate stimuli here:
            // // TO DO
            // #1000
            // phase.drop_objection(this);
            memory_sequence seq;
            seq = memory_sequence::type_id::create("seq");
            if (!seq.randomize()) 
                `uvm_error("", "Randomize failed")

            seq.starting_phase = phase;
            seq.start(m_env.m_sequencer);

        endtask
    endclass: memory_test

endpackage: memory_pkg



module top;
    import uvm_pkg::*;
    import memory_pkg::*;

    dut_if dut_if1();
    //logic [31:0] data_out_wire;
    
    memory dut(
        .clk(dut_if1.clk),
        .rst_n(dut_if1.rst_n),
        .wr_en(dut_if1.wr_en),
        .rd_en(dut_if1.rd_en),
        .addr(dut_if1.addr),
        .data_in(dut_if1.data_in),
        .data_out(dut_if1.data_out)
    );
  
    // Clk_gen:
    initial begin
        dut_if1.clk = 0;
        forever #5 dut_if1.clk = ~dut_if1.clk;
    end

    initial begin
        uvm_config_db #(virtual dut_if)::set(null, "*", "dut_if", dut_if1);
        uvm_top.finish_on_completion = 1;
        run_test("memory_test");
        #100
        #10 $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top);
    end

endmodule: top
