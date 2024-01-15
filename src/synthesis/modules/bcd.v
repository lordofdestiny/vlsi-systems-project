module bcd (
    input [5:0] in,
    output [3:0] ones, tens
);
    assign ones = in % 10;
    assign tens = in / 10;
endmodule