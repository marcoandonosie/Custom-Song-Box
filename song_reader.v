`define SONG_WIDTH 7
`define NOTE_WIDTH 6
`define DURATION_WIDTH 6
`define TYPE_WIDTH 1
`define METADATA 3

// ----------------------------------------------
// Define State Assignments
// ----------------------------------------------
`define SWIDTH 3
`define PAUSED             3'b000
`define WAIT               3'b001
`define INCREMENT_ADDRESS  3'b010
`define RETRIEVE_NOTE      3'b011
`define NEW_NOTE_READY1     3'b100
`define NEW_NOTE_READY2     3'b101
`define NEW_NOTE_READY3     3'b110


module song_reader(
    input clk,
    input reset,
    input play,
    input [1:0] song, //specifies which song in the RAM
    input note_done1,
    input note_done2,
    input note_done3,
    output wire song_done, //when address = 512, and overflows into 10th bit
    output wire [5:0] note1, 
    output wire [5:0] note2,
    output wire [5:0] note3,
    output wire [5:0] duration1,
    output wire [5:0] duration2,
    output wire [5:0] duration3,
    output wire new_note1,
    output wire new_note2,
    output wire new_note3
);

    //check if all wire reg declared properly later 
    wire [`SONG_WIDTH-1:0] curr_note_num; 
    reg  [`SONG_WIDTH-1:0] next_note_num; //7 bits wide; 128 notes
    wire [`NOTE_WIDTH + `DURATION_WIDTH + `TYPE_WIDTH + `METADATA -1:0] rom_contents;
    wire [`SONG_WIDTH + 1:0] rom_addr = {song, curr_note_num};

    wire [`SWIDTH-1:0] state;
    reg  [`SWIDTH-1:0] next;
    

    //time we want note player to play based off the '1-starting' time advance notes
    wire [`DURATION_WIDTH:0] time_advance;
    
    // For identifying when we reach the end of a song
    reg overflow;


    
    dffr #(`SONG_WIDTH) note_counter ( //tracks which note we are on of the 128 notes
        .clk(clk),
        .r(reset),
        .d(next_note_num),
        .q(curr_note_num)
    );
    dffr #(`SWIDTH) fsm ( //keeps track of states
        .clk(clk),
        .r(reset),
        .d(next),
        .q(state)
    );

    reg  next_note_ready1, next_note_ready2, next_note_ready3;
    wire curr_note_ready1, curr_note_ready2, curr_note_ready3;

    dff note_ready1 ( //tracks which note players are ready to load. 1 if empty, 0 if currently playing another note
        .clk(clk),
        .d(next_note_ready1),
        .q(curr_note_ready1)
    );
    
    dff note_ready2 ( 
        .clk(clk),
        .d(next_note_ready2),
        .q(curr_note_ready2)
    );
    
    dff note_ready3 ( 
        .clk(clk),
        .d(next_note_ready3),
        .q(curr_note_ready3)
    );

    reg next_note_on1, next_note_on2, next_note_on3;
    wire curr_note_on1, curr_note_on2, curr_note_on3;

    dffre note_on1 (
        .clk(clk),
        .r(reset),
        .en(new_note1),
        .d(next_note_on1),
        .q(curr_note_on1)
    );

    dffre note_on2 (
        .clk(clk),
        .r(reset),
        .en(new_note2),
        .d(next_note_on2),
        .q(curr_note_on2)
    );

    dffre note_on3 (
        .clk(clk),
        .r(reset),
        .en(new_note3),
        .d(next_note_on3),
        .q(curr_note_on3)
    );

always @(*) begin
    if (reset) begin
        next_note_ready1 = 1'b0;
        end else begin
        next_note_ready1 = !curr_note_ready1;
    end
    if (reset) begin
        next_note_ready2 = 1'b0;
        end else begin
        next_note_ready2 = !curr_note_ready2;
    end
    if (reset) begin
        next_note_ready3 = 1'b0;
        end else begin
        next_note_ready3 = !curr_note_ready3;
    end
end
    

    song_rom rom(.clk(clk), .addr(rom_addr), .dout(rom_contents));
    //For identifying note type
    wire type;
    assign type = rom_contents[15];

   //assign next_note_ready and curr_note_ready
always @(*) begin
    if (reset || note_done1) begin
        next_note_ready1 = 1'b1; 
        end else if (new_note1) begin
        next_note_ready1 = 1'b0;
        end else begin
        next_note_ready1 = curr_note_ready1;
    end

        if (reset || note_done2) begin
        next_note_ready2 = 1'b1; 
        end else if (new_note2) begin
        next_note_ready2 = 1'b0;
        end else begin
        next_note_ready2 = curr_note_ready2;
    end

        if (reset || note_done3) begin
            next_note_ready3 = 1'b1; 
        end else if (new_note3) begin
        next_note_ready3 = 1'b0;
        end else begin
        next_note_ready3 = curr_note_ready3;
        end
    end
        
    
    always @(*) begin //FSM 
        case (state)
            `PAUSED:            next = play ? `RETRIEVE_NOTE : `PAUSED;
            `RETRIEVE_NOTE:     next = !play ? `PAUSED : 
                                    type ? `WAIT: //is the ROM_contents MSB 1 --> if it isnt then we have a MUSIC note
                                    curr_note_ready1 ? `NEW_NOTE_READY1 :
                                    curr_note_ready2 ? `NEW_NOTE_READY2 :
                                    curr_note_ready3 ? `NEW_NOTE_READY3 :
                                    `WAIT;                     
            `NEW_NOTE_READY1:    next = play ? `INCREMENT_ADDRESS : `PAUSED; //logic works if note/duration outputs are allowed to 'pulse' and latch as inputs to NP
            `NEW_NOTE_READY2:    next = play ? `INCREMENT_ADDRESS : `PAUSED;
            `NEW_NOTE_READY3:    next = play ? `INCREMENT_ADDRESS : `PAUSED;
            `WAIT:              next = !play ? `PAUSED : note_done1 ? `INCREMENT_ADDRESS : `WAIT;
            `INCREMENT_ADDRESS: next = (play && ~overflow) ? `RETRIEVE_NOTE
                                                           : `PAUSED;
            default:            next = `PAUSED;
        endcase
    end
    
           

    
    //handles song_done logic      
     always @(*) begin
        if (state == `INCREMENT_ADDRESS) begin 
            {overflow, next_note_num} = {1'b0, curr_note_num} + 1;
        end else begin 
            {overflow, next_note_num} = {1'b0, curr_note_num};
        end 
end 
    
    
    assign song_done = overflow;

    //handles time_advance and time_advance_ready logic
    assign time_advance = (next == `WAIT) ? rom_contents[8:3] : 6'b0;

    //handles new_note logic; 
    assign new_note1 = (state == `NEW_NOTE_READY1) ? 1'b1 : 1'b0;
    assign new_note2 = (state == `NEW_NOTE_READY2) ? 1'b1 : 1'b0;
    assign new_note3 = (state == `NEW_NOTE_READY3) ? 1'b1 : 1'b0;

    //if new_note1 is on, then load note/duration values into note1 and duration1. These values should pulse since new note pulses
    assign {note1, duration1} = (curr_note_on1) ? {rom_contents[14:9], time_advance} : 12'b0;
    assign {note2, duration2} = (curr_note_on2) ? {rom_contents[14:9], time_advance} : 12'b0;
    assign {note3, duration3} = (curr_note_on3) ? {rom_contents[14:9], time_advance} : 12'b0;

endmodule
