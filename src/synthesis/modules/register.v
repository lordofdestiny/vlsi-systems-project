module register
#(
    parameter DATA_WIDTH = 16
) (
    input clk, rst_n,
    input cl, ld,
    input [DATA_WIDTH-1:0] in,
    input inc, dec,
    input sr, ir,
    input sl, il,
    output [DATA_WIDTH-1:0] out
);
    reg [DATA_WIDTH-1:0] data_next, data_reg;
    assign out = data_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            data_reg <= data_next;
        end
    end

    always @(*) begin
        data_next = data_reg;

        if (cl) data_next = {DATA_WIDTH{1'b0}};
        else if (ld) data_next = in;
        else if (inc) data_next = data_reg + { {(DATA_WIDTH-1){1'b0}}, 1'b1 };
        else if (dec) data_next = data_reg - { {(DATA_WIDTH-1){1'b0}}, 1'b1 };
        else if (sr) data_next = { ir, data_reg[DATA_WIDTH-1:1] };
        else if (sl) data_next = { data_reg[DATA_WIDTH-2:0], il };
    end
    
endmodule