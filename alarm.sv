// CSE140 lab 2  
// How does this work? How long does the alarm stay on? 
// (buzz is the alarm itself)
module alarm(
  input[6:0]   tmin,
               amin,
			   thrs,
			   ahrs,
  			   day,
  			   alarmon,
  output logic buzz
);

  always_comb
    buzz = alarmon && tmin==amin && thrs==ahrs && day!=5 && day!=6;

endmodule