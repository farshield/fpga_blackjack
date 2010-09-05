module blackjack
(
	input wire IN_LCD_ON,
	
	input wire begin_s,
	input wire clk,  //from button
	input wire iCLK, //from internal oscillator
	input wire rst,
	input wire[3:0] cval, //card value
	input wire ready, //card is ready
	input wire opt, //player option, 1 - stand, 0 - hit
	
	output reg end_s,
	output reg request, //request a card
	
	output wire[6:0] seg_ace, //to 7 segment display #0
	output wire[6:0] seg_nr_cards, //to 7 segment display #1
	
	output wire[3:0] debug_state, //to green LEDs
	
	output wire[7:0] LCD_DATA,
	output wire LCD_RW,
	output wire LCD_EN,
	output wire LCD_RS,
	
	output wire LCD_ON
	//output wire end_lcd
);

//data
reg request_next;
reg[4:0] hand, hand_next;

reg[2:0] ace, ace_next; //number of aces in hand that are valued as 11
reg[3:0] nr_cards, nr_cards_next;

reg victory, victory_next;
reg defeat, defeat_next;

reg opt_buf, opt_buf_next;
reg[3:0] cval_buf, cval_buf_next;

//state registers
reg[3:0] state, state_next;
//control signals
reg[10:0] c;

//assignments
assign debug_state = state;
assign LCD_ON = IN_LCD_ON;

//interconectare module
seg_driver
	seg1(.cif_hexa({1'b0, ace}), .a_seg(seg_ace)); //ace
seg_driver
	seg2(.cif_hexa(nr_cards), .a_seg(seg_nr_cards)); //nr_cards
LCD_Display
	lcd0(iCLK, rst, hand, victory, defeat, LCD_DATA, LCD_RW, LCD_EN, LCD_RS);

/*
LCD_CRTL
	lcd1(hand,defeat,victory,begin_s,rst,iCLK,end_lcd,LCD_DATA,LCD_RW,LCD_EN,LCD_RS);
*/


//control unit - sequential logic
always @(negedge rst or posedge clk)
begin
	if (!rst)
		state <= 0;
	else
		state <= state_next;
end

//control unit - combinational logic
always @(state, begin_s, ready, nr_cards_next, opt_buf_next, cval_buf, hand_next, ace_next)
begin
	c = 0;
	state_next = state;
	
	case (state)
		4'b0000: if (begin_s)
					state_next = 4'b0001;
				 else
					state_next = 4'b0000;
		4'b0001: begin
					if (nr_cards_next < 2)
						state_next = 4'b0011;
					else
						state_next = 4'b0010;
						
					c[0] = 1'b1;
				 end
		4'b0010: begin
					if (opt_buf_next)
						state_next = 4'b1001;
					else
						state_next = 4'b0011;
						
					c[1] = 1'b1;
				 end
		4'b0011: begin
					state_next = 4'b0100;
					c[2] = 1'b1;
				 end
		4'b0100: begin
					if (ready)
						state_next = 4'b0101;
					else
						state_next = 4'b0100;
						
					c[3] = 1'b1;
				 end
				 
		4'b0101: begin
					state_next = 4'b0110;
					c[4] = 1'b1;
				 end
		4'b0110: begin
					if (cval_buf == 4'b1011)
						state_next = 4'b0111;
					else
						begin
							if (hand_next < 21)
								begin
									if (nr_cards_next < 2)
										state_next = 4'b0011;
									else
										state_next = 4'b0010;
								end
							else
								begin
									if (hand_next == 21)
										state_next = 4'b1001;
									else
										begin
											if (ace_next > 0)
												state_next = 4'b1000;
											else
												state_next = 4'b1010;
										end
								end
						end
						
					c[5] = 1'b1;
				 end
				 
		4'b0111: begin
					if (hand_next < 21)
							begin
								if (nr_cards_next < 2)
									state_next = 4'b0011;
								else
									state_next = 4'b0010;
							end
						else
							begin
								if (hand_next == 21)
									state_next = 4'b1001;
								else
									begin
										if (ace_next > 0)
											state_next = 4'b1000;
										else
											state_next = 4'b1010;
									end
							end
							
					c[6] = 1'b1;
				 end
				 
		4'b1000: begin
					if (hand_next < 21)
							begin
								if (nr_cards_next < 2)
									state_next = 4'b0011;
								else
									state_next = 4'b0010;
							end
						else
							begin
								if (hand_next == 21)
									state_next = 4'b1001;
								else
									begin
										if (ace_next > 0)
											state_next = 4'b1000;
										else
											state_next = 4'b1010;
									end
							end
					
					c[7] = 1'b1;
				 end
		
		4'b1001: begin
					state_next = 4'b1011;
					c[8] = 1'b1;
				 end
		4'b1010: begin
					state_next = 4'b1011;
					c[9] = 1'b1;
				 end
		4'b1011: begin
					state_next = 4'b1011;
					c[10] = 1'b1;
				 end
		default: state_next = state;
	endcase
end

//data path - sequential logic
always @(negedge rst or posedge clk)
begin
	if (!rst)
		begin
			request <= 0;
			hand <= 0;
			ace <= 0;
			nr_cards <= 0;
			victory <= 0;
			defeat <= 0;
			opt_buf <= 0;
			cval_buf <= 0;
		end
	else
		begin
			request <= request_next;
			hand <= hand_next;
			ace <= ace_next;
			nr_cards <= nr_cards_next;
			victory <= victory_next;
			defeat <= defeat_next;
			opt_buf <= opt_buf_next;
			cval_buf <= cval_buf_next;
		end
end

//data path - combinational logic
always @(c, cval, opt, request, hand, ace, nr_cards, victory, defeat, opt_buf, cval_buf)
begin
	
	request_next = request;
	hand_next = hand;
	ace_next = ace;
	nr_cards_next = nr_cards;
	victory_next = victory;
	defeat_next = defeat;
	opt_buf_next = opt_buf;
	cval_buf_next = cval_buf;
	
	end_s = 1'b0;
	
	case (c)
		11'b00000000001: begin //c0
							hand_next = 0;
							ace_next = 0;
							nr_cards_next = 0;
							request_next = 0;
							victory_next = 0;
							defeat_next = 0;
							opt_buf_next = 0;
							cval_buf_next = 0;
						 end
		11'b00000000010: begin //c1
							opt_buf_next = opt;
						 end
		11'b00000000100: begin //c2
							request_next = 1'b1;
						 end
		11'b00000001000: begin //c3
						 //NOP
						 end
		11'b00000010000: begin //c4
							cval_buf_next = cval;
							request_next = 1'b0;
						 end
		11'b00000100000: begin //c5
							hand_next = hand + cval_buf;
							nr_cards_next = nr_cards + 4'b0001;
						 end
		11'b00001000000: begin //c6
							ace_next = ace + 3'b001;
						 end
		11'b00010000000: begin //c7
							hand_next = hand - 5'b01010;
							ace_next = ace - 3'b001;
						 end
		11'b00100000000: begin //c8
							victory_next = 1'b1;
						 end
		11'b01000000000: begin //c9
							defeat_next = 1'b1;
						 end
		11'b10000000000: begin //c10
							end_s = 1'b1;
						 end
		default: hand_next = hand;
	endcase
	
end

endmodule
