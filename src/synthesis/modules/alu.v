module alu
#(
    parameter DATA_WIDTH = 16
) (
    input [2:0] oc,
    input [DATA_WIDTH-1:0] a, b,
    output [DATA_WIDTH-1:0] f
);
    localparam [2:0] ADD    = 3'b000;
    localparam [2:0] SUB    = 3'b001;
    localparam [2:0] MUL    = 3'b010;
    localparam [2:0] DIV    = 3'b011;
    localparam [2:0] NOT    = 3'b100;
    localparam [2:0] XOR    = 3'b101;
    localparam [2:0] OR     = 3'b110;
    localparam [2:0] AND    = 3'b111;

    reg [DATA_WIDTH-1:0] result;
    assign f = result;

    always @(*) begin
        case (oc)
            ADD:    result = a + b;
            SUB:    result = a - b;
            MUL:    result = a * b;
            DIV:    result = a / b;
            NOT:    result = ~a;
            XOR:    result = a ^ b;
            OR:     result = a | b;
            AND:    result = a & b;
        endcase
    end

endmodule