// CSE140L  
// see Structural Diagram in Lab2 assignment writeup
// fill in missing connections and parameters
module struct_diag #(parameter NS=60, NH=24, ND=7, NM=12, NDM1=31, NDM2=30, NDM3=28)(
  input Reset,
        Timeset, 	  // manual buttons
        Alarmset,	  //	(five total)
		Minadv,
		Hrsadv,
  		Dayadv,
  		Dateadv,
  		Monthadv,
		Alarmon,
		Pulse,		  // assume 1/sec.
// 6 decimal digit display (7 segment)
  output [6:0] S1disp, S0disp, 	   // 2-digit seconds display
               M1disp, M0disp, 
               H1disp, H0disp,
  			   D0disp,
  			   Month1disp, Month0disp,
  			   Date1disp,  Date0disp,
//                       D0disp,   // for part 2
  output logic Buzz);	           // alarm sounds
// internal connections (may need more)
  logic[6:0] TSec, TMin, THrs, TDay, TDate, TMonth,    // clock/time 
             AMin, AHrs;		   // alarm setting
  logic[6:0] Min, Hrs;
  logic Szero, Mzero, Hzero, Dzero, 	   // "carry out" from sec -> min, min -> hrs, hrs -> days
        TMen, THen, TDen, TDten, TMonthen, AMen, AHen, MNorm, M30, M28, ERst; 


// free-running seconds counter	-- be sure to set parameters on ct_mod_N modules
  ct_mod_N #(.N(NS)) Sct(
// input ports
    .clk(Pulse), .rst(Reset), .en(!Timeset), .earlyrst(), 
// output ports    
    .ct_out(TSec), .z(Szero)
    );
// minutes counter -- runs at either 1/sec or 1/60sec
  ct_mod_N #(.N(NS)) Mct(
    .clk(Pulse), .rst(Reset), .en(TMen), .earlyrst(), .ct_out(TMin), .z(Mzero)
    );
// hours counter -- runs at either 1/sec or 1/60min
  ct_mod_N #(.N(NH)) Hct(
    .clk(Pulse), .rst(Reset), .en(THen), .earlyrst(), .ct_out(THrs), .z(Hzero) //Add Hzero in pt2
    );
// Day counter -- runs at either 1/sec or 1/24hr
  ct_mod_N #(.N(ND)) Dct(
    .clk(Pulse), .rst(Reset), .en(TDen), .earlyrst(), .ct_out(TDay), .z()
    );
//Date counters -- runs at either 1/sec or 1/24hr
  ct_mod_N #(.N(NDM1)) DTct(
    .clk(Pulse), .rst(Reset), .en(TDten), .earlyrst(ERst), .ct_out(TDate), .z(Dzero)
    );
//Month counter
  ct_mod_N #(.N(NM)) MTHct(
    .clk(Pulse), .rst(Reset), .en(TMonthen), .earlyrst(), .ct_out(TMonth), .z()
    );
// alarm set registers -- either hold or advance 1/sec
  ct_mod_N #(.N(NS)) Mreg(
// input ports
    .clk(Pulse), .rst(Reset), .en(AMen), 
// output ports    
    .ct_out(AMin), .z()
    ); 

  ct_mod_N #(.N(NH)) Hreg(
    .clk(Pulse), .rst(Reset), .en(AHen), .ct_out(AHrs), .z()
    ); 


// display drivers (2 digits each, 6 digits total)
  lcd_int Sdisp(
    .bin_in    (TSec)  ,
	.Segment1  (S1disp),
	.Segment0  (S0disp)
	);
  
always_comb
  if(TMonth==3|TMonth==5|TMonth==8|TMonth==10) begin
    M30=1;
    M28=0;
    MNorm=0;
  end
    else if(TMonth==1) begin
    M28=1;
    M30=0;
    MNorm=0;
    end
  else begin
    MNorm=1;
    M30=0;
    M28=0;
  end
  
 	
  
  logic[6:0] DMin;
   always_comb
     if(Alarmset) DMin = AMin;
  else DMin = TMin;
  
  lcd_int Mdisp(
    .bin_in    (DMin),
    .Segment1  (M1disp),
    .Segment0  (M0disp)
	);

  logic[6:0] DHrs;
  always_comb
    if(Alarmset) DHrs = AHrs;
  else DHrs = THrs;
  
  lcd_int Hdisp(
    .bin_in    (DHrs),
    .Segment1  (H1disp),
    .Segment0  (H0disp)
	);

  //Day Display
  lcd_int Ddisp(
    .bin_in	   (TDay),
    .Segment1  (    ),
    .Segment0  (D0disp)
  );
  
  //Date Display
  //Increment by 1
  logic[6:0] DDate;
  always_comb
    DDate=TDate+1;
  lcd_int Datedisp(
    .bin_in	   (DDate),
    .Segment1  (Date1disp),
    .Segment0  (Date0disp)
  );
  
  //Month Display
  //Increment by 1
  logic[6:0] DMonth;
  always_comb
    DMonth=TMonth+1;
  lcd_int Mothdisp(
    .bin_in	   (DMonth),
    .Segment1  (Month1disp),
    .Segment0  (Month0disp)
  );
  
  
// buzz off :)	  make the connections
  alarm a1(
    .tmin(TMin), .amin(AMin), .thrs(THrs), .ahrs(AHrs), .day(TDay), .alarmon(Alarmon), .buzz(Buzz)
	);
  
  //Adjust Dzero based on month
  /*
  always_comb
    if(TMonth==4 | TMonth==6 | TMonth==9 | TMonth==11 && TDay==29)
      Dzero=1;
  else if(TMonth==2 && TDay==28)
    Dzero=1;
  */
  
  //Mux 
  always_comb
    if(Timeset&&!Alarmset) begin
      if(Minadv)
      TMen = 1;
        else TMen=0;
    if(Hrsadv)
      THen = 1;
      else THen=0;
    if(Dayadv)
      TDen = 1;
      else TDen=0;
    if(Dateadv)
        TDten = 1;
      else TDten=0;
      if(Monthadv)
        TMonthen = 1;
      else TMonthen=0;
      
  end
    else begin
      if(Szero) TMen=1;
      else TMen=0;
      if(Mzero&&Szero) THen=1;
      else THen=0;
      if(Hzero&&Mzero&&Szero)begin
        TDen = 1;
        TDten = 1;
      end
      else begin
        TDen=0;
        TDten=0;
      end
      if((Dzero&&Hzero&&Mzero&&Szero) | (TMonth==3 | TMonth==5 | TMonth==8 | TMonth==10 && TDate==29 &&Hzero&&Mzero&&Szero) | (TMonth==1 && TDate==27&&Hzero&&Mzero&&Szero)) begin
        TMonthen = 1;
		ERst = 1;
      end
      else begin
        TMonthen=0;
        ERst=0;
      end
  end
  always_comb
    if(Alarmset&&!Timeset) begin
      if(Minadv)
      AMen = 1;
      else AMen=0;
    if(Hrsadv)
      AHen = 1;
      else AHen=0;
  end
  else begin
    AMen=0;
    AHen=0;
  end


  
endmodule