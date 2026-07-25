class apb_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(apb_virtual_sequencer)

    apb_sequencer   apb_sqr;
    virtual apb_if  vif;

    function new(string name="apb_virtual_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
