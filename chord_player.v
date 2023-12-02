module chord_player(
   input wire [5:0] time_advance, //2. outputs how much time note player should spend playing the note 
   input wire time_advance_ready //3. pulses up when we have new time_advance value 
   input wire song_done, //when address = 512, and overflows into 10th bit
   input wire [5:0] note1, 
   input wire [5:0] note2,
   input wire [5:0] note3,
   input wire [5:0] duration1,
   input wire [5:0] duration2,
   input wire [5:0] duration3,
   input wire new_note1,
   input wire new_note2,
   input wire new_note3
);
