`define AWAIT_REQ 2'b00
`define REQ_IN_PROGRESS 2'b01
`define AWAIT_RESP 2'b11

module switch #(parameter N_CXU = 4) (
    // CX signals from/to Ibex

    input wire        clk,
    input wire        rst,
    input wire        cx_clk,
    input wire        cx_rst,
    input wire        cx_req_valid,
    input wire        cx_resp_ready,
    input wire [1:0]  cx_cxu_id,
    input wire [1:0]  cx_state_id,
    input wire [31:0] cx_req_data0,
    input wire [31:0] cx_req_data1,

    output  reg        cx_req_ready,
    output  reg        cx_resp_valid,
    output  reg        cx_resp_state,
    output  reg [3:0]  cx_resp_status,
    output  reg [31:0] cx_resp_data,

    input wire [1:0]  cx_virt_state_id,

    input wire [31:0] cx_insn_o,
    input wire [24:0] cx_func_o,

    // Interfaces with CXUs
    input wire [32 * N_CXU - 1:0] cxu_responses,
    input wire [N_CXU - 1:0] cxu_replying,
    input wire [4 * N_CXU - 1:0] cxu_statuses,
    output reg [N_CXU - 1:0] cxu_requesting,
    // no point replicating these for each CXU
    output wire [31:0] cxu_data0_o,
    output wire [31:0] cxu_data1_o,
    output wire [1:0] cx_state_id_o

);

    assign cxu_data0_o = cx_req_data0;
    assign cxu_data1_o = cx_req_data1;
    assign cx_state_id_o = cx_state_id;

    reg[1:0] switch_state_c, switch_state_n;

    reg[31:0] cxu_response_c;
    reg[31:0] cxu_response_n;

    reg[3:0] cxu_status_c;
    reg[3:0] cxu_status_n;

    // [MK] Can we always set those?
    // We have hand-shaking anyways
    always cx_resp_status = cxu_status_c;
    always cx_resp_data = cxu_response_c;
    always cxu_requesting = 4'b1 << cx_cxu_id;


    always @ (*) begin
        cx_req_ready = 1'b0;
        cx_resp_valid = 1'b0;
        cx_resp_state = 1'b0;

        switch_state_n = switch_state_c;
        cxu_response_n = cxu_response_c;
        cxu_status_n = cxu_status_c;

        case (switch_state_c)
            `AWAIT_REQ: begin
                cx_req_ready = 1'b1;
                if (cx_req_valid) begin
                    switch_state_n = `REQ_IN_PROGRESS;
                end
            end
            `REQ_IN_PROGRESS: begin
                if (cxu_replying[cx_cxu_id]) begin
                    switch_state_n = `AWAIT_RESP;
                    cxu_response_n = (cxu_responses >> (cx_cxu_id * 32));
                    cxu_status_n = (cxu_statuses >> (cx_cxu_id * 4));
                end
            end
            `AWAIT_RESP: begin
                // TODO: return status bits
                cx_resp_valid = 1'b1;
                if (cx_resp_ready) begin
                    switch_state_n = `AWAIT_REQ;
                end
            end
            default: begin
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            switch_state_c <= `AWAIT_REQ;
        end else begin
            switch_state_c <= switch_state_n;
            cxu_response_c <= cxu_response_n;
            cxu_status_c <= cxu_status_n;
        end
    end

endmodule
