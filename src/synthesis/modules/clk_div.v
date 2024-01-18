module clk_div 
#(
    parameter DIVISOR = 50_000_000
) (
    input clk,
    input rst_n,
    output out
);
    reg out_reg;
    assign out = DIVISOR > 1
        ? out_reg
        : clk;

    integer counter;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            counter <= 0;
            out_reg <= 1'b0;
        end else begin
            counter <= counter + 1;
            if( counter >= DIVISOR - 1) begin
                counter <= 0;
            end
            out_reg <= (counter < DIVISOR / 2) ? 1'b1: 1'b0;
        end
    end

endmodule