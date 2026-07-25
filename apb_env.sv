`include "apb_defines.svh"

class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)

    apb_agent              agent;
    apb_reference_model    ref_mod;
    apb_scoreboard         scb;
    apb_virtual_sequencer  vsqr;

    function new(string name="apb_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent   = apb_agent::type_id::create("agent", this);
        ref_mod = apb_reference_model::type_id::create("ref_mod", this);
        scb     = apb_scoreboard::type_id::create("scb", this);
        vsqr    = apb_virtual_sequencer::type_id::create("vsqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.mon.item_collector_port.connect(ref_mod.item_export);
        agent.mon.read_collector_port.connect(scb.act_fifo.analysis_export);
        ref_mod.exp_port.connect(scb.exp_fifo.analysis_export);
        agent.mon.reset_ap.connect(ref_mod.reset_export);
        agent.mon.reset_ap.connect(scb.reset_export);
        vsqr.apb_sqr = agent.sqr;
    endfunction
endclass
