module music_player_tb();

  
  reg clk, reset, play, next;
  wire new_frame, new_sample_generated;
  wire [15:0] sample_out;


  music_player dut(
    .clk(clk), //input
    .reset(reset). //input
    .play_button(play),
    .next_button(next),
    .new_frame(new_frame),
    new_sample_generated(new_sample_generated),
    .sample_out(sample_out)
  )

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
        #10
      play_button = 1'b1;
      next_button = 1'b0;
      new_frame = 1'b0
    
        
        $display ("Playing first three notes of song %d : %d, %d, %d", current_song, note_to_play1, note_to_play2, note_to_play3);
        $display ("Their durations are : %d, %d, %d", duration_for_note1, duration_for_note2, duration_for_note3);
        
        
    end

endmodule






module music_player_tb();
    reg clk, reset, next_button, play_button;
    wire new_frame;
    wire [15:0] sample;

    music_player #(.BEAT_COUNT(500)) music_player(
        .clk(clk),
        .reset(reset),
        .next_button(next_button),
        .play_button(play_button),
        .new_frame(new_frame),
        .sample_out(sample)
    );

    // AC97 interface
    wire AC97Reset_n;        // Reset signal for AC97 controller/clock
    wire SData_Out;          // Serial data out (control and playback data)
    wire Sync;               // AC97 sync signal

    // Our codec simulator
    ac97_if codec(
        .Reset(1'b0), // Reset MUST be shorted to 1'b0
        .ClkIn(clk),
        .PCM_Playback_Left(sample),   // Set these two to different
        .PCM_Playback_Right(sample),  // samples to have stereo audio!
        .PCM_Record_Left(),
        .PCM_Record_Right(),
        .PCM_Record_Valid(),
        .PCM_Playback_Accept(new_frame),  // Asserted each sample
        .AC97Reset_n(AC97Reset_n),
        .AC97Clk(1'b0),
        .Sync(Sync),
        .SData_Out(SData_Out),
        .SData_In(1'b0)
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
    integer delay;
    initial begin
        delay = 2000000;
        play_button = 1'b0;
        next_button = 1'b0;
        @(negedge reset);
        @(negedge clk);

        repeat (25) begin
            @(negedge clk);
        end 

        // Start playing
        $display("Starting playing song 0...");
        @(negedge clk);
        play_button = 1'b1;
        @(negedge clk);
        play_button = 1'b0;

        repeat (delay) begin
            @(negedge clk);
        end

        // Pause  
        $display("Pause...");
        @(negedge clk);
        play_button = 1'b1;
        @(negedge clk);
        play_button = 1'b0;

        repeat (delay/4) begin
            @(negedge clk);
        end


        // Play 
        $display("Resume playing song 0..."); 
        @(negedge clk);
        play_button = 1'b1;
        @(negedge clk);
        play_button = 1'b0;

        repeat (delay) begin
            @(negedge clk);
        end



        // Next Song  
        $display("Next song...");
        @(negedge clk);
        next_button = 1'b1;
        @(negedge clk);
        next_button = 1'b0;

        repeat (delay/8) begin
            @(negedge clk);
        end


        // Play
        $display("Starting playing song 1...");  
        @(negedge clk);
        play_button = 1'b1;
        @(negedge clk);
        play_button = 1'b0;

        repeat (delay) begin
            @(negedge clk);
        end

        $finish;
    end


endmodule
