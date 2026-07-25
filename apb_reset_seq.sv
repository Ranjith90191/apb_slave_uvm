//==============================================================================
// File: apb_reset_seq.sv
// Drives PRESETn directly via the virtual interface handle. This is NOT a
// uvm_sequence #(apb_sequence_item) ? it never touches the data sequencer,
// it manipulates the reset wire directly, exactly as tb_top's initial block
// does for power-on reset. This gives us randomizable, reusable mid-test
// reset events instead of a one-shot reset only at time 0.
//==============================================================================
class apb_reset_seq extends uvm_sequence;
    `uvm_object_utils(apb_reset_seq)

    virtual apb_if vif;
    rand int unsigned pulse_cycles;
    constraint pulse_c { pulse_cycles inside {[2:8]}; }

    function new(string name="apb_reset_seq");
        super.new(name);
    endfunction

    virtual task body();
        if (vif == null)
            `uvm_fatal("RST_SEQ", "vif not set on apb_reset_seq")

        `uvm_info("RST_SEQ", $sformatf("Asserting PRESETn for %0d cycles", pulse_cycles), UVM_LOW)
        @(posedge vif.PCLK);
        vif.PRESETn <= 1'b0;
        repeat (pulse_cycles) @(posedge vif.PCLK);
        vif.PRESETn <= 1'b1;
        @(posedge vif.PCLK);
        `uvm_info("RST_SEQ", "PRESETn de-asserted", UVM_LOW)
    endtask
endclass
