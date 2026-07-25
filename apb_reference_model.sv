
`include "apb_defines.svh"

`uvm_analysis_imp_decl(_item)
`uvm_analysis_imp_decl(_reset)

class apb_reference_model extends uvm_component;
    `uvm_component_utils(apb_reference_model)

    uvm_analysis_imp_item #(apb_sequence_item, apb_reference_model) item_export;
    uvm_analysis_imp_reset #(bit, apb_reference_model)              reset_export;
    uvm_analysis_port #(apb_sequence_item)                          exp_port;

    bit [`DATA_WIDTH-1:0] shadow_mem[int];
    bit [`DATA_WIDTH-1:0] last_PRDATA;

    function new(string name="apb_reference_model", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_export  = new("item_export", this);
        reset_export = new("reset_export", this);
        exp_port     = new("exp_port", this);
    endfunction

    virtual function void write_item(apb_sequence_item t);
        apb_sequence_item exp_pkt;
        if (t.PWRITE) begin
            for (int i = 0; i < `NUM_BYTES; i++)begin
                if (t.PSTRB[i])begin
                    shadow_mem[t.PADDR][i*8 +: 8] = t.PWDATA[i*8 +: 8];
            `uvm_info("REF_MOD", $sformatf("WRITE PREDICT: shadow[0x%0h]=0x%0h (PSTRB=0x%0h)",
                      t.PADDR, shadow_mem[t.PADDR], t.PSTRB), UVM_HIGH)
                      end
            end
            exp_pkt = apb_sequence_item::type_id::create("exp_pkt");
            exp_pkt.copy(t);
            exp_pkt.PRDATA = last_PRDATA;
            exp_port.write(exp_pkt);
        end
        else begin
            exp_pkt = apb_sequence_item::type_id::create("exp_pkt");
            exp_pkt.copy(t);
            exp_pkt.PRDATA = shadow_mem[t.PADDR];
            last_PRDATA = shadow_mem[t.PADDR];
            `uvm_info("REF_MOD", $sformatf("READ PREDICT: expected 0x%0h @0x%0h",
                      exp_pkt.PRDATA, t.PADDR), UVM_HIGH)
            exp_port.write(exp_pkt);
        end
    endfunction

    virtual function void write_reset(bit val);
        if (val == 1'b0) begin
            `uvm_info("REF_MOD", "Reset seen ? clearing shadow memory", UVM_LOW)
            shadow_mem.delete();
        end
    endfunction
endclass
