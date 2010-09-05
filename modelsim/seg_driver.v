//the 7 segment driver

`timescale 1ns/1ns

module seg_driver
(
  input wire[3:0] cif_hexa,
  output reg[6:0] a_seg
);

  always @(cif_hexa)
  begin
    #3
	case (cif_hexa)
		4'b0000 : a_seg = 7'b1000000;
		4'b0001 : a_seg = 7'b1111001;
		4'b0010 : a_seg = 7'b0100100;
		4'b0011 : a_seg = 7'b0110000;
		4'b0100 : a_seg = 7'b0011001;
		4'b0101 : a_seg = 7'b0010010;
		4'b0110 : a_seg = 7'b0000010;
		4'b0111 : a_seg = 7'b1111000;
		4'b1000 : a_seg = 7'b0000000;
		4'b1001 : a_seg = 7'b0010000;
		4'b1010 : a_seg = 7'b0001000;
		4'b1011 : a_seg = 7'b0000011;
		4'b1100 : a_seg = 7'b1000110;
		4'b1101 : a_seg = 7'b0100001;
		4'b1110 : a_seg = 7'b0000110;
		4'b1111 : a_seg = 7'b0001110;
		default : a_seg = 7'b1111111;
	endcase
  end

endmodule
