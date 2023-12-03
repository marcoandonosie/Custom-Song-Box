module chord_player(
    input clk,
    input reset,
    input play_enable,  // When high we play, when low we don't.
   input [5:0] note_to_load1,  // The note to play
   input [5:0] note_to_load2,  // The note to play
   input [5:0] note_to_load3,  // The note to play
   input [5:0] duration_to_load1,  // The duration of the note to play
   input [5:0] duration_to_load2,  // The duration of the note to play
   input [5:0] duration_to_load3,  // The duration of the note to play
    input load_new_note1,  // Tells us when we have a new note to load
   input load_new_note2,  // Tells us when we have a new note to load
   input load_new_note3,  // Tells us when we have a new note to load
    output done_with_note1,  // When we are done with the note this stays high.
   output done_with_note2,  // When we are done with the note this stays high.
   output done_with_note3,  // When we are done with the note this stays high.
    input beat,  // This is our 1/48th second beat
    input generate_next_sample,  // Tells us when the codec wants a new sample
    output [15:0] sample_out,  // Our sample output
    output new_sample_ready  // Tells the codec when we've got a sample
);

   
   wire [15:0] sample_out1;
   wire [15:0] sample_out2;
   wire [15:0] sample_out3;
   wire [17:0] sample_out_unnormalized;

   wire new_sample_ready1;
   wire new_sample_ready2;
   wire new_sample_ready3;
   
       note_player1 note_player(
        .clk(clk),
        .reset(reset),
        .play_enable(play),
          .note_to_load(note_to_load1),
          .duration_to_load(duration_to_load1),
          .load_new_note(load_new_note1),
          .done_with_note(done_with_note1),
        .beat(beat),
        .generate_next_sample(generate_next_sample),
          .sample_out(sample_out1),
          .new_sample_ready(new_sample_ready1)
    );

   note_player2 note_player(
        .clk(clk),
        .reset(reset),
        .play_enable(play),
      .note_to_load(note_to_load2),
      .duration_to_load(duration_to_load2),
      .load_new_note(load_new_note2),
      .done_with_note(done_with_note2),
        .beat(beat),
        .generate_next_sample(generate_next_sample),
      .sample_out(sample_out2),
      .new_sample_ready(new_sample_ready2)
    );

   note_player3 note_player(
        .clk(clk),
        .reset(reset),
        .play_enable(play),
      .note_to_load(note_to_load3),
      .duration_to_load(duration_to_load3),
      .load_new_note(load_new_note3),
      .done_with_note(done_with_note3),
        .beat(beat),
        .generate_next_sample(generate_next_sample),
      .sample_out(sample_out3),
      .new_sample_ready(new_sample_ready3)
    );
   //a new sample is ready if any of the 3 noteplayers have released a sample
   assign note_sample_ready = (new_sample_ready1 || new_sample_ready2 || new_sample_ready3);

   //add the samples together, then divide by 4 via bitshift to avoid clipping
   assign sample_out_unnormalized = (sample_out1 + sample_out2 + sample_out3);
   assign sample_out = sample_out_unnormalized[17:2];
   
   //timer logic should be implemented in SONG_READER; make it so that time_advance NEVER exceeds duration of note, and then feed in time_advance into note player
