module top
#(
    parameter DIVISOR = 50_000_00,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16 
) (
);
    reg clk;
    reg rst_n;
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

    reg [DATA_WIDTH-1:0] cpu_in_test;

    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cpu0 (
        .clk(clk_div), .rst_n(rst_n),
        .mem_in(cpu_mem_data_in),
        .mem_we(cpu_mem_we_out),
        .mem_addr(cpu_mem_addr_out),
        .mem_data(cpu_mem_data_out),
        .in(cpu_in_test),
        .out(cpu_out),
        .pc(),
        .sp()
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

    always @(*) begin
        $display("%4t -> CPU_OUT = %4h", $time, cpu_out);
    end

    initial begin
        $readmemh("./init_memory.hex", memory0.mem);
        $monitor("%4t -> mem[1] = %4h; mem[2] = %4h; mem[3] = %4h; mem[4] = %4h; mem[5] = %4h",
            $time, memory0.mem[1], memory0.mem[2], memory0.mem[3], memory0.mem[4], memory0.mem[5]);
        
        clk = 0;
        rst_n = 0;
        cpu_in_test = 16'd8;
        #2 rst_n = 1;
    
        #500 cpu_in_test = 16'd9;
        #250 cpu_in_test = 16'd3;
    end

    always #5 clk = ~clk;
    
endmodule