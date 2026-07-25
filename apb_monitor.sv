`include "apb_defines.svh"

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    uvm_analysis_port #(apb_sequence_item) input_collector_port;
    uvm_analysis_port #(apb_sequence_item) output_collector_port;
    uvm_analysis_port #(bit)               reset_ap;

    virtual apb_if vif;

    function new(string name="apb_monitor", uvm_component parent);
        super.new(name, parent);
        input_collector_port = new("input_collector_port", this);
        output_collector_port = new("output_collector_port", this);
        reset_ap             = new("reset_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Could not get virtual interface!")
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            collect_transfers();
            watch_reset();
        join_none
    endtask

    virtual task collect_transfers();
    apb_sequence_item pkt;
    forever begin
        @(vif.MON_cb);
        if (!vif.MON_cb.PRESETn) begin
            wait (vif.MON_cb.PRESETn == 1'b1);
            continue;
        end

        if (vif.MON_cb.PSEL && vif.MON_cb.PENABLE && vif.MON_cb.PREADY) begin
            pkt = apb_sequence_item::type_id::create("pkt");
            pkt.PADDR   = vif.MON_cb.PADDR;
            pkt.PWRITE  = vif.MON_cb.PWRITE;
            pkt.PWDATA  = vif.MON_cb.PWDATA;
            pkt.PSTRB   = vif.MON_cb.PSTRB;
            pkt.PSLVERR = vif.MON_cb.PSLVERR;
            input_collector_port.write(pkt);

            //if (pkt.PWRITE) begin
                //item_collector_port.write(pkt);
            //end
            //else begin
            
            @(vif.MON_cb);
                pkt.PRDATA = vif.MON_cb.PRDATA;

                `uvm_info("MON", $sformatf("READ  Addr=0x%0h Data=0x%0h SLVERR=%0b",
                          pkt.PADDR, pkt.PRDATA, pkt.PSLVERR), UVM_HIGH)
            output_collector_port.write(pkt);
                //read_collector_port.write(pkt);
            //end
        end
    end
endtask

    virtual task watch_reset();
        forever begin
            @(negedge vif.PRESETn);
            `uvm_info("MON", "Reset asserted", UVM_MEDIUM)
            reset_ap.write(1'b0);
            @(posedge vif.PRESETn);
            `uvm_info("MON", "Reset released", UVM_MEDIUM)
            reset_ap.write(1'b1);
        end
    endtask
endclass
