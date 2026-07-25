// Code your design here
//==============================================================================
// APB Slave with Internal Memory
// Description: General APB slave module with configurable data and address width
// Features: Read/Write operations, PSTRB support, configurable memory depth
//==============================================================================

module apb_slave #(
    parameter ADDR_WIDTH = 9,      // Address bus width
    parameter DATA_WIDTH = 32,     // Data bus width
    parameter MEM_DEPTH  = 256     // Memory depth (number of locations)
)(
    // APB Global Signals
    input  wire                    PCLK,       // Clock
    input  wire                    PRESETn,    // Active-low reset
    // APB Slave Signals
    input  wire [ADDR_WIDTH-1:0]   PADDR,      // Address
    input  wire                    PSEL,       // Slave select
    input  wire                    PENABLE,    // Enable
    input  wire                    PWRITE,     // Write control (1=Write, 0=Read)
    input  wire [DATA_WIDTH-1:0]   PWDATA,     // Write data
    input  wire [DATA_WIDTH/8-1:0] PSTRB,      // Write strobe (byte enables)
    output reg  [DATA_WIDTH-1:0]   PRDATA,     // Read data
    output wire                    PREADY,     // Ready signal
    output wire                    PSLVERR     // Error signal
);

    //==========================================================================
    // Local Parameters
    //==========================================================================
    localparam BYTE_WIDTH = 8;
    localparam NUM_BYTES  = DATA_WIDTH / BYTE_WIDTH;
    //==========================================================================
    // Internal Memory Declaration
    //==========================================================================
    reg [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];
    //==========================================================================
    // Internal Signals
    //==========================================================================
    wire transfer;          // Valid APB transfer
    wire write_enable;      // Write enable signal
    wire read_enable;       // Read enable signal
    wire addr_valid;        // Address within valid range
    integer i;              // Loop variable
    //==========================================================================
    // APB Transfer Detection
    //==========================================================================
    // Transfer occurs when slave is selected and enabled
    assign transfer = PSEL & PENABLE;
    // Write enable: transfer is happening and it's a write operation
    assign write_enable = transfer & PWRITE;
    // Read enable: transfer is happening and it's a read operation
    assign read_enable = transfer & ~PWRITE;
    // Check if address is within valid memory range
    assign addr_valid = (PADDR < MEM_DEPTH);
    //==========================================================================
    // APB Ready and Error Signals
    //==========================================================================
    // Always ready (single cycle access)
    // For multi-cycle access, implement wait states here
    assign PREADY = 1'b1;
    // Generate error if address is out of range during a valid transfer
    assign PSLVERR = transfer & ~addr_valid;
    //==========================================================================
    // Write Operation with Byte Strobes
    //==========================================================================
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            // Initialize memory to zero on reset
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                memory[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            if (write_enable && addr_valid) begin
                // Write data based on byte strobes
                for (i = 0; i < NUM_BYTES; i = i + 1) begin
                    if (PSTRB[i]) begin
                        memory[PADDR][i*BYTE_WIDTH +: BYTE_WIDTH] <= PWDATA[i*BYTE_WIDTH +: BYTE_WIDTH];
                    end
                end
             $display(" MEM[%0d] <= 0x%0h", PADDR, PWDATA);
            end
        end
    end
    //==========================================================================
    // Read Operation
    //==========================================================================
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= {DATA_WIDTH{1'b0}};
        end
        else begin
            if (read_enable && addr_valid) begin
                PRDATA <= memory[PADDR];
            end
            else if (read_enable && ~addr_valid) begin
                // Return error pattern for out-of-range access
                PRDATA <= {DATA_WIDTH{1'b1}};  // All 1's for error
            end
            else begin
                PRDATA <= {DATA_WIDTH{1'b0}};
            end
        end
    end

endmodule
