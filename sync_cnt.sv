`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Counter for one axis of VGA display
//////////////////////////////////////////////////////////////////////////////////

module sync_cnt#
(
	parameter   							DISLAY_LEN = 480,
	
	parameter   							PORCH_POL = 1,
	
	parameter   							FRONT_PORCH = 16,
	parameter   							SYNC_PULSE = 96,
	parameter   							BACK_PORCH = 48
)
(
	input               					clk,				//Clock input
	input               					rst,				//Global reset
	
	input               					inc_i,				//Increment Counter
	output              					sync_o,				//Sync signal
	output              					display_o,			//Display active
	output              					disp_done_o,		//Display area done
	output [CNT_W-1:0]  					pos_o,				//Counter position
	output              					done_o				//Counter done

	
);
    
	//Timing parameters
    localparam CNT_MAX = DISLAY_LEN+FRONT_PORCH+SYNC_PULSE+BACK_PORCH-1;
	
    localparam SYNC_PULSE_START = DISLAY_LEN+FRONT_PORCH;
    localparam SYNC_PULSE_END = DISLAY_LEN+FRONT_PORCH+SYNC_PULSE;
	
    localparam CNT_W = $clog2(CNT_MAX);
    
    reg [CNT_W-1:0] cnt_r = 0;
    reg             done_r = 0;
    
    
    always @ (posedge clk) 
    begin
        if(rst)
        begin
            cnt_r <= 0;
        end
        else
        begin
			done_r <= 0;
            if(inc_i)
            begin
				//Count on increment input
				if(cnt_r < (CNT_MAX - 1))
                begin
                    cnt_r <= cnt_r + 1;
                end
				//Reset when we reach the end of the display, send reset signal
                else
                begin
                    cnt_r <= 0;
                    done_r <= 1;
                end
            end
        end
    end
    
	//Sync pulse defined by parameters
    assign sync_o = ((cnt_r >= SYNC_PULSE_START) && (cnt_r < SYNC_PULSE_END)) ^^ (!PORCH_POL);
    assign display_o = cnt_r < DISLAY_LEN;
    assign disp_done_o = (cnt_r == DISLAY_LEN) && inc_i;
    
    assign pos_o = display_o ? cnt_r : 0;
    assign done_o = done_r;
    
endmodule
