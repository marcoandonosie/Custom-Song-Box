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

   wire sample_ready1;
   wire sample_ready2;
   wire sample_ready3;


    //I assumed 1st field is name of module, 2nd is name of instantiation
       note_player note_player1(
        .clk(clk),
        .reset(reset),
        .play_enable(play_enable),
          .note_to_load(note_to_load1),
          .duration_to_load(duration_to_load1),
          .load_new_note(load_new_note1),
          .done_with_note(done_with_note1),
        .beat(beat),
        .generate_next_sample(generate_next_sample),
          .sample_out(sample_out1),
          .new_sample_ready(sample_ready1)
    );

   note_player note_player2(
        .clk(clk),
        .reset(reset),
        .play_enable(play_enable),
      .note_to_load(note_to_load2),
      .duration_to_load(duration_to_load2),
      .load_new_note(load_new_note2),
      .done_with_note(done_with_note2),
        .beat(beat),
        .generate_next_sample(generate_next_sample),
      .sample_out(sample_out2),
      .new_sample_ready(sample_ready2)
    );

   note_player note_player3(
        .clk(clk),
        .reset(reset),
        .play_enable(play_enable),
      .note_to_load(note_to_load3),
      .duration_to_load(duration_to_load3),
      .load_new_note(load_new_note3),
      .done_with_note(done_with_note3),
        .beat(beat),
        .generate_next_sample(generate_next_sample),
      .sample_out(sample_out3),
      .new_sample_ready(sample_ready3)
    );


    wire new_sample_ready1;
    wire new_sample_ready2;
    wire new_sample_ready3;

    assign new_sample_ready1 = (reset) ? 1'b0 : sample_ready1;
    assign new_sample_ready2 = (reset) ? 1'b0 : sample_ready2;
    assign new_sample_ready3 = (reset) ? 1'b0 : sample_ready3;
        

    
   //a new sample is ready if any of the 3 noteplayers have released a sample
   assign new_sample_ready = (new_sample_ready1 || new_sample_ready2 || new_sample_ready3);

    wire [17:0] total_sample_out;
    assign total_sample_out = ($signed(sample_out1) + $signed(sample_out2) + $signed(sample_out3));
    assign sample_out = total_sample_out[17:2];

   
  endmodule
