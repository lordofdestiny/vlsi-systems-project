module top
#(
    parameter DIVISOR = 50_000_00,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16 
) (
    input clk,
    input rst_n,
    input[2:0] btn,
    input [9:0] sw,
    output [9:0] led,
    output [27:0] hex
);
    wire clk_div;
    clk_div #(
        .DIVISOR(1)
    ) clk_div0(
        .clk(clk),
        .rst_n(rst_n),
        .out(clk_div)
    );

    wire cpu_mem_we_out;
    wire [ADDR_WIDTH-1:0] cpu_mem_addr_out;
    wire [DATA_WIDTH-1:0] cpu_mem_data_out;
    wire [DATA_WIDTH-1:0] cpu_mem_data_in;
    wire [DATA_WIDTH-1:0] cpu_out;
    wire [ADDR_WIDTH-1:0] cpu_pc_out;
    wire [ADDR_WIDTH-1:0] cpu_sp_out;

    // red i debounce vrv...
    wire [DATA_WIDTH-1:0] cpu_in;


    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cpu0 (
        .clk(clk_div), .rst_n(rst_n),
        .mem_in(cpu_mem_data_in),
        .mem_we(cpu_mem_we_out),
        .mem_addr(cpu_mem_addr_out),
        .mem_data(cpu_mem_data_out),
        .in(sw[3:0]),
        .out(led[4:0]),
        .pc(cpu_pc_out),
        .sp(cpu_sp_out)
    );

    wire [3:0] sp_tens, sp_ones;
    bcd bcd_sp(
        .in(cpu_sp_out),
        .ones(sp_ones),
        .tens(sp_tens)
    );
    ssd ssd_sp_tens(
        .in(sp_tens), .out(hex[27:21])
    );
    ssd ssd_sp_ones(
        .in(sp_ones), .out(hex[20:14])
    );

    wire [3:0] pc_tens, pc_ones;
    bcd bcd_pc(
        .in(cpu_pc_out),
        .ones(pc_ones),
        .tens(pc_tens)
    );
    ssd ssd_pc_tens(
        .in(pc_tens), .out(hex[13:7])
    );
    ssd ssd_pc_ones(
        .in(pc_ones), .out(hex[6:0])
    );

    memory #(
        .FILE_NAME(FILE_NAME),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    )  memory0 (
        .clk(clk_div),
        .we(cpu_mem_we_out),
        .addr(cpu_mem_addr_out),
        .data(cpu_mem_data_out),
        .out(cpu_mem_data_in)
    );
    
endmodule