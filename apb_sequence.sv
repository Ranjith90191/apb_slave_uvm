`include "apb_defines.svh"

class apb_base_sequence extends uvm_sequence #(apb_sequence_item);
    `uvm_object_utils(apb_base_sequence)

    rand int unsigned num_transactions = 10;
    constraint reasonable_len { num_transactions inside {[1:200]}; }

    function new(string name="apb_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("SEQ", $sformatf("Generating %0d transactions", num_transactions), UVM_LOW)
        repeat (num_transactions) begin
            req = apb_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize())
                `uvm_fatal("SEQ", "Randomization failed!")
            finish_item(req);
        end
    endtask
endclass

class apb_write_read_sequence extends uvm_sequence #(apb_sequence_item);
    `uvm_object_utils(apb_write_read_sequence)

    rand bit [`ADDR_WIDTH-1:0] addr;
    rand bit [`DATA_WIDTH-1:0] data;

    constraint addr_c { addr inside {[0:`MEM_DEPTH-1]}; }

    function new(string name="apb_write_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
        req = apb_sequence_item::type_id::create("req");
        start_item(req);
        if (!req.randomize() with { PADDR == local::addr; PWRITE == 1'b1; PWDATA == local::data; PSTRB == '1; })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(req);
        req = apb_sequence_item::type_id::create("req");
        start_item(req);
        if (!req.randomize() with { PADDR == local::addr; PWRITE == 1'b0; })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(req);
    endtask
endclass
