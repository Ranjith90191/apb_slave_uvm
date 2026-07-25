`include "apb_defines.svh"

interface apb_if(input logic PCLK);
    logic PRESETn;
    logic [`ADDR_WIDTH-1:0] PADDR;
    logic PSEL;
    logic PENABLE;
    logic PWRITE;
    logic [`DATA_WIDTH-1:0] PWDATA;
    logic [`NUM_BYTES-1:0]  PSTRB;
    logic [`DATA_WIDTH-1:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

    clocking DRV_cb @(posedge PCLK);
        default input #1ns output #1ns;
        output PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB;
        input  PRDATA, PREADY, PSLVERR;
    endclocking

    clocking MON_cb @(posedge PCLK);
        default input #2ns output #2ns;
        input PRESETn, PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB;
        input PRDATA, PREADY, PSLVERR;
    endclocking

    modport DRIVER  (clocking DRV_cb, input PCLK, PRESETn);
    modport MONITOR (clocking MON_cb, input PCLK);
endinterface
