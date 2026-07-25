`include "apb_defines.svh"

class apb_sequence_item extends uvm_sequence_item;

    rand bit [`ADDR_WIDTH-1:0] PADDR;
    rand bit                   PWRITE;
    rand bit [`DATA_WIDTH-1:0] PWDATA;
    rand bit [`NUM_BYTES-1:0]  PSTRB;
    bit [`DATA_WIDTH-1:0]      PRDATA;
    bit                        PSLVERR;

    `uvm_object_utils_begin(apb_sequence_item)
        `uvm_field_int(PADDR,   UVM_ALL_ON)
        `uvm_field_int(PWRITE,  UVM_ALL_ON)
        `uvm_field_int(PWDATA,  UVM_ALL_ON)
        `uvm_field_int(PSTRB,   UVM_ALL_ON)
        `uvm_field_int(PRDATA,  UVM_ALL_ON)
        `uvm_field_int(PSLVERR, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="apb_sequence_item");
        super.new(name);
    endfunction

    constraint PADDR_range {
        PADDR inside {[0 : `MEM_DEPTH-1]};
    }

    constraint PSTRB_dist {
        PSTRB dist { '1 := 7, [1:'1] :/ 3 };
    }
endclass
