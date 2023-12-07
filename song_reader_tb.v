module song_reader_tb();

    reg clk, reset, play, note_done1, note_done2, note_done3, reset_player;
    reg [1:0] current_song;
    wire [5:0] note_to_play1, note_to_play2, note_to_play3;
    wire [5:0] duration_for_note1, duration_for_note2, duration_for_note3;
    wire song_done, new_note1, new_note2, new_note3;
    

    song_reader dut(
        .clk(clk),
        .reset(reset | reset_player),
        .play(play),
        .song(current_song),
        .note_done1(note_done1),
        .note_done2(note_done2),
        .note_done3(note_done3),
        .song_done(song_done),
        .note1(note_to_play1),
        .note2(note_to_play2),
        .note3(note_to_play3),
        .duration1(duration_for_note1),
        .duration2(duration_for_note2),
        .duration3(duration_for_note3),
        .new_note1(new_note1),
        .new_note2(new_note2),
        .new_note3(new_note3)
    );

    // Clock and reset
    initial begin
        clk = 1'b0;
        reset = 1'b1;
        repeat (4) #5 clk = ~clk;
        reset = 1'b0;
        forever #5 clk = ~clk;
    end

    // Tests
    initial begin
        #1
        play = 1'b1;
        current_song = 2'b0;
        note_done1 = 1'b0;
        note_done2 = 1'b0;
        note_done3 = 1'b0;
    
        $display ("Playing first three notes of song %d : %d, %d, %d", current_song, note_to_play1, note_to_play2, note_to_play3);
        $display ("Their durations are : %d, %d, %d", duration_for_note1, duration_for_note2, duration_for_note3);
        
        #240
        
        note_done1 = 1'b1;
        note_done2 = 1'b1;
        note_done3 = 1'b1;
        
        $display ("Playing first three notes of song %d : %d, %d, %d", current_song, note_to_play1, note_to_play2, note_to_play3);
        $display ("Their durations are : %d, %d, %d", duration_for_note1, duration_for_note2, duration_for_note3);
        
        
    end

endmodule
