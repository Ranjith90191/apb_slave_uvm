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
        bit addr_valid;

        addr_valid = (t.PADDR < `MEM_DEPTH);

        exp_pkt = apb_sequence_item::type_id::create("exp_pkt");
        exp_pkt.copy(t);

        if (t.PWRITE) begin
            if (addr_valid) begin
                for (int i = 0; i < `NUM_BYTES; i++) begin
                    if (t.PSTRB[i])
                        shadow_mem[t.PADDR][i*8 +: 8] = t.PWDATA[i*8 +: 8];
                end
                exp_pkt.PSLVERR = 1'b0;
                `uvm_info("REF_MOD", $sformatf("WRITE PREDICT: shadow[0x%0h]=0x%0h (PSTRB=0x%0h)",
                          t.PADDR, shadow_mem[t.PADDR], t.PSTRB), UVM_HIGH)
            end
            else begin
                // Out-of-range write: DUT's write block gates on addr_valid, so
                // memory is NOT touched. PSLVERR asserts.
                exp_pkt.PSLVERR = 1'b1;
                `uvm_info("REF_MOD", $sformatf("WRITE OUT-OF-RANGE @0x%0h -> PSLVERR expected, memory unaffected",
                          t.PADDR), UVM_HIGH)
            end

            // PRDATA holds its last value on ANY write (in-range or out-of-range) ?
            // the DUT's read block only branches on read_enable, so a write cycle
            // never touches PRDATA at all; it simply retains whatever it was.
            exp_pkt.PRDATA = last_PRDATA;
        end
        else begin
            if (addr_valid) begin
                exp_pkt.PRDATA  = shadow_mem.exists(t.PADDR) ? shadow_mem[t.PADDR] : '0;
                exp_pkt.PSLVERR = 1'b0;
                `uvm_info("REF_MOD", $sformatf("READ PREDICT: expected 0x%0h @0x%0h",
                          exp_pkt.PRDATA, t.PADDR), UVM_HIGH)
            end
            else begin
                exp_pkt.PRDATA  = {`DATA_WIDTH{1'b1}};
                exp_pkt.PSLVERR = 1'b1;
                `uvm_info("REF_MOD", $sformatf("READ OUT-OF-RANGE @0x%0h -> expect PRDATA=all-1s, PSLVERR=1",
                          t.PADDR), UVM_HIGH)
            end
            // Whatever this read produced becomes the new "held" value for
            // subsequent writes to predict against.
            last_PRDATA = exp_pkt.PRDATA;
        end

        exp_port.write(exp_pkt);
    endfunction

    virtual function void write_reset(bit val);
        if (val == 1'b0) begin
            `uvm_info("REF_MOD", "Reset seen - clearing shadow memory", UVM_LOW)
            shadow_mem.delete();
            last_PRDATA = '0;   // DUT's PRDATA register clears to 0 on reset too
        end
    endfunction
endclass
