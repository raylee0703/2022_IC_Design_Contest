module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output [3:0] MatchCount,
output [9:0] MinCost,
output Valid );

parameter INIT  = 4'b0000;
parameter COMP  = 4'b0001;
parameter CHAN  = 4'b0010;
parameter FIND  = 4'b0011;
parameter EXCH  = 4'b0100;
parameter REV   = 4'b0101;
parameter GIVE  = 4'b0110;
parameter COUNT = 4'b0111;
parameter VALID = 4'b1000;

reg [3:0] curr_state;
reg [3:0] next_state;

parameter [0:3*128-1] mapTbl = {3'd7, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6, 3'd3, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6,
                            	3'd2, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6, 3'd3, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6,
                            	3'd1, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6, 3'd3, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6,
                	            3'd2, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6, 3'd3, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6,
                		  	    3'd0, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6, 3'd3, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6,
                			    3'd2, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6, 3'd3, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6,
                			    3'd1, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6, 3'd3, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6,
                				3'd2, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6, 3'd3, 3'd6, 3'd5, 3'd6, 3'd4, 3'd6, 3'd5, 3'd6};
reg [0:6] compare;
reg [3:0] permutation [0:7];
reg [3:0] permutation_rot [0:7];
reg [3:0] permutation_ex [0:7];


reg [1:0] FIND_count;
wire [2:0] rot;
wire done;
reg [3:0] matchcount;
reg [9:0] mincost;
// FSM
always@(posedge CLK) begin
	if(RST) curr_state <= INIT;
	else    curr_state <= next_state; 
end 

always@(*)begin
	case (curr_state)
	INIT  : next_state = COMP;
	COMP  : next_state = CHAN; // compare each adjacent pair, 1 if left one is less than right one
	CHAN  : next_state = FIND; // change none-candidate elemnet to 8
	FIND  : if(FIND_count==2) next_state = EXCH; // find the minimum
	        else next_state = FIND;
	EXCH  : next_state = REV; // exchange minimum with rotation point
	REV   : next_state = GIVE; // reverse elements on the right side of rotation point
	GIVE  : next_state = COUNT;
	COUNT : if(done) next_state = VALID;
			else next_state = COMP;
	VALID : next_state =  INIT;
	endcase
end


reg [3:0] count;
reg [9:0] cost;

reg start;
always@(posedge CLK) begin
	if(RST) start <= 0;
	else if(~RST) start <= 1;
	else start <= start;
end 

always@(posedge CLK) begin
	if(RST) begin
		W <= 0;
		J <= 0;
		count <= 1;
	end
	else begin
		W <= count >= 8 ? 0 : count;
		J <= permutation[count >= 8 ? 0 : count];
		if(count == 10) begin
			count <= 2;
			W <= 1;
			J <= permutation[1];
		end
		else begin
			count <= count + 1;
		end
	end
end

always@(posedge CLK) begin
	if(curr_state==INIT) begin
		mincost <= 10'd1023;
		matchcount <= 0;
		cost <= 0;
	end
	else if(start)begin
		cost <= cost + Cost;
		if(count == 10) begin
			if(cost < mincost)begin
				mincost <= cost;
				matchcount <= 1;
			end
			else if(cost == mincost)begin
				matchcount <= matchcount + 1;
			end
			cost <= 0;
		end
	end
end

assign MatchCount = matchcount;
assign MinCost = mincost;



always@(posedge CLK)begin
	if(curr_state == COMP) begin
		compare[6] <= permutation[6] < permutation[7];
		compare[5] <= permutation[5] < permutation[6];
		compare[4] <= permutation[4] < permutation[5];
		compare[3] <= permutation[3] < permutation[4];
		compare[2] <= permutation[2] < permutation[3];
		compare[1] <= permutation[1] < permutation[2];
		compare[0] <= permutation[0] < permutation[1];
	end
end

assign rot = mapTbl[compare*3+:3];



always @(posedge CLK) begin
	if(curr_state == CHAN) begin
  		permutation_rot[0] <= 0<=rot || (0>rot && permutation[0]<permutation[rot]) ? 8 : permutation[0];
  		permutation_rot[1] <= 1<=rot || (1>rot && permutation[1]<permutation[rot]) ? 8 : permutation[1];
  		permutation_rot[2] <= 2<=rot || (2>rot && permutation[2]<permutation[rot]) ? 8 : permutation[2];
  		permutation_rot[3] <= 3<=rot || (3>rot && permutation[3]<permutation[rot]) ? 8 : permutation[3];
  		permutation_rot[4] <= 4<=rot || (4>rot && permutation[4]<permutation[rot]) ? 8 : permutation[4];
  		permutation_rot[5] <= 5<=rot || (5>rot && permutation[5]<permutation[rot]) ? 8 : permutation[5];
  		permutation_rot[6] <= 6<=rot || (6>rot && permutation[6]<permutation[rot]) ? 8 : permutation[6];
  		permutation_rot[7] <= 7<=rot || (7>rot && permutation[7]<permutation[rot]) ? 8 : permutation[7];
  	end
end

reg [2:0] minIdx1;
reg [2:0] minIdx2;
reg [2:0] minIdx3;
reg [2:0] minIdx4;
reg [2:0] minIdx11;
reg [2:0] minIdx22;
reg [2:0] minIdx;

always@(posedge CLK)begin
	if(curr_state==INIT) begin
		FIND_count <= 0;
	end
	if(curr_state==FIND && FIND_count==0)begin
		minIdx4 <= permutation_rot[7] > permutation_rot[6] ? 6 : 7;
		minIdx3 <= permutation_rot[5] > permutation_rot[4] ? 4 : 5;
		minIdx2 <= permutation_rot[3] > permutation_rot[2] ? 2 : 3;
		minIdx1 <= permutation_rot[1] > permutation_rot[0] ? 0 : 1;
		FIND_count <= 1;
	end
	else if(curr_state==FIND && FIND_count==1)begin
		minIdx22 <= permutation_rot[minIdx4] > permutation_rot[minIdx3] ? minIdx3 : minIdx4;
		minIdx11 <= permutation_rot[minIdx2] > permutation_rot[minIdx1] ? minIdx1 : minIdx2;
		FIND_count <= 2;
	end
	else if(curr_state==FIND && FIND_count==2)begin
		minIdx <= permutation_rot[minIdx22] > permutation_rot[minIdx11] ? minIdx11 : minIdx22;
		FIND_count <= 0;
	end
	else begin
		FIND_count <= 0;
	end
end


always@(posedge CLK) begin
	if(curr_state==COMP) begin
		permutation_ex[0] <= permutation[0];
		permutation_ex[1] <= permutation[1];
		permutation_ex[2] <= permutation[2];
		permutation_ex[3] <= permutation[3];
		permutation_ex[4] <= permutation[4];
		permutation_ex[5] <= permutation[5];
		permutation_ex[6] <= permutation[6];
		permutation_ex[7] <= permutation[7];
	end
	else if(curr_state==EXCH) begin
		permutation_ex[rot] <= permutation[minIdx];
		permutation_ex[minIdx] <= permutation[rot];
	end
	else if(curr_state == REV)begin
		if(0>rot)
			permutation_ex[0] <= permutation_ex[7-(0-rot-1)];
		if(1>rot)
			permutation_ex[1] <= permutation_ex[7-(1-rot-1)];
		if(2>rot)
			permutation_ex[2] <= permutation_ex[7-(2-rot-1)];
		if(3>rot)
			permutation_ex[3] <= permutation_ex[7-(3-rot-1)];
		if(4>rot)
			permutation_ex[4] <= permutation_ex[7-(4-rot-1)];
		if(5>rot)
			permutation_ex[5] <= permutation_ex[7-(5-rot-1)];
		if(6>rot)
			permutation_ex[6] <= permutation_ex[7-(6-rot-1)];
		if(7>rot)
			permutation_ex[7] <= permutation_ex[7-(7-rot-1)];
		/*
		permutation_ex[0] <= 0>rot ? permutation_ex[7-(0-rot-1)] : permutation_ex[0];
		permutation_ex[1] <= 1>rot ? permutation_ex[7-(1-rot-1)] : permutation_ex[1];
		permutation_ex[2] <= 2>rot ? permutation_ex[7-(2-rot-1)] : permutation_ex[2];
		permutation_ex[3] <= 3>rot ? permutation_ex[7-(3-rot-1)] : permutation_ex[3];
		permutation_ex[4] <= 4>rot ? permutation_ex[7-(4-rot-1)] : permutation_ex[4];
		permutation_ex[5] <= 5>rot ? permutation_ex[7-(5-rot-1)] : permutation_ex[5];
		permutation_ex[6] <= 6>rot ? permutation_ex[7-(6-rot-1)] : permutation_ex[6];
		permutation_ex[7] <= 7>rot ? permutation_ex[7-(7-rot-1)] : permutation_ex[7];
		*/
	end
end

always@(posedge CLK)begin
	if(curr_state == INIT) begin
		permutation[0] <= 0;
		permutation[1] <= 1;
		permutation[2] <= 2;
		permutation[3] <= 3;
		permutation[4] <= 4;
		permutation[5] <= 5;
		permutation[6] <= 6;
		permutation[7] <= 7;
	end
	else if(curr_state == GIVE) begin
		permutation[0] <= permutation_ex[0];
		permutation[1] <= permutation_ex[1];
		permutation[2] <= permutation_ex[2];
		permutation[3] <= permutation_ex[3];
		permutation[4] <= permutation_ex[4];
		permutation[5] <= permutation_ex[5];
		permutation[6] <= permutation_ex[6];
		permutation[7] <= permutation_ex[7];
	end
end

assign done = compare==0;

// valid
assign Valid = (curr_state == VALID);

endmodule


