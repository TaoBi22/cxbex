`timescale 1ns / 1ps
`define N 4

module testbench;

    reg clk;
    reg rst;
    reg cx_clk;
    reg cx_rst;
    reg cx_req_valid;
    reg cx_resp_ready;
    reg [1:0] cx_cxu_id;
    reg [1:0] cx_state_id;
    reg [31:0] cx_req_data0;
    reg [31:0] cx_req_data1;

    wire cx_req_ready;
    wire cx_resp_valid;
    wire cx_resp_state;
    wire [3:0] cx_resp_status;
    wire [31:0] cx_resp_data;

    reg [1:0] cx_virt_state_id;

    reg [31:0] cx_insn_o;
    reg [24:0] cx_func_o;

    reg [32 * 4 - 1:0] cxu_responses;
    reg [4 - 1:0] cxu_readys;
    reg [4 * 4 - 1:0] cxu_statuses;
    wire [4 - 1:0] cxu_valids;
    wire [31:0] cxu_data0_o;
    wire [31:0] cxu_data1_o;
    wire [1:0] cx_state_id_o;

    always #50 clk = ~clk; // Clock generation

    initial begin
        adder_waiting = 1;
        $dumpfile("test.vcd");
        $dumpvars(0, testbench);
        clk = 0;
        rst = 0;
        cx_clk = 0;
        cx_rst = 0;
        cx_req_valid = 0;
        cx_resp_ready = 0;
        cx_cxu_id = 0;
        cx_state_id = 0;
        cx_req_data0 = 5;
        cx_req_data1 = 1;
        cx_virt_state_id = 0;
        cx_insn_o = 0;
        cx_func_o = 0;
        cxu_responses = 0;
        cxu_readys = 0;
        cxu_statuses = 0;

        #100 rst = 1;
        #100 rst = 0;
        #100 cx_req_valid = 1;
        #100 cx_req_valid = 0;

        while (~cx_resp_valid) begin
            #100;
        end

        cx_resp_ready = 1;

        #1000 $finish;
    end

    switch my_switch (
    // CX signals from/to Ibex

    .clk(clk),
    .rst(rst),
    .cx_clk(cx_clk),
    .cx_rst(cx_rst),
    .cx_req_valid(cx_req_valid),
    .cx_resp_ready(cx_resp_ready),
    .cx_cxu_id(cx_cxu_id),
    .cx_state_id(cx_state_id),
    .cx_req_data0(cx_req_data0),
    .cx_req_data1(cx_req_data1),

    .cx_req_ready(cx_req_ready),
    .cx_resp_valid(cx_resp_valid),
    .cx_resp_state(cx_resp_state),
    .cx_resp_status(cx_resp_status),
    .cx_resp_data(cx_resp_data),

    .cx_virt_state_id(cx_virt_state_id),

    .cx_insn_o(cx_insn_o),
    .cx_func_o(cx_func_o),

    .cxu_responses(cxu_responses),
    .cxu_readys(cxu_readys),
    .cxu_statuses(cxu_statuses),
    .cxu_valids(cxu_valids),
    .cxu_data0_o(cxu_data0_o),
    .cxu_data1_o(cxu_data1_o),
    .cx_state_id_o(cx_state_id_o)
    );

    reg adder_waiting;
    reg[31:0] adder_result;

    always @ (posedge clk) begin
        if (adder_waiting) begin
            if (cxu_valids[0]) begin
                adder_result <= cxu_data0_o + cxu_data1_o;
                adder_waiting <= 0;
                cxu_readys[0] <= 0;
            end
        end else begin
            cxu_responses[31:0] <= adder_result;
            cxu_readys[0] <= 1;
            adder_waiting <= 1;
        end
    end

endmodule