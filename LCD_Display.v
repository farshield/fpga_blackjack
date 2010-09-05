module	LCD_Display (	//	Host Side
					iCLK,iRST_N,
					// Blackjack
					hand, victory, defeat,
					//	LCD Side
					LCD_DATA,LCD_RW,LCD_EN,LCD_RS	);
//	Host Side
input			iCLK,iRST_N;
//  Blackjack side
input [4:0] hand;
input victory;
input defeat;
//	LCD Side
output	[7:0]	LCD_DATA;
output			LCD_RW,LCD_EN,LCD_RS;
//	Internal Wires/Registers
reg	[5:0]	LUT_INDEX;
reg	[8:0]	LUT_DATA;
reg	[5:0]	mLCD_ST;
reg	[17:0]	mDLY;
reg			mLCD_Start;
reg	[7:0]	mLCD_DATA;
reg			mLCD_RS;
wire		mLCD_Done;

parameter	LCD_INTIAL	=	0;
parameter	LCD_LINE1	=	5;
parameter	LCD_CH_LINE	=	LCD_LINE1+16;
parameter	LCD_LINE2	=	LCD_LINE1+16+1;
parameter	LUT_SIZE	=	LCD_LINE1+32+1;

always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		LUT_INDEX	<=	0;
		mLCD_ST		<=	0;
		mDLY		<=	0;
		mLCD_Start	<=	0;
		mLCD_DATA	<=	0;
		mLCD_RS		<=	0;
	end
	else
	begin
		if(LUT_INDEX<LUT_SIZE)
		begin
			case(mLCD_ST)
			0:	begin
					mLCD_DATA	<=	LUT_DATA[7:0];
					mLCD_RS		<=	LUT_DATA[8];
					mLCD_Start	<=	1;
					mLCD_ST		<=	1;
				end
			1:	begin
					if(mLCD_Done)
					begin
						mLCD_Start	<=	0;
						mLCD_ST		<=	2;					
					end
				end
			2:	begin
					if(mDLY<18'h3FFFE) //262142
					mDLY	<=	mDLY+1;
					else
					begin
						mDLY	<=	0;
						mLCD_ST	<=	3;
					end
				end
			3:	begin
					LUT_INDEX	<=	LUT_INDEX+1;
					mLCD_ST	<=	0;
				end
			endcase
		end
		else
		begin
			LUT_INDEX <= LCD_LINE1 + 8;
		end
	end
end

always
begin
	case(LUT_INDEX)
	//	Initial
	LCD_INTIAL+0:	LUT_DATA	<=	9'h038; //8 bit mode, 2 line, 5*8 font
 	LCD_INTIAL+1:	LUT_DATA	<=	9'h00C; //display ON, cursor OFF, blink OFF
	LCD_INTIAL+2:	LUT_DATA	<=	9'h001; //Clear display
	LCD_INTIAL+3:	LUT_DATA	<=	9'h006; //entry mode set: increase cursor position, scroll display OFF
	LCD_INTIAL+4:	LUT_DATA	<=	9'h080; //set DDRAM address to 0 (first line)
	//	Line 1
	LCD_LINE1+0:	LUT_DATA	<=	9'h150; //Points:_0x
	LCD_LINE1+1:	LUT_DATA	<=	9'h16F;
	LCD_LINE1+2:	LUT_DATA	<=	9'h169;
	LCD_LINE1+3:	LUT_DATA	<=	9'h16E;
	LCD_LINE1+4:	LUT_DATA	<=	9'h174;
	LCD_LINE1+5:	LUT_DATA	<=	9'h173;
	LCD_LINE1+6:	LUT_DATA	<=	9'h13A;
	LCD_LINE1+7:	LUT_DATA	<=	9'h120;
	LCD_LINE1+8:	LUT_DATA	<=	9'h088; //** Set cursor to overwrite number (DDRAM address)
	LCD_LINE1+9:	begin
						/*if (hand[4] == 1'b1)
							LUT_DATA	<=	9'h131;
						else
							LUT_DATA	<=	9'h130;*/
						LUT_DATA[8] <= 1'b1;
						LUT_DATA[7:0] <= 48+hand/10;
					end
	LCD_LINE1+10:	begin
						/*case (hand[3:0])
							4'b0000: LUT_DATA	<=	9'h130;
							4'b0001: LUT_DATA	<=	9'h131;
							4'b0010: LUT_DATA	<=	9'h132;
							4'b0011: LUT_DATA	<=	9'h133;
							4'b0100: LUT_DATA	<=	9'h134;
							4'b0101: LUT_DATA	<=	9'h135;
							4'b0110: LUT_DATA	<=	9'h136;
							4'b0111: LUT_DATA	<=	9'h137;
							4'b1000: LUT_DATA	<=	9'h138;
							4'b1001: LUT_DATA	<=	9'h139;
							4'b1010: LUT_DATA	<=	9'h141;
							4'b1011: LUT_DATA	<=	9'h142;
							4'b1100: LUT_DATA	<=	9'h143;
							4'b1101: LUT_DATA	<=	9'h144;
							4'b1110: LUT_DATA	<=	9'h145;
							4'b1111: LUT_DATA	<=	9'h146;
							default: LUT_DATA	<=	9'h130;
						endcase*/
						LUT_DATA[8] <= 1'b1;
						LUT_DATA[7:0] <= 48+hand%10;
					end
	LCD_LINE1+11:	LUT_DATA	<=	9'h120;
	LCD_LINE1+12:	LUT_DATA	<=	9'h120;
	LCD_LINE1+13:	LUT_DATA	<=	9'h120;
	LCD_LINE1+14:	LUT_DATA	<=	9'h120;
	LCD_LINE1+15:	LUT_DATA	<=	9'h120;
	//	Change Line
	LCD_CH_LINE:	LUT_DATA	<=	9'h0C0; //Set DDRAM address to 64 (2nd line)
	//	Line 2
	LCD_LINE2+0:	LUT_DATA	<=	9'h120;
	LCD_LINE2+1:	begin
						case ({victory, defeat})
							2'b10: LUT_DATA	<=	9'h156;
							2'b01: LUT_DATA	<=	9'h144;
							default: LUT_DATA	<=	9'h120;
						endcase
					end
	LCD_LINE2+2:	begin
						case ({victory, defeat})
							2'b10: LUT_DATA	<=	9'h169;
							2'b01: LUT_DATA	<=	9'h165;
							default: LUT_DATA	<=	9'h120;
						endcase
					end
	LCD_LINE2+3:	begin
						case ({victory, defeat})
							2'b10: LUT_DATA	<=	9'h163;
							2'b01: LUT_DATA	<=	9'h166;
							default: LUT_DATA	<=	9'h120;
						endcase
					end
	LCD_LINE2+4:	begin
						case ({victory, defeat})
							2'b10: LUT_DATA	<=	9'h174;
							2'b01: LUT_DATA	<=	9'h165;
							default: LUT_DATA	<=	9'h120;
						endcase
					end
	LCD_LINE2+5:	begin
						case ({victory, defeat})
							2'b10: LUT_DATA	<=	9'h16F;
							2'b01: LUT_DATA	<=	9'h161;
							default: LUT_DATA	<=	9'h120;
						endcase
					end
	LCD_LINE2+6:	begin
						case ({victory, defeat})
							2'b10: LUT_DATA	<=	9'h172;
							2'b01: LUT_DATA	<=	9'h174;
							default: LUT_DATA	<=	9'h120;
						endcase
					end
	LCD_LINE2+7:	begin
						case ({victory, defeat})
							2'b10: LUT_DATA	<=	9'h179;
							2'b01: LUT_DATA	<=	9'h120;
							default: LUT_DATA	<=	9'h120;
						endcase
					end
	LCD_LINE2+8:	LUT_DATA	<=	9'h120;
	LCD_LINE2+9:	LUT_DATA	<=	9'h120;
	LCD_LINE2+10:	LUT_DATA	<=	9'h120;
	LCD_LINE2+11:	LUT_DATA	<=	9'h120;
	LCD_LINE2+12:	LUT_DATA	<=	9'h120;
	LCD_LINE2+13:	LUT_DATA	<=	9'h120;
	LCD_LINE2+14:	LUT_DATA	<=	9'h120;
	LCD_LINE2+15:	LUT_DATA	<=	9'h120;
	default:		LUT_DATA	<=	9'h000; //This is not a valid instruction
	endcase
end

LCD_Controller 		u0	(	//	Host Side
							.iDATA(mLCD_DATA),
							.iRS(mLCD_RS),
							.iStart(mLCD_Start),
							.oDone(mLCD_Done),
							.iCLK(iCLK),
							.iRST_N(iRST_N),
							//	LCD Interface
							.LCD_DATA(LCD_DATA),
							.LCD_RW(LCD_RW),
							.LCD_EN(LCD_EN),
							.LCD_RS(LCD_RS)	);

endmodule
