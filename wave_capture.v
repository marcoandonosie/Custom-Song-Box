`define ARMED 2'b00
`define ACTIVE 2'b01
`define WAIT 2'b10
`define WIDTH 2

module wave_capture (
    input clk,
    input reset,
    input new_sample_ready,
    input [15:0] new_sample_in,
    input wave_display_idle,

    output wire [8:0] write_address,
    output wire write_enable,
    output wire [7:0] write_sample,
    output wire read_index
);
    
    // flip flop to track states
    wire [1:0] next_state;
    wire [1:0] cur_state;
    reg [1:0] next_state_1;
    dffr #(`WIDTH) dff1 (.clk(clk), .r(reset), .d(next_state), .q(cur_state));
    
    // flip flop to track counter (address into RAM)
    wire [7:0] next_address;
    wire [7:0] cur_address;
    reg [7:0] next_address_1;
    dffr #(.WIDTH(8)) dff2 (.clk(clk), .r(reset), .d(next_address), .q(cur_address)); // width of 8 is correct???
    
    // flip flop to track prev and cur sample
    wire [15:0] input_sample;
    wire [15:0] prev_sample;
    dffr #(.WIDTH(16)) dff3 (.clk(clk), .r(reset), .d(input_sample), .q(prev_sample));
    
    // temp variable to update read_index
//    reg update_read_index;

    // flip flop to track read_index value
    wire next_index;
    wire cur_index;
    dffre #(.WIDTH(1)) dff4 (.clk(clk), .r(reset), .d(next_index), .q(cur_index), .en(wave_display_idle == 1'b1 && cur_state == `WAIT));
    
    always @(*) begin
        case(cur_state)
            `ARMED: begin
                // signed samples -- 1 indicates a neg number and 0 indicates positive
                // NEED TO FIX BECAUSE IS THIS CORRECT ON WHEN TO DET3ECT SAMPLE GOING UP??????
                if (prev_sample[15] == 1'b1 && input_sample[15] == 1'b0) begin // prev_sample == 16'd0 && input_sample[15] == 1'b0) 
                    next_state_1 = `ACTIVE;
                    next_address_1 = 8'd0; // used to be cur_address
                    //next_index_1 = cur_index;
                    //update_read_index = read_index;
                end
                else begin
                    next_state_1 = `ARMED;
                    next_address_1 = 8'd0; // used to be cur_address
                    //next_index_1 = cur_index;
                    //update_read_index = read_index;
                end
            end
            `ACTIVE: begin
                if (new_sample_ready == 1'b1) begin
                    // update counter (will update in one cycle for the next time we get a sample)
                    // not a problem because we start at zero indexing so no need to wait to send to RAM
                    if (cur_address == 8'd255) begin //255
                        next_address_1 = cur_address; // used to be 8'd0
                        next_state_1 = `WAIT;
                        //next_index_1 = cur_index;
                        //update_read_index = read_index;
                    end
                    else begin
                        next_address_1 = cur_address + 8'd1;  
                        next_state_1 = `ACTIVE;
                        //next_index_1 = cur_index;
                        //update_read_index = read_index;
                    end
                end
                else begin
                    next_address_1 = cur_address;
                    next_state_1 = `ACTIVE;
                    //next_index_1 = cur_index;
                    //update_read_index = read_index;
                end
            end
            `WAIT: begin
                if (wave_display_idle == 1'b1) begin
                    //update_read_index = ~read_index;
                    //next_index_1 = ~cur_index;
                    next_state_1 = `ARMED;
                    next_address_1 = cur_address;
                end
                else begin
                    //update_read_index = read_index;
                   // next_index_1 = cur_index;
                    next_state_1 = `WAIT;
                    next_address_1 = cur_address;
                end
            end
        endcase
    end
    assign next_state = reset ? `ARMED : next_state_1;
    assign next_address = reset ? 8'd0 : next_address_1; // width of 8 is correct?
    assign input_sample = new_sample_in; // need reset? reset ? 16'd0 : 
    assign next_index = ~read_index; //reset ? 1'b1 : next_index_1; // next_index = ~read_index with an enable
    
    // assign values to outputs
    assign read_index = cur_index;
    assign write_address = {~read_index, cur_address};
    assign write_sample = ~new_sample_in[15:8] + 8'd128; // was 128 // cur_state == `ACTIVE ? 
    assign write_enable = cur_state == `ACTIVE ? 1'b1 : 1'b0;
endmodule