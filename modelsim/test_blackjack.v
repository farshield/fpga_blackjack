//the testbench

`timescale 1ns/1ns

module test_blackjack;
  parameter RESET_ST = 0;
  parameter START_ST = 1;
  parameter APPLY_DATA_ST = 2;
  parameter DO_NOTHING_ST = 3;
  
  parameter NR_TESTS = 10;
  
  reg clk, rst, begin_s;
  reg[3:0] cval;
  reg opt;
  reg ready;
  
  wire end_s;
  wire request;
  wire[4:0] hand;
  wire victory, defeat;
  wire[6:0] seg_ace, seg_nr_cards;
  wire[2:0] ace;
  wire[3:0] nr_cards;
  wire[3:0] debug_state;
  
  blackjack black_test(begin_s, clk, rst, cval, ready, opt, end_s, request, hand, 
                        victory, defeat, seg_ace, seg_nr_cards, ace, nr_cards, debug_state);
  
  //40 ns clock generator, 1/2 duty cycle
  always
    #20 clk = ~clk;
  
  //STUFF BEGINS
  
  integer test_state;
  integer test_case;
  
  reg[3:0] card[NR_TESTS - 1:0];
  reg opt_val[NR_TESTS - 1:0];
  
  initial
  begin
    clk = 1'b0;
    test_state = RESET_ST;
    test_case = 0;
    
    //from card deck
    card[0] = 11;
    card[1] = 9;
    card[2] = 3;
    card[3] = 5;
    card[4] = 6;
    card[5] = 10;
    card[6] = 10;
    card[7] = 11;
    card[8] = 7;
    card[9] = 5;
    
    //user option
    opt_val[0] = 0;
    opt_val[1] = 0;
    opt_val[2] = 0;
    opt_val[3] = 0; //ex: this is the option after card[2] is in hand
    opt_val[4] = 1; //stand after card[3] has been inserted (stand at 18 points in hand)
    opt_val[5] = 0;
    opt_val[6] = 0;
    opt_val[7] = 0;
    opt_val[8] = 0;
    opt_val[9] = 0;
  end
  
  always @(negedge clk)
  begin
    case (test_state)
      RESET_ST:
        begin
          rst <= 1'b0;
          begin_s <= 1'b0;
          
          test_state = START_ST;
        end
        
      START_ST:
        begin
          rst <= 1'b1;
          begin_s <= 1'b1;
          ready <= 1'b1;
          
          test_state = APPLY_DATA_ST;
        end
      
      APPLY_DATA_ST:
        begin
          case (debug_state)
            4'b0010:
              begin
                opt <= opt_val[test_case];
              end
            4'b0101:
              begin
                cval <= card[test_case];
                test_case = test_case + 1;
              end
            default:
              begin
                opt <= 1'b0;
                cval <= 4'b0000;
              end
          endcase
          
          if ( (test_case == NR_TESTS) || (end_s == 1'b1) )
            test_state = DO_NOTHING_ST;
        end
      
      DO_NOTHING_ST:
        begin
          opt <= 1'b0;
          cval <= 4'b0000;
        end
      
      default: test_state = RESET_ST;
    endcase
  end
  
endmodule
