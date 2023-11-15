module wave_display (
    input clk,
    input reset,
    input [10:0] x,  // [0..1279]
    input [9:0]  y,  // [0..1023]
    input valid,
    input [7:0] read_value,
    input read_index,
    output wire [8:0] read_address,
    output wire valid_pixel,
    output wire [7:0] r,
    output wire [7:0] g,
    output wire [7:0] b
);
wire [7:0] read_value_adjusted = (read_value >> 1'b1) + 8'd32;
// get read_address to put into RAM:
    // a valid pixel is one that is in the valid region, top half, and middle two
    // quadrants of the vga
//wire enable_value = ^x[9:8] && ~y[9] && valid;
wire [8:0] next_read_address = reset ? 8'd0 : {read_index, x[9], x[7:1]};
// wire [8:0] prev_read_address = read_address; // temp wire to hold the previous address
dffre #(9) RAM_addresses (.clk(clk), .r(reset), .en(valid), 
                          .d(next_read_address), .q(read_address));
                          
// get valid_pixel output and rgb values
    // only accept a new data sample from RAM when read_address changes

wire [7:0] next_read_value = reset ? 8'd0 : read_value_adjusted; //should be read_value_adjusted
wire [7:0] cur_read_value;
//wire [7:0] prev_read_value = cur_read_value; // saves the previous data from the RAM

wire check_enable_signal_2 = next_read_address > read_address;
dffre #(8) RAM_data(.clk(clk), .r(reset), .en(check_enable_signal_2),
                    .d(next_read_value), .q(cur_read_value)); // en signal is when read_addr changes
                    
// logic to get valid pixels
reg y_is_between;
wire [7:0] y_wire = y[8:1];

always @(*) begin
    if (^x[9:8] && ~y[9] && valid) begin // this line checks that we are in correct area of vga
        // this logic checks that we are between the previous and current values
       if ((y[8:1] >= cur_read_value && y[8:1] <= next_read_value) ||
            (y[8:1] <= cur_read_value && y[8:1] >= next_read_value)) begin
            y_is_between = 1'b1;
       end
       else begin
            y_is_between = 1'b0;
       end
    end else begin
        y_is_between = 1'b0; 
    end   
end

assign valid_pixel = (y_is_between);
assign {r, g, b} = reset ? 24'h000000 : (y_is_between) ? 24'hFFFFFF : 24'h000000;

endmodule