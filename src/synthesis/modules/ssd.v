module ssd (
    input [3:0] in,
    output [6:0] out
);
    reg [7:0] out_reg;
    assign out = out_reg;

    always @(*) begin
        case (in)
            4'd0:    out_reg = ~7'h3F;
            4'd1:    out_reg = ~7'h06;
            4'd2:    out_reg = ~7'h5B;
            4'd3:    out_reg = ~7'h4F;
            4'd4:    out_reg = ~7'h66;
            4'd5:    out_reg = ~7'h6D;
            4'd6:    out_reg = ~7'h7D;
            4'd7:    out_reg = ~7'h07;
            4'd8:    out_reg = ~7'h7F;
            4'd9:    out_reg = ~7'h4F;
            default: out_reg = ~7'b0; 
        endcase
    end
endmodule