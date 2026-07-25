
`include "apb_defines.svh"

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_driver    drv;
    apb_monitor   mon;
    apb_sequencer sqr;

    function new(string name="apb_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = apb_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv = apb_driver::type_id::create("drv", this);
            sqr = apb_sequencer::type_id::create("sqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass
