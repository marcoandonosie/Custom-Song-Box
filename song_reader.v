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
    input time_elapsed, //1. pulses up when we're done advancing time in a MSB-1 note 
    output wire [5:0] time_advance, //2. outputs how much time note player should spend playing the note 
    output wire time_advance_ready //3. pulses up when we have new time_advance value 
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
    
    wire [`SONG_WIDTH-1:0] curr_note_num, next_note_num; //7 bits wide; 128 notes
    wire [`NOTE_WIDTH + `DURATION_WIDTH + `TYPE_WIDTH + `METADATA -1:0] rom_contents;
    wire [`SONG_WIDTH + 1:0] rom_addr = {song, curr_note_num};

    wire [`SWIDTH-1:0] state;
    reg  [`SWIDTH-1:0] next;
    
    // For identifying when we reach the end of a song
    wire overflow;

    
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

    wire next_note_ready1;
    wire next_note_ready2;
    wire next_note_ready3;
    wire curr_note_ready1;
    wire curr_note_ready2;
    wire curr_note_ready3;

    dffr note_ready1 ( //tracks which note players are ready to load. 1 if empty, 0 if currently playing another note
        .clk(clk),
        .r(reset),
        .d(next_note_ready1),
        .q(curr_note_ready1)
    );
    
    dffr note_ready2 ( 
        .clk(clk),
        .r(reset),
        .d(next_note_ready2),
        .q(curr_note_ready2)
    );
    
    dffr note_ready3 ( 
        .clk(clk),
        .r(reset),
        .d(next_note_ready3),
        .q(curr_note_ready3)
    );
        

    song_rom rom(.clk(clk), .addr(rom_addr), .dout(rom_contents));
    

    always @(*) begin //tells us if note is ready or not
        next_note_ready_1 = (reset) ? 1'b1 : (note_done1) ? 1'b1 : (new_note1 ? 1'b0 : curr_note_ready_1);
        next_note_ready_2 = (reset) ? 1'b1 : (note_done2) ? 1'b1 : (new_note2 ? 1'b0 : curr_note_ready_2);
        next_note_ready_3 = (reset) ? 1'b1 : (note_done3) ? 1'b1 : (new_note3 ? 1'b0 : curr_note_ready_3);
    end
            

    always @(*) begin //FSM 
        case (state)
            `PAUSED:            next = play ? `RETRIEVE_NOTE : `PAUSED;
            `RETRIEVE_NOTE:     next = !play ? `PAUSED : 
                                    rom_contents[15] ? `WAIT: //is the ROM_contents MSB 1 --> if it isnt then we have a MUSIC note
                                    curr_note_ready1 ? `NEW_NOTE_READY1 :
                                    curr_note_ready2 ? `NEW_NOTE_READY2 :
                                    `NEW_NOTE_READY3;
            `NEW_NOTE_READY1:    next = play ? `INCREMENT_ADDRESS : `PAUSED; //logic works if note/duration outputs are allowed to 'pulse' and latch as inputs to NP
            `NEW_NOTE_READY2:    next = play ? `INCREMENT_ADDRESS : `PAUSED;
            `NEW_NOTE_READY3:    next = play ? `INCREMENT_ADDRESS : `PAUSED;
            `WAIT:              next = !play ? `PAUSED // pass time_advance as an input to ALL note_player modules
                                             : time_elapsed ? `INCREMENT_ADDRESS 
                                             : `WAIT;
            `INCREMENT_ADDRESS: next = (play && ~overflow) ? `RETRIEVE_NOTE
                                                           : `PAUSED;
            default:            next = `PAUSED;
        endcase
    end

            
    //handles song_done logic        
    assign {overflow, next_note_num} =
        (state == `INCREMENT_ADDRESS) ? {1'b0, curr_note_num} + 1
                                      : {1'b0, curr_note_num};
    assign song_done = overflow;

    //handles time_elapsed logic;
    assign time_elapsed = (state = `WAIT) ? rom_contents[8:3] : 6'b0;

    //handles time_advance and time_advance_ready logic
    assign time_advance_ready = (state == `WAIT);
    assign time_advance = (state == `WAIT) ? rom_contents[8:3] : 6'b0;

    //handles new_note logic; 
    assign new_note1 = (state == `NEW_NOTE_READY1);
    assign new_note2 = (state == `NEW_NOTE_READY2);
    assign new_note3 = (state == `NEW_NOTE_READY3);

    //if new_note1 is on, then load note/duration values into note1 and duration1
    assign {note1, duration1} = (new_note1) ? rom_contents[14:3] : 12'b0;
    assign {note1, duration2} = (new_note2) ? rom_contents[14:3] : 12'b0;
    assign {note1, duration3} = (new_note3) ? rom_contents[14:3] : 12'b0;

endmodule
