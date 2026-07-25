
`include "apb_defines.svh"

module tb_top;
    import uvm_pkg::*;
    import apb_pkg::*;

    logic PCLK;
    logic PRESETn;

    always #5 PCLK = ~PCLK;

    initial begin
        PCLK    = 0;
        PRESETn = 0;
        #20;
        PRESETn = 1;
    end

    apb_if vif(PCLK);
    assign vif.PRESETn = PRESETn;

    apb_slave #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH),
        .MEM_DEPTH(`MEM_DEPTH)
    ) dut (
        .PCLK    (PCLK),
        .PRESETn (vif.PRESETn),
        .PADDR   (vif.PADDR),
        .PSEL    (vif.PSEL),
        .PENABLE (vif.PENABLE),
        .PWRITE  (vif.PWRITE),
        .PWDATA  (vif.PWDATA),
        .PSTRB   (vif.PSTRB),
        .PRDATA  (vif.PRDATA),
        .PREADY  (vif.PREADY),
        .PSLVERR (vif.PSLVERR)
    );

    initial begin
        uvm_config_db #(virtual apb_if)::set(null, "uvm_test_top.*", "vif", vif);
        run_test();   // pick +UVM_TESTNAME=apb_test or apb_reset_test at invocation
    end
endmodule
