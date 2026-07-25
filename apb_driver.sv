`include "apb_defines.svh"

class apb_driver extends uvm_driver #(apb_sequence_item);
    `uvm_component_utils(apb_driver)

    virtual apb_if vif;

    function new(string name="apb_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Could not get virtual interface! Did you set it in tb_top?")
    endfunction

    virtual task run_phase(uvm_phase phase);
        drive_idle();
        wait (vif.PRESETn == 1'b1);

        fork
            drive_loop();
            reset_watcher();
        join_none
    endtask

    virtual task drive_idle();
        vif.DRV_cb.PSEL    <= 1'b0;
        vif.DRV_cb.PENABLE <= 1'b0;
        vif.DRV_cb.PADDR   <= '0;
        vif.DRV_cb.PWRITE  <= 1'b0;
        vif.DRV_cb.PWDATA  <= '0;
        vif.DRV_cb.PSTRB   <= '0;
    endtask

    virtual task drive_loop();
        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_transfer(apb_sequence_item req);
        @(vif.DRV_cb);
        vif.DRV_cb.PSEL    <= 1'b1;
        vif.DRV_cb.PENABLE <= 1'b0;
        vif.DRV_cb.PADDR   <= req.PADDR;
        vif.DRV_cb.PWRITE  <= req.PWRITE;

        if (req.PWRITE) begin
            vif.DRV_cb.PWDATA <= req.PWDATA;
            vif.DRV_cb.PSTRB  <= req.PSTRB;
        end else begin
            vif.DRV_cb.PSTRB <= '0;
        end

        @(vif.DRV_cb);
        vif.DRV_cb.PENABLE <= 1'b1;
        do begin
            @(vif.DRV_cb);
        end while (vif.DRV_cb.PREADY !== 1'b1);

        vif.DRV_cb.PSEL    <= 1'b0;
        vif.DRV_cb.PENABLE <= 1'b0;
    endtask

    virtual task reset_watcher();
        forever begin
            @(negedge vif.PRESETn);
            `uvm_info("DRV", "Reset detected mid-run ? aborting in-flight transfer", UVM_LOW)
            disable drive_loop;
            drive_idle();

            @(posedge vif.PRESETn);
            `uvm_info("DRV", "Reset released ? resuming drive_loop", UVM_LOW)
            fork
                drive_loop();
            join_none
        end
    endtask
endclass
