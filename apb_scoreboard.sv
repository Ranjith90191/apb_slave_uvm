`include "apb_defines.svh"
`uvm_analysis_imp_decl(_rst)

class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)

    uvm_tlm_analysis_fifo #(apb_sequence_item) exp_fifo;
    uvm_tlm_analysis_fifo #(apb_sequence_item) act_fifo;
    uvm_analysis_imp_rst #(bit, apb_scoreboard) reset_export;

    int unsigned match_count;
    int unsigned mismatch_count;
    int file_handle;

    function new(string name="apb_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        exp_fifo     = new("exp_fifo", this);
        act_fifo     = new("act_fifo", this);
        reset_export = new("reset_export", this);

        file_handle = $fopen("reports.txt", "w");
        if (file_handle == 0)
            `uvm_fatal("SCB", "[SCOREBOARD] Failed to open reports.txt for writing!")

        $fdisplay(file_handle, "=========================================================================================================");
        $fdisplay(file_handle, "                                        APB TRANSACTION REPORT                                           ");
        $fdisplay(file_handle, "=========================================================================================================");
        $fdisplay(file_handle, " TIME       | STATUS | OP    | ADDR | PSTRB | PWDATA   | PRDATA (EXP / ACT)    | PSLVERR (EXP / ACT) ");
        $fdisplay(file_handle, "---------------------------------------------------------------------------------------------------------");
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_sequence_item exp_pkt, act_pkt;
        forever begin
            exp_fifo.get(exp_pkt);
            act_fifo.get(act_pkt);
            compare(exp_pkt, act_pkt);
        end
    endtask

    virtual function void compare(apb_sequence_item exp_pkt, apb_sequence_item act_pkt);
        string status, op_type;

        op_type = act_pkt.PWRITE ? "WRITE" : "READ ";

        if (exp_pkt.PADDR !== act_pkt.PADDR) begin
            `uvm_error("SCB", $sformatf("ADDR MISMATCH: exp=0x%0h act=0x%0h",
                       exp_pkt.PADDR, act_pkt.PADDR))
            status = "[FAIL]";
            mismatch_count++;
        end
        else if (exp_pkt.PRDATA !== act_pkt.PRDATA) begin
            `uvm_error("SCB", $sformatf("DATA MISMATCH @0x%0h: exp=0x%0h act=0x%0h",
                       exp_pkt.PADDR, exp_pkt.PRDATA, act_pkt.PRDATA))
            status = "[FAIL]";
            mismatch_count++;
        end
        else if (exp_pkt.PSLVERR !== act_pkt.PSLVERR) begin
            `uvm_error("SCB", $sformatf("PSLVERR MISMATCH @0x%0h: exp=0x%0h act=0x%0h",
                       exp_pkt.PADDR, exp_pkt.PSLVERR, act_pkt.PSLVERR))
            status = "[FAIL]";
            mismatch_count++;
        end
        else begin
            `uvm_info("SCB", $sformatf("MATCH @0x%0h: data=0x%0h",
                      act_pkt.PADDR, act_pkt.PRDATA), UVM_HIGH)
            status = "[PASS]";
            match_count++;
        end

        $fdisplay(file_handle, " %-10t | %s | %s | %4d |  %4b  | %8h | %8h / %8h |      %b / %b",
                  $time,
                  status,
                  op_type,
                  act_pkt.PADDR,
                  act_pkt.PSTRB,
                  act_pkt.PWDATA,
                  exp_pkt.PRDATA, act_pkt.PRDATA,
                  exp_pkt.PSLVERR, act_pkt.PSLVERR);
    endfunction

    virtual function void write_rst(bit val);
        apb_sequence_item tmp;
        if (val == 1'b0) begin
            `uvm_info("SCB", "Reset seen - flushing exp_fifo/act_fifo", UVM_LOW)
            while (exp_fifo.try_get(tmp));
            while (act_fifo.try_get(tmp));
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCB", $sformatf("Result: %0d match(es), %0d mismatch(es)",
                  match_count, mismatch_count), UVM_NONE)
        if (mismatch_count == 0 && match_count > 0)
            `uvm_info("SCB", "TEST PASSED", UVM_NONE)
        else
            `uvm_error("SCB", "TEST FAILED")

        $fdisplay(file_handle, "=========================================================================================================");
        $fdisplay(file_handle, "                                  APB SCOREBOARD FINAL REPORT                                            ");
        $fdisplay(file_handle, "=========================================================================================================");
        $fdisplay(file_handle, " Total Passed : %0d", match_count);
        $fdisplay(file_handle, " Total Failed : %0d", mismatch_count);
        $fdisplay(file_handle, "=========================================================================================================");
        $fclose(file_handle);
    endfunction
endclass