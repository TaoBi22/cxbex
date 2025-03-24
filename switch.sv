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

    output  wire        cx_req_ready,
    output  wire        cx_resp_valid,
    output  wire        cx_resp_state,
    output  wire [3:0]  cx_resp_status,
    output  wire [31:0] cx_resp_data,

    input wire [1:0]  cx_virt_state_id,

    input wire [31:0] cx_insn_o,
    input wire [24:0] cx_func_o,

    // Interfaces with CXUs
    input wire [32 * N_CXU - 1:0] cxu_responses,
    input wire [N_CXU - 1:0] cxu_readys,
    output wire [N_CXU - 1:0] cxu_valids,
    // no point replicating these for each CXU
    output wire [31:0] cxu_data0,
    output wire [31:0] cxu_data1,
    output wire [1:0] cx_state_id,

);
    
    assign cxu_data0 = cx_req_data0;
    assign cxu_data1 = cx_req_data1;
    assign cx_state_id = cx_state_id;

    typedef enum logic[1:0] {
        AWAIT_REQ,
        REQ_IN_PROGRESS,
        AWAIT_RESP,
    } switch_state;
    switch_state switch_state_c, switch_state_n;

    reg[31:0] cxu_response;
    wire[31:0] cxu_response_c;

    always_comb begin 
        // TODO: set defaults
        cx_req_ready = 1'b0;
        cx_resp_valid = 1'b0;
        cx_resp_state = 1'b0;
        cx_resp_status = 4'b0;
        cx_resp_data = 32'h0;
        cxu_valids = 4'b0;
        switch_state_n = switch_state_c;
        cxu_response_c = 32'h0;
        case (switch_state_c)
            AWAIT_REQ: begin
                cx_req_ready = 1'b1;
                cx_resp_valid = 1'b0;
                if (cx_req_valid) begin
                    switch_state_n = REQ_IN_PROGRESS;
                end
            end
            REQ_IN_PROGRESS: begin
                cx_req_ready = 1'b0;
                cx_resp_valid = 1'b1;
                cxu_valids = 4'b1 << cx_cxu_id;
                if (cxu_readys[cx_cxu_id]) begin
                    switch_state_n = AWAIT_REQ;
                    cxu_response_c = (cxu_responses >> (cx_cxu_id * 32));
                end
            end
            AWAIT_RESP: begin
                cx_req_ready = 1'b0;
                cx_resp_valid = 1'b1;
                cx_resp_data = cxu_response;
                if (cx_resp_ready) begin
                    switch_state_n = AWAIT_REQ;
                end
            end

        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst) begin
            switch_state_c <= NO_REQ;
        end else begin
            switch_state_c <= switch_state_n;
            if (switch_state_c == REQ_IN_PROGRESS && cxu_readys[cx_cxu_id]) begin
                cxu_recxu_response <= cxu_response_c;
            end
        end
    end

endmodule