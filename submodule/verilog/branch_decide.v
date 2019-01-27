//branch decider, located in MEM stage

module branch_decision(Branch, Predicted, Branch_Enable, Jump, Mistake, Decision, Branch_Jump_Trigger);
	input Branch, Predicted, Branch_Enable, Jump;
	output Mistake, Decision, Branch_Jump_Trigger;
	
	assign Branch_Jump_Trigger = ((!Predicted) & (Branch & Branch_Enable)) | Jump;
	assign Decision = (Branch & Branch_Enable);
	assign Mistake = (Predicted & (!(Branch & Branch_Enable)));
endmodule
