/*

0,1,2,3: upper2lower
4,5,6,7: lower2upper
8: ms1b (index of most significant bit set)
*/

module cx #(
    parameter TYPE = 1
) (
  input logic rstn,
  input logic clk,
  
  input logic [9:0] opcode,
  input logic [31:0] op_a,
  input logic [31:0] op_b,

  output logic invalid_opcode,
  output logic [31:0] result,
  output logic result_valid,
  output logic result_error

);

initial begin
    $dumpfile("waves.vcd");
    $dumpvars();
end

logic[7:0] a[4];
assign {a[3], a[2], a[1], a[0]} = op_a[31:0];

logic[7:0] r[4];
assign result[31:0] = {r[3], r[2], r[1], r[0]};


`define a 97
`define z 122
`define A 65
`define Z 90


always @* begin
invalid_opcode=1'b1;
result_valid=1'b1;
result_error=1'b0;
{r[3], r[2], r[1], r[0]}=32'd0;

casez (opcode)
    10'b00000000??: begin //upper2lower
        {r[3], r[2], r[1], r[0]}=op_a;
        invalid_opcode=1'b0;
        for(integer i=0; i<=opcode[1:0]; i++) begin
            if ((a[i] >= `A) && (a[i] <= `Z) ) r[i] = a[i] - `A + `a;
            else result_error=1'b1;
        end
        end
    10'b00000001??: begin //lower2upper
        {r[3], r[2], r[1], r[0]}=op_a;
        invalid_opcode=1'b0;
        for(integer i=0; i<=opcode[1:0]; i++) begin
            if (a[i] >= `a && a[i] <= `z ) r[i] = a[i] - `a + `A;
            else result_error=1'b1;
        end
        end
    10'b0000001000: begin //ms1b
        {r[3], r[2], r[1], r[0]}=32'd0;
        invalid_opcode=1'b0;
        result_error=1'b1;
        for(integer i=31; i>=0; i--) begin
            if (op_a[i]) begin
              {r[3], r[2], r[1], r[0]} = i;
              result_error=1'b0;
            end
        end
        end
    default: begin 
        end
endcase
end


endmodule

