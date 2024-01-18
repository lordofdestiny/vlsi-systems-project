module top
#(
    parameter DIVISOR = 50_000_00,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16 
) (
    
);
    reg clk, rst_n;

    wire cpu_mem_we_out;
    wire [ADDR_WIDTH-1:0] cpu_mem_addr_out;
    wire [DATA_WIDTH-1:0] cpu_mem_data_out;
    wire [DATA_WIDTH-1:0] cpu_mem_data_in;

    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cpu0 (
        .clk(clk), .rst_n(rst_n),
        .mem_in(cpu_mem_data_in),
        .mem_we(cpu_mem_we_out),
        .mem_addr(cpu_mem_addr_out),
        .mem_data(cpu_mem_data_out),
        .in(),
        .out(),
        .pc(),
        .sp()
    );

    memory #(
        .FILE_NAME(FILE_NAME),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    )  memory0 (
        .clk(clk),
        .we(cpu_mem_we_out),
        .addr(cpu_mem_addr_out),
        .data(cpu_mem_data_out),
        .out(cpu_mem_data_in)
    );

    initial begin
        $readmemh("./init_memory.hex", memory0.mem);

        clk = 0;
        rst_n = 0;
        #2 rst_n = 1;
    end

    always #5 clk = ~clk;
endmodule