module deb #(
    parameter SIZE = 2
) (input clk, input rst_n, input in, output out);
    reg out_next, out_reg;
    reg [1:0] ff_next, ff_reg;
    reg [SIZE-1:0] cnt_next, cnt_reg;
    wire is_changed, is_stable;

    assign out = out_reg;
    assign is_changed = ff_reg[0] ^ ff_reg[1];
    assign is_stable = cnt_reg == {SIZE{1'b1}};

    always @(posedge clk, negedge rst_n)
        if(!rst_n) begin
            out_reg <= 1'b0;
            ff_reg <= 2'b00;
            cnt_reg <= {SIZE{1'b0}};
        end else begin
            out_reg <= out_next;
            ff_reg <= ff_next;
            cnt_reg <= cnt_next;
        end

    always @(*) begin
        ff_next[0] = in;
        ff_next[1] = ff_reg[0];
        cnt_next = is_changed ? 0 : (cnt_reg + 1'b1);
        out_next = is_stable ? ff_reg[1] : out_reg;
    end

endmodule