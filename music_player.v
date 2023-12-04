//
//  music_player module
//
//  This music_player module connects up the MCU, song_reader, note_player,
//  beat_generator, and codec_conditioner. It provides an output that indicates
//  a new sample (new_sample_generated) which will be used in lab 5.
//

module music_player(
    // Standard system clock and reset
    input clk,
    input reset,

    // Our debounced and one-pulsed button inputs.
    input play_button,
    input next_button,

    // The raw new_frame signal from the ac97_if codec.
    input new_frame,

    // This output must go high for one cycle when a new sample is generated.
    output wire new_sample_generated,

    // Our final output sample to the codec. This needs to be synced to
    // new_frame.
    output wire [15:0] sample_out
);
    // The BEAT_COUNT is parameterized so you can reduce this in simulation.
    // If you reduce this to 100 your simulation will be 10x faster.
    parameter BEAT_COUNT = 1000;


//
//  ****************************************************************************
//      Master Control Unit
//  ****************************************************************************
//   The reset_player output from the MCU is run only to the song_reader because
//   we don't need to reset any state in the note_player. If we do it may make
//   a pop when it resets the output sample.
//
 
    wire play;
    wire reset_player;
    wire [1:0] current_song;
    wire song_done;
    mcu mcu(
        .clk(clk),
        .reset(reset),
        .play_button(play_button),
        .next_button(next_button),
        .play(play),
        .reset_player(reset_player),
        .song(current_song),
        .song_done(song_done)
    );

//
//  ****************************************************************************
//      Song Reader
//  ****************************************************************************
//
    wire [5:0] note_to_play1;
    wire [5:0] note_to_play2;
    wire [5:0] note_to_play3;
    wire [5:0] duration_for_note1;
    wire [5:0] duration_for_note2;
    wire [5:0] duration_for_note3;
    wire new_note1;
    wire new_note2;
    wire new_note3;
    wire note_done1;
    wire note_done2;
    wire note_done3;
    

    song_reader song_reader(
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
        .new_note3(new_note3),
    );

//   
//  ****************************************************************************
//      Chord Player
//  ****************************************************************************
//  
    wire beat;
    wire generate_next_sample;
    wire [15:0] note_sample;
    wire note_sample_ready;

    chord_player chord_player(
        .clk(clk),
        .rst(reset),
        .play_enable(play),
        .note_to_load1(note_to_play1),
        .note_to_load2(note_to_play2),
        .note_to_load3(note_to_play3),
        .duration_to_load1(duration_for_note1),
        .duration_to_load2(duration_for_note2),
        .duration_to_load3(duration_for_note3),
        .load_new_note1(new_note1),
        .load_new_note2(new_note2),
        .load_new_note3(new_note3),
        .done_with_note1(note_done1),
        .done_with_note2(note_done2),
        .done_with_note3(note_done3),
        .beat(beat),
        .generate_next_sample(generate_next_sample),
        .sample_out(note_sample),
        .new_sample_ready(note_sample_ready)
    );
      
//   
//  ****************************************************************************
//      Beat Generator
//  ****************************************************************************
//  By default this will divide the generate_next_sample signal (48kHz from the
//  codec's new_frame input) down by 1000, to 48Hz. If you change the BEAT_COUNT
//  parameter when instantiating this you can change it for simulation.
//  
    beat_generator #(.WIDTH(10), .STOP(BEAT_COUNT)) beat_generator(
        .clk(clk),
        .reset(reset),
        .en(generate_next_sample),
        .beat(beat)
    );

//  
//  ****************************************************************************
//      Codec Conditioner
//  ****************************************************************************
//  
    assign new_sample_generated = generate_next_sample;
    codec_conditioner codec_conditioner(
        .clk(clk),
        .reset(reset),
        .new_sample_in(note_sample),
        .latch_new_sample_in(note_sample_ready),
        .generate_next_sample(generate_next_sample),
        .new_frame(new_frame),
        .valid_sample(sample_out)
    );

endmodule
