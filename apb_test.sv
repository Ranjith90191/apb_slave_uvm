
class apb_test extends uvm_test;
    `uvm_component_utils(apb_test)

    apb_env env;

    function new(string name="apb_test", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_base_sequence seq;
        phase.raise_objection(this);

        seq = apb_base_sequence::type_id::create("seq");
        `uvm_info("TEST", "Starting APB Base Sequence...", UVM_LOW)
        seq.start(env.agent.sqr);
        #100ns;
        `uvm_info("TEST", "APB Base Sequence completed successfully!", UVM_LOW)

        phase.drop_objection(this);
    endtask
endclass


class apb_reset_test extends apb_test;
    `uvm_component_utils(apb_reset_test)

    function new(string name="apb_reset_test", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_base_sequence seq1, seq2;
        apb_reset_seq     rst;

        phase.raise_objection(this);

        env.vsqr.vif = env.agent.drv.vif;   // share vif for direct reset drive

        seq1 = apb_base_sequence::type_id::create("seq1");
        seq1.num_transactions = 8;
        `uvm_info("TEST", "Phase 1: traffic before reset", UVM_LOW)
        seq1.start(env.agent.sqr);

        rst = apb_reset_seq::type_id::create("rst");
        rst.vif = env.vsqr.vif;
        if (!rst.randomize())
            `uvm_fatal("TEST", "reset seq randomization failed")
        `uvm_info("TEST", "Phase 2: mid-test reset injection", UVM_LOW)
        rst.start(env.vsqr);

        seq2 = apb_base_sequence::type_id::create("seq2");
        seq2.num_transactions = 8;
        `uvm_info("TEST", "Phase 3: traffic after reset", UVM_LOW)
        seq2.start(env.agent.sqr);

        #100ns;
        phase.drop_objection(this);
    endtask
endclass
