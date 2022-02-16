`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Clock divider - divides main clock to VGA pixel clock
//////////////////////////////////////////////////////////////////////////////////

module clk_div#
	(
		parameter   							DIV = 2
	)
    (
        input 									clk,
        input 									rst,
		
        output 									clk_div_o
    );
	//Calculate needed width of counter
	localparam CNT_W = $clog2(DIV - 1);
	
    logic [CNT_W - 1:0] cnt_r = 0;
    logic clk_div_r;
    
	//Count unless reset
    always @ (posedge clk) 
    begin
	    if(rst)
        begin
            cnt_r <= 0;
        end
        else
		begin
			if( clk_div_r )
			begin
				cnt_r <= 0;
			end
			else
			begin
				cnt_r <= cnt_r + 1;
			end
		end
    end
    
	//Output a single clock pulse once the counter overflows
    assign clk_div_r = (cnt_r == (DIV - 1));
    assign clk_div_o = clk_div_r;
    
endmodule