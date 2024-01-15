module top ();
    /* ALU declarations */
    wire [2:0] opcode;
    wire [3:0] operandA;
    wire [3:0] operandB;
    wire [3:0] alu_result;

    reg [10:0] alu_input;
    assign { 
        opcode,
        operandA, operandB
    } = alu_input;

    alu alu0(
        .oc(opcode),
        .a(operandA),
        .b(operandB),
        .f(alu_result)
    );

    /* REGISTER declarations */
    reg reg_clk;
    reg reg_rst_n;
    wire reg_cl, reg_ld;
    wire [3:0] reg_in;
    wire reg_inc, reg_dec;
    wire reg_sr, reg_ir;
    wire reg_sl, reg_il;
    wire [3:0] reg_out;

    reg [11:0] reg_input;
    assign {
        reg_cl, reg_ld, reg_in,
        reg_inc, reg_dec,
        reg_sr, reg_ir,
        reg_sl, reg_il
    } = reg_input;


    register reg0(
        .clk(reg_clk), .rst_n(reg_rst_n),
        .cl(reg_cl), .ld(reg_ld), .in(reg_in),
        .inc(reg_inc), .dec(reg_dec),
        .sr(reg_sr), .ir(reg_ir),
        .sl(reg_sl), .il(reg_il),
        .out(reg_out)
    );
    

    /* ALU SETUP*/
    initial begin
        #5  $monitor(
            "opcode: %3b; A = %2d, B = %2d; result = %2d",
            opcode, operandA, operandB, alu_result);
    end

    /* REGISTER SETUP*/
    always #5 reg_clk = ~reg_clk;

    always @(reg_out) begin
        $strobe(
            "IN(%1b, %1b, %4b, %1b, %1b, %1b, %1b, %1b, %1b); OUT(%4b);",
            reg_cl, reg_ld, reg_in,
            reg_inc, reg_dec,
            reg_sr, reg_ir,
            reg_sl, reg_il,
            reg_out);
    end

    integer  i;

    initial begin
        alu_input = 11'b0;
        reg_clk = 1'b0;
        reg_rst_n = 1'b0;

        #5;
        for(i = 0; i < 2**11; i = i + 1) begin
            #5 alu_input = i;
        end

        #10; // wait between test phases

        #2 reg_rst_n = 1'b1;
        repeat (1000) begin
            #5 reg_input = {$random} % 2**12;
        end

        #5 $finish;
    end

endmodule