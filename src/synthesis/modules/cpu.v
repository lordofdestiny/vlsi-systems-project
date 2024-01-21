module cpu
# (
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] mem_in,
    input [DATA_WIDTH-1:0] in,
    output reg mem_we,
    output [ADDR_WIDTH-1:0] mem_addr,
    output [DATA_WIDTH-1:0] mem_data,
    output [DATA_WIDTH-1:0] out,
    output [ADDR_WIDTH-1:0] pc,
    output [ADDR_WIDTH-1:0] sp
);
    /* STATES */
    localparam state_init               = 8'h00;
    localparam state_read_high_ir_1     = 8'h01;
    localparam state_read_high_ir_2     = 8'h02;
    localparam state_read_high_ir_3     = 8'h03;
    localparam state_read_high_ir_4     = 8'h04;
    localparam state_read_high_ir_5     = 8'h05;
    localparam state_read_low_ir_1      = 8'h06;
    localparam state_read_low_ir_2      = 8'h07;
    localparam state_read_low_ir_3      = 8'h08;
    localparam state_read_low_ir_4      = 8'h09;
    
    localparam state_decode             = 8'h10;
    localparam state_ld_indirect_op1_1  = 8'h11;
    localparam state_ld_indirect_op1_2  = 8'h12;
    localparam state_ld_indirect_op1_3  = 8'h13;
    localparam state_ld_indirect_op1_4  = 8'h14;

    localparam state_ld_indirect_op2_1  = 8'h15;
    localparam state_ld_indirect_op2_2  = 8'h16;
    localparam state_ld_indirect_op2_3  = 8'h17;
    localparam state_ld_indirect_op2_4  = 8'h18;

    localparam state_ld_indirect_op3_1  = 8'h19;
    localparam state_ld_indirect_op3_2  = 8'h1a;
    localparam state_ld_indirect_op3_3  = 8'h1b;
    localparam state_ld_indirect_op3_4  = 8'h1c;

    localparam state_exec_mov           = 8'h40;
    localparam state_exec_mov_read_op_1 = 8'h41;
    localparam state_exec_mov_read_op_2 = 8'h42;
    localparam state_exec_mov_read_op_3 = 8'h43;
    localparam state_exec_mov_write_1   = 8'h44;
    localparam state_exec_mov_write_2   = 8'h45;
    localparam state_exec_mov_write_3   = 8'h46;
    localparam state_exec_mov_write_4   = 8'h47;
    
    localparam state_exec_alu_ld_op2_1  = 8'h50; 
    localparam state_exec_alu_ld_op2_2  = 8'h51; 
    localparam state_exec_alu_ld_op2_3  = 8'h52; 
    localparam state_exec_alu_ld_op2_4  = 8'h53;
    localparam state_exec_alu_ld_op3_1  = 8'h54; 
    localparam state_exec_alu_ld_op3_2  = 8'h55; 
    localparam state_exec_alu_ld_op3_3  = 8'h56; 
    localparam state_exec_alu_work      = 8'h57; 
    localparam state_exec_alu_st_op1_1  = 8'h58; 
    localparam state_exec_alu_st_op1_2  = 8'h59; 
    
    localparam state_exec_in_1          = 8'h60;
    localparam state_exec_in_2          = 8'h61;
    
    localparam state_exec_out_1         = 8'h70;
    localparam state_exec_out_2         = 8'h71;
    localparam state_exec_out_3         = 8'h72;
    localparam state_exec_out_4         = 8'h73;
    localparam state_exec_out_5         = 8'h74;

    localparam state_exec_done          = 8'ha0;

    localparam state_exec_stop          = 8'hf0;

    localparam state_exec_stop_o_op1_1  = 8'hf1;
    localparam state_exec_stop_o_op1_2  = 8'hf2;
    localparam state_exec_stop_o_op1_3  = 8'hf3;
    localparam state_exec_stop_o_op1_4  = 8'hf4;
    
    localparam state_exec_stop_o_op2_1  = 8'hf5;
    localparam state_exec_stop_o_op2_2  = 8'hf6;
    localparam state_exec_stop_o_op2_3  = 8'hf7;
    localparam state_exec_stop_o_op2_4  = 8'hf8;
    
    localparam state_exec_stop_o_op3_1  = 8'hf9;
    localparam state_exec_stop_o_op3_2  = 8'hfa;
    localparam state_exec_stop_o_op3_3  = 8'hfb;
    localparam state_exec_stop_o_op3_4  = 8'hfc;

    localparam state_exec_stop_loop     = 8'hff;

    /* INSTRUCTION OPCODES */
    localparam instr_MOV    = 4'b0000; // 1 or 2 Bytes
    localparam instr_ADD    = 4'b0001; // 1 Byte
    localparam instr_SUB    = 4'b0010; // 1 Byte
    localparam instr_MUL    = 4'b0011; // 1 Byte
    localparam instr_DIV    = 4'b0100; // 1 Byte
    localparam instr_IN     = 4'b0111; // 1 Byte
    localparam instr_OUT    = 4'b1000; // 1 Byte
    localparam instr_STOP   = 4'b1111; // 1 Byte

    /* Internals */
    reg [7:0] state_next, state_reg;

    /* CPU REGISTERS */

    reg pc_ld, pc_inc;
    reg [ADDR_WIDTH-1:0] pc_in;
    register #(ADDR_WIDTH) pc_reg(
        .clk(clk), .rst_n(rst_n),
        .ld(pc_ld), .in(pc_in),
        .inc(pc_inc),
        .out(pc),
        .cl(), .dec(),
        .sr(), .ir(),
        .sl(), .il()
    );

    reg sp_ld;
    reg [ADDR_WIDTH-1:0] sp_in;
    register #(ADDR_WIDTH) sp_reg(
        .clk(clk), .rst_n(rst_n),
        .ld(sp_ld), .in(sp_in),
        .inc(),
        .out(sp),
        .cl(), .dec(),
        .sr(), .ir(),
        .sl(), .il()
    );

    reg ir_cl, ir_ld;
    wire [31:0] ir_in;
    reg [15:0] ir_in_high, ir_in_low;
    assign ir_in = {ir_in_high, ir_in_low};
    
    wire [31:0] ir;
    wire [15:0] ir_high, ir_low;
    assign {ir_high, ir_low} = ir;

    wire [3:0] ir_opcode;
    wire [3:0] ir_operand_1, ir_operand_2, ir_operand_3;
    wire [15:0] ir_data; 
    assign {
        ir_opcode,
        ir_operand_1, ir_operand_2, ir_operand_3,
        ir_data
    } =  ir;
    
    wire ir_indirect_op1, ir_indirect_op2, ir_indirect_op3;
    assign ir_indirect_op1 = ir_operand_1[3];
    assign ir_indirect_op2 = ir_operand_2[3];
    assign ir_indirect_op3 = ir_operand_3[3];
    
    wire [ADDR_WIDTH-1:0] ir_op1_addr, ir_op2_addr, ir_op3_addr;
    assign ir_op1_addr = {{(ADDR_WIDTH - 3){1'b0}}, ir_operand_1[2:0]}; 
    assign ir_op2_addr = {{(ADDR_WIDTH - 3){1'b0}}, ir_operand_2[2:0]}; 
    assign ir_op3_addr = {{(ADDR_WIDTH - 3){1'b0}}, ir_operand_3[2:0]}; 

    register #(32) ir_reg(
        .clk(clk), .rst_n(rst_n),
        .cl(ir_cl),
        .ld(ir_ld), .in(ir_in),
        .out(ir),
        .inc(), .dec(),
        .sr(), .ir(),
        .sl(), .il()
    );

    reg acc_ld, acc_cl;
    reg [DATA_WIDTH-1:0] acc_in;
    wire [DATA_WIDTH-1:0] acc;
    register #(DATA_WIDTH) acc_reg(
        .clk(clk), .rst_n(rst_n),
        .cl(acc_cl),
        .ld(acc_ld), .in(acc_in),
        .out(acc),
        .inc(), .dec(),
        .sr(), .ir(),
        .sl(), .il()
    );

    reg mar_ld, mar_inc;
    reg [ADDR_WIDTH-1:0] mar_in;
    register #(ADDR_WIDTH) mar_reg(
        .clk(clk), .rst_n(rst_n),
        .ld(mar_ld), .in(mar_in),
        .inc(mdr_inc),
        .out(mem_addr),
        .cl(), .dec(),
        .sr(), .ir(),
        .sl(), .il()
    );

    reg mdr_ld;
    reg [DATA_WIDTH-1:0] mdr_in;
    register #(DATA_WIDTH) mdr_reg(
        .clk(clk), .rst_n(rst_n),
        .ld(mdr_ld), .in(mdr_in),
        .out(mem_data),
        .cl(),
        .inc(), .dec(),
        .sr(), .ir(),
        .sl(), .il()
    );

    /* INDIRECT MEMORY REGISTERS */
    reg op1_addr_ld;
    wire [ADDR_WIDTH-1:0] op1_addr;
    register #(ADDR_WIDTH) op1_addr_reg(
        .clk(clk), .rst_n(rst_n),
        .ld(op1_addr_ld), .in(mem_data[5:0]),
        .out(op1_addr),
        .cl(),
        .inc(), .dec(),
        .sr(), .ir(),
        .sl(), .il()
    );

    reg op2_addr_ld;
    wire [ADDR_WIDTH-1:0] op2_addr;
    register #(ADDR_WIDTH) op2_addr_reg(
        .clk(clk), .rst_n(rst_n),
        .ld(op2_addr_ld), .in(mem_data[5:0]),
        .out(op2_addr),
        .cl(),
        .inc(), .dec(),
        .sr(), .ir(),
        .sl(), .il()
    );
    
    reg op3_addr_ld;
    wire [ADDR_WIDTH-1:0] op3_addr;
    register #(ADDR_WIDTH) op3_addr_reg(
        .clk(clk), .rst_n(rst_n),
        .ld(op3_addr_ld), .in(mem_data[5:0]),
        .out(op3_addr),
        .cl(),
        .inc(), .dec(),
        .sr(), .ir(),
        .sl(), .il()
    );
    
    /* OUTPUT REGISTER */
    reg [DATA_WIDTH-1:0] out_next, out_reg;
    assign out = out_reg;
        

    /* INSTRUCTION DECODING */
    reg two_word_instruction;
    always @(*) begin
       two_word_instruction = 
            ir_opcode == instr_MOV &&
            ir_operand_3 == 4'b1000;
    end

    /* Pick instruction state */
    reg [7:0] instruction_state;
    always @(*) begin
        case (ir_opcode)
            instr_MOV:  instruction_state = state_exec_mov;
            instr_ADD:  instruction_state = state_exec_alu_ld_op2_1; 
            instr_SUB:  instruction_state = state_exec_alu_ld_op2_1;
            instr_MUL:  instruction_state = state_exec_alu_ld_op2_1;
            instr_DIV:  instruction_state = state_exec_done; // Ignore instruction and go to next instruction
            instr_IN:   instruction_state = state_exec_in_1;
            instr_OUT:  instruction_state = state_exec_out_1;
            instr_STOP: instruction_state = state_exec_stop;
            default: begin
                $strobe("error (invalid opcode): go to stop state");
                instruction_state = state_exec_stop_loop;
            end
        endcase
    end

    /* Generate ALU OC */
    reg [2:0] alu_oc;
    always @(*) begin
        case(ir_opcode)
            instr_ADD:  alu_oc = 3'b000;
            instr_SUB:  alu_oc = 3'b001;
            instr_MUL:  alu_oc = 3'b010;
            instr_DIV:  alu_oc = 3'b011;
            default: alu_oc = 3'b000; // Some default is needed
        endcase
    end

    /* ALU */
    wire [DATA_WIDTH-1:0] alu_out;
    alu #(
        .DATA_WIDTH(DATA_WIDTH)
    ) alu0(
        .oc(alu_oc),
        .a(acc), .b(mem_data),
        .f(alu_out)
    );

    /* Implementation */
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state_reg <= state_init;
            out_reg <= 0;
        end else begin
            state_reg <= state_next;
            out_reg <= out_next;
        end
    end

    always @(*) begin
        /* INTERNAL CONTROL SIGNALS*/
        /* PC register*/
        pc_ld = 0;
        pc_inc = 0;
        pc_in = 0;

        /* SP register*/
        sp_ld = 0;
        sp_in = 0;
        
        /* IR register*/
        ir_ld = 0;
        ir_cl = 0;
        ir_in_high = 16'hDEFE;
        ir_in_low = 16'hDCBA;
        
        /* ACC register*/
        acc_cl = 0;
        acc_ld = 0;
        acc_in = alu_out;

        /* MEMORY BUS CONTROL SIGNALS */
        mem_we = 0;
        mar_ld = 0;
        mar_inc = 0;
        mar_in = pc;
        mdr_ld = 0;
        mdr_in = mem_in;

        op1_addr_ld = 0;
        op2_addr_ld = 0;
        op3_addr_ld = 0;

        /* OUTPUT REGISTER*/
        out_next = out_reg;

        case (state_reg)
            /* INITIALIZATION STATES*/
            state_init: begin
                // Reset pc to 0x08
                pc_ld = 1'b1;
                pc_in = {{(DATA_WIDTH-4){1'b0}}, 4'h8};
                // Reset sp to last address in memory
                sp_ld = 1'b1;
                sp_in = {ADDR_WIDTH{1'b1}};
                // Reset ir to 0
                ir_cl = 1'b1;
                // Reset acc to 0
                acc_cl = 1'b1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            /* INSTRUCTION FETCH STATES*/
            state_read_high_ir_1: begin
                pc_inc = 1;
                mar_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_read_high_ir_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_read_high_ir_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_read_high_ir_4: begin
                ir_ld = 1;
                ir_in_high = mem_data;
                ir_in_low = ir_low;
                state_next = state_reg + 1;
            end
            state_read_high_ir_5: begin
                state_next = two_word_instruction
                    ? state_reg + 1 // Read next word into IR
                    : state_decode // Go to the decode state
                    ;
            end
            state_read_low_ir_1: begin
                pc_inc = 1;
                mar_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_read_low_ir_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_read_low_ir_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_read_low_ir_4:begin
                ir_ld = 1;
                ir_in_high = ir_high;
                ir_in_low = mem_data;
                state_next = state_decode;
            end
            /* INSTRUCTION DECODE STATES */
            state_decode: begin
                if(ir_indirect_op1) begin
                    state_next = state_ld_indirect_op1_1;
                end
                else if(ir_indirect_op2 &&
                        ir_opcode != instr_IN && ir_opcode != instr_OUT) begin
                    state_next = state_ld_indirect_op2_1;
                end
                else if(ir_indirect_op3 && ir_opcode != instr_MOV &&
                        ir_opcode != instr_IN && ir_opcode != instr_OUT) begin
                    state_next = state_ld_indirect_op3_1;
                end
                else begin
                    state_next = instruction_state;
                end
            end
            state_ld_indirect_op1_1: begin
                mar_ld = 1;
                mar_in = ir_op1_addr;
                // Go to the next state
                state_next = state_reg + 1; 
            end
            state_ld_indirect_op1_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_ld_indirect_op1_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1; 
            end
            state_ld_indirect_op1_4: begin
                op1_addr_ld = 1;
                if(ir_indirect_op2  &&
                    ir_opcode != instr_IN && ir_opcode != instr_OUT) begin
                    state_next = state_ld_indirect_op2_1;
                end
                else if(ir_indirect_op3 && ir_opcode != instr_MOV &&
                        ir_opcode != instr_IN && ir_opcode != instr_OUT) begin
                    state_next = state_ld_indirect_op3_1;
                end
                else begin
                    state_next = instruction_state;
                end 
            end
            state_ld_indirect_op2_1: begin
                mar_ld = 1;
                mar_in = ir_op2_addr;
                // Go to the next state
                state_next = state_reg + 1; 
            end
            state_ld_indirect_op2_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_ld_indirect_op2_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1; 
            end
            state_ld_indirect_op2_4: begin
                op2_addr_ld = 1;
                if(ir_indirect_op3 && ir_opcode != instr_MOV &&
                    ir_opcode != instr_IN && ir_opcode != instr_OUT) begin
                    state_next = state_ld_indirect_op3_1;
                end
                else begin
                    state_next = instruction_state;
                end 
            end

            state_ld_indirect_op3_1: begin
                mar_ld = 1;
                mar_in = ir_op3_addr;
                // Go to the next state
                state_next = state_reg + 1; 
            end
            state_ld_indirect_op3_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_ld_indirect_op3_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1; 
            end
            state_ld_indirect_op3_4: begin
                op3_addr_ld = 1;
                state_next = instruction_state;
            end
            /* INSTRUCTION EXEC STATES */
            state_exec_mov: begin
                if(ir_operand_3 == 4'b0000) begin
                    state_next = state_exec_mov_read_op_1;
                end
                else if(ir_operand_3 == 4'b1000) begin
                    mdr_ld = 1;
                    mdr_in = ir_data;
                    state_next = state_exec_mov_write_1;
                end else begin
                    $display("error - invalid mov type (%2h): go to stop state", state_reg);
                    state_next = state_exec_stop_loop;
                end
            end
            state_exec_mov_read_op_1: begin
                mar_ld = 1;
                mar_in = ir_indirect_op2
                    ? op2_addr
                    : ir_op2_addr;
                // Go to the next state
                state_next = state_reg + 1; 
            end
            state_exec_mov_read_op_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_exec_mov_read_op_3: begin
                mdr_ld = 1;
                state_next = state_exec_mov_write_1;
            end
            state_exec_mov_write_1: begin
                mar_ld = 1;
                mar_in = ir_indirect_op1
                    ? op1_addr
                    : ir_op1_addr;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_mov_write_2: begin
                mem_we = 1;
                // Wait a single cycle for memory data
                state_next = state_exec_done;
            end
            state_exec_alu_ld_op2_1: begin
                mar_ld = 1;
                mar_in = ir_indirect_op2
                    ? op2_addr
                    : ir_op2_addr;
                // Go to the next state
                state_next = state_reg + 1; 
            end
            state_exec_alu_ld_op2_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_exec_alu_ld_op2_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1; 
            end
            state_exec_alu_ld_op2_4: begin
                acc_ld = 1;
                acc_in = mem_data;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_alu_ld_op3_1: begin
                mar_ld = 1;
                mar_in = ir_indirect_op3
                    ? op3_addr
                    : ir_op3_addr;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_alu_ld_op3_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_exec_alu_ld_op3_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_alu_work: begin
                acc_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_alu_st_op1_1: begin
                mar_ld = 1;
                mar_in = ir_indirect_op1
                    ? op1_addr
                    : ir_op1_addr;
                mdr_ld = 1;
                mdr_in = acc;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_alu_st_op1_2: begin
                mem_we = 1;
                // Wait a single cycle for memory data
                state_next = state_exec_done;
            end
            state_exec_in_1: begin
                mar_ld = 1;
                mar_in = ir_indirect_op1
                    ? op1_addr
                    : ir_op1_addr;
                mdr_ld = 1;
                mdr_in = in;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_in_2: begin
                mem_we = 1;
                state_next = state_exec_done;
            end
            state_exec_out_1: begin
                mar_ld = 1;
                mar_in = ir_indirect_op1
                    ? op1_addr
                    : ir_op1_addr;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_out_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_exec_out_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_out_4: begin
                out_next = mem_data;
                state_next = state_exec_done;
            end
            state_exec_done: state_next = state_read_high_ir_1;
            state_exec_stop: begin
                if(ir_operand_1 != 4'b000) begin
                    state_next = state_exec_stop_o_op1_1;
                end
                else if(ir_operand_2 != 4'b0000) begin
                    state_next = state_exec_stop_o_op2_1;
                end
                else if(ir_operand_3 != 4'b0000) begin
                    state_next = state_exec_stop_o_op3_1;
                end else begin
                    state_next = state_exec_stop_loop;
                end
            end
            state_exec_stop_o_op1_1: begin
                mar_ld = 1;
                mar_in = ir_indirect_op1
                    ? op1_addr
                    : ir_op1_addr;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_stop_o_op1_2: begin
                // Wait a single cycle for memory data
                state_next = state_reg + 1;
            end
            state_exec_stop_o_op1_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_stop_o_op1_4: begin
                out_next = mem_data;
                if(ir_operand_2 != 4'b0000) begin
                    state_next = state_exec_stop_o_op2_1;
                end
                else if(ir_operand_3 != 4'b0000) begin
                    state_next = state_exec_stop_o_op3_1;
                end else begin
                    state_next = state_exec_stop_loop;
                end
            end

            state_exec_stop_o_op2_1:begin
                mar_ld = 1;
                mar_in = ir_indirect_op2
                    ? op2_addr
                    : ir_op2_addr;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_stop_o_op2_2: begin
               // Wait a single cycle for memory data
                state_next = state_reg + 1; 
            end
            state_exec_stop_o_op2_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_stop_o_op2_4: begin
                out_next = mem_data;
                if(ir_operand_3 != 4'b0000) begin
                    state_next = state_exec_stop_o_op3_1;
                end else begin
                    state_next = state_exec_stop_loop;
                end
            end
            state_exec_stop_o_op3_1: begin
                mar_ld = 1;
                mar_in = ir_indirect_op3
                    ? op3_addr
                    : ir_op3_addr;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_stop_o_op3_2: begin
               // Wait a single cycle for memory data
                state_next = state_reg + 1; 
            end
            state_exec_stop_o_op3_3: begin
                mdr_ld = 1;
                // Go to the next state
                state_next = state_reg + 1;
            end
            state_exec_stop_o_op3_4: begin
                out_next = mem_data;
                state_next = state_exec_stop_loop; 
            end

            state_exec_stop_loop: begin
                state_next = state_exec_stop_loop; // Loop the stop state
                #100 $finish;
            end
            default: begin
                $display("error - invalid state (%2h): go to stop state", state_reg);
                state_next = state_exec_stop;
            end
        endcase
    end

    /* LOGGING */
    always @(*) begin
        $strobe("%4t -> PC = %6b", $time, pc);
    end

    always @(*) begin
        $strobe("%4t -> SP = %6b", $time, sp);
    end

    always @(*) begin
        $strobe("%4t -> op = %04b; A = %04b; B = %04b, C = %04b, DATA = %4h",
            $time, ir_opcode, ir_operand_1, ir_operand_2, ir_operand_3, ir_data);    
    end

    always @(*) begin
        $strobe("%4t -> ACC = %4h", $time, acc);
    end

    always @(*) begin
        $strobe("%4t -> MAR = %6b", $time, mem_addr);
    end

    always @(*) begin
        $strobe("%4t -> MDR = %4h", $time, mem_data);
    end

    always @(*) begin
        $strobe("%4t -> state = %2h", $time, state_reg);
    end

    always @(*) begin
        $strobe("%4t -> op_addr(1) = %6b", $time, op1_addr);
    end
    always @(*) begin
        $strobe("%4t -> op_addr(2) = %6b", $time, op2_addr);
    end
    always @(*) begin
        $strobe("%4t -> op_addr(3) = %6b", $time, op3_addr);
    end

endmodule