module alu (
    input [2:0] oc,
    input [3:0] a, b,
    output reg [3:0] f
);
    localparam [2:0] ADD    = 3'b000;
    localparam [2:0] SUB    = 3'b001;
    localparam [2:0] MUL    = 3'b010;
    localparam [2:0] DIV    = 3'b011;
    localparam [2:0] NOT    = 3'b100;
    localparam [2:0] XOR    = 3'b101;
    localparam [2:0] OR     = 3'b110;
    localparam [2:0] AND    = 3'b111;

    always @(*) begin
        case (oc)
            ADD:    f = a + b;
            SUB:    f = a - b;
            MUL:    f = a * b;
            DIV:    f = a / b;
            NOT:    f = ~a;
            XOR:    f = a ^ b;
            OR:     f = a | b;
            AND:    f = a & b;
        endcase
    end

endmodule