//cpu top-level

module cpu( 
			clk, 
			inst_mem_in, 
			inst_mem_out, 
			data_mem_out, 
			data_mem_addr, 
			data_mem_WrData, 
			data_mem_memwrite, 
			data_mem_memread,
			data_mem_sign_mask
		);
	
	//Input Clock
	input clk;
	
	//instruction memory input
	output[31:0] inst_mem_in;
	input[31:0] inst_mem_out;
	
	//Data Memory
	input[31:0] data_mem_out;
	output[31:0] data_mem_addr;
	output[31:0] data_mem_WrData;
	output data_mem_memwrite; 
	output data_mem_memread;
	output[3:0] data_mem_sign_mask;
	
	//Program Counter
	wire[31:0] pc_mux0;
	wire[31:0] pc_in;
	wire[31:0] pc_out;
	wire pcsrc;
	wire[31:0] inst_mux_out;
	wire[31:0] fence_mux_out;
	
	//Pipeline Registers
	wire[63:0] if_id_out;
	wire[177:0] id_ex_out;
	wire[154:0] ex_mem_out;
	wire[116:0] mem_wb_out;
	
	//control signals
	wire MemtoReg1;
	wire RegWrite1;
	wire MemWrite1;
	wire MemRead1;
	wire Branch1;
	wire Jump1;
	wire Jalr1;
	wire ALUSrc1;
	wire Lui1;
	wire Auipc1;
	wire Fence_signal;
	wire CSRR_signal;
	wire CSRRI_signal;
	
	//Decode stage
	wire [31:0] cont_mux_out; //control signal mux
	wire[31:0] regA_out;
	wire[31:0] regB_out;
	wire[31:0] imm_out;
	wire[31:0] RegA_mux_out;
	wire[31:0] RegB_mux_out;
	wire[31:0] RegA_AddrFwdFlush_mux_out;
	wire[31:0] RegB_AddrFwdFlush_mux_out;
	wire[31:0] rdValOut_CSR;
	wire[3:0]  dataMem_sign_mask;
	
	//execute stage
	wire[31:0] ex_cont_mux_out;
	wire[31:0] addr_adder_mux_out;
	wire[31:0] alu_mux_out;
	wire[31:0] addr_adder_sum;
	wire[6:0] alu_ctl;
	wire alu_branch_enable;
	wire[31:0] alu_result;
	wire[31:0] lui_result;
	
	//Memory access stage
	wire[31:0] auipc_mux_out;
	wire[31:0] mem_csrr_mux_out;
	
	//Writeback to registers stage
	wire[31:0] wb_mux_out;
	wire[31:0] reg_dat_mux_out;
	
	//Forwarding multiplexer wires
	wire[31:0] dataMemOut_fwd_mux_out;
	wire[31:0] mem_fwd1_mux_out;
	wire[31:0] mem_fwd2_mux_out;
	wire[31:0] wb_fwd1_mux_out;
	wire[31:0] wb_fwd2_mux_out;
	wire mfwd1;
	wire mfwd2;
	wire wfwd1;
	wire wfwd2;
	
	//Branch Predictor
	wire[31:0] pc_adder_out;
	wire[31:0] branch_predictor_addr;
	wire predict;
	wire[31:0] branch_predictor_mux_out;
	wire actual_branch_decision;
	wire mistake_trigger;
	wire decode_ctrl_mux_sel;
	wire inst_mux_sel;
	
	//Instruction Fetch Stage
	mux2to1 pc_mux( 
			.input0(pc_mux0),
			.input1(ex_mem_out[72:41]),
			.select(pcsrc),
			.out(pc_in)
		);
	
	adder pc_adder( 
			.input1(32'b100),
			.input2(pc_out),
			.out(pc_adder_out)
		);
	
	program_counter PC( 
			.inAddr(pc_in), 
			.outAddr(pc_out), 
			.clk(clk)
		);
	
	mux2to1 inst_mux( 
			.input0(inst_mem_out),
			.input1(32'b0),
			.select(inst_mux_sel),
			.out(inst_mux_out)
		);
	
	mux2to1 fence_mux( 
			.input0(pc_adder_out),
			.input1(pc_out),
			.select(Fence_signal),
			.out(fence_mux_out)
		);
	
	//IF/ID Pipeline Register
	if_id if_id_reg( 
			.clk(clk), 
			.data_in({inst_mux_out, pc_out}), 
			.data_out(if_id_out)
		);
	
	//Decode Stage
	control control_unit( 
			.opcode({if_id_out[38:32]}), 
			.MemtoReg(MemtoReg1), 
			.RegWrite(RegWrite1), 
			.MemWrite(MemWrite1), 
			.MemRead(MemRead1),
			.Branch(Branch1),
			.ALUSrc(ALUSrc1),
			.Jump(Jump1),
			.Jalr(Jalr1),
			.Lui(Lui1),
			.Auipc(Auipc1),
			.Fence(Fence_signal),
			.CSRR(CSRR_signal)
		);
	
	mux2to1 cont_mux( 
			.input0({21'b0, Jalr1, ALUSrc1, Lui1, Auipc1, Branch1, MemRead1, MemWrite1, CSRR_signal, RegWrite1, MemtoReg1, Jump1}),
			.input1(32'b0),
			.select(decode_ctrl_mux_sel),
			.out(cont_mux_out)
		);
	
	regfile register_files( 
			.clk(clk), 
			.write(mem_wb_out[2]), 
			.wrAddr(mem_wb_out[104:100]),
			.wrData(reg_dat_mux_out), 
			.rdAddrA(inst_mux_out[19:15]), //if_id_out[51:47] //inst_mux_out[19:15]
			.rdDataA(regA_out), 
			.rdAddrB(inst_mux_out[24:20]), //if_id_out[56:52] //inst_mux_out[24:20]
			.rdDataB(regB_out),
		);
	
	imm_gen immediate_generator( 
			.inst(if_id_out[63:32]),
			.imm(imm_out)
		);
	
	ALUControl alu_control( 
			.Opcode(if_id_out[38:32]),
			.FuncCode({if_id_out[62], if_id_out[46:44]}),
			.ALUCtl(alu_ctl)
		);
	
	sign_mask_gen sign_mask_gen_inst(
			.func3(if_id_out[46:44]),
			.sign_mask(dataMem_sign_mask)
		);
	
	csr_file ControlAndStatus_registers(
			.clk(clk), 
			.write(mem_wb_out[3]), //TODO
			.wrAddr_CSR(mem_wb_out[116:105]), 
			.wrVal_CSR(mem_wb_out[35:4]), 
			.rdAddr_CSR(inst_mux_out[31:20]), 
			.rdVal_CSR(rdValOut_CSR)
		);
	
	mux2to1 RegA_mux( 
			.input0(regA_out),
			.input1({27'b0, if_id_out[51:47]}),
			.select(CSRRI_signal),
			.out(RegA_mux_out)
		);
	
	mux2to1 RegB_mux( 
			.input0(regB_out),
			.input1(rdValOut_CSR),
			.select(CSRR_signal),
			.out(RegB_mux_out)
		);
	
	mux2to1 RegA_AddrFwdFlush_mux( 
			.input0({27'b0, if_id_out[51:47]}),
			.input1(32'b0),
			.select(CSRRI_signal),
			.out(RegA_AddrFwdFlush_mux_out)
		);
	
	mux2to1 RegB_AddrFwdFlush_mux( 
			.input0({27'b0, if_id_out[56:52]}),
			.input1(32'b0),
			.select(CSRR_signal),
			.out(RegB_AddrFwdFlush_mux_out)
		);
	
	assign CSRRI_signal = CSRR_signal & (if_id_out[46]);
	
	//ID/EX Pipeline Register
	id_ex id_ex_reg( 
			.clk(clk), 
			.data_in({if_id_out[63:52], RegB_AddrFwdFlush_mux_out[4:0], RegA_AddrFwdFlush_mux_out[4:0], if_id_out[43:39], dataMem_sign_mask, alu_ctl, imm_out, RegB_mux_out, RegA_mux_out, if_id_out[31:0], cont_mux_out[10:7], predict, cont_mux_out[6:0]}), 
			.data_out(id_ex_out)
		);
	
	//Execute stage
	mux2to1 ex_cont_mux( 
			.input0({23'b0, id_ex_out[8:0]}),
			.input1(32'b0),
			.select(pcsrc),
			.out(ex_cont_mux_out)
		);
		
	mux2to1 addr_adder_mux( 
			.input0(id_ex_out[43:12]),
			.input1(wb_fwd1_mux_out),
			.select(id_ex_out[11]),
			.out(addr_adder_mux_out)
		);
	
	adder addr_adder( 
			.input1(addr_adder_mux_out),
			.input2(id_ex_out[139:108]),
			.out(addr_adder_sum)
		);
	
	mux2to1 alu_mux( 
			.input0(wb_fwd2_mux_out),
			.input1(id_ex_out[139:108]),
			.select(id_ex_out[10]),
			.out(alu_mux_out)
		);
	
	alu alu_main( 
			.ALUctl(id_ex_out[146:140]), 
			.A(wb_fwd1_mux_out), 
			.B(alu_mux_out), 
			.ALUOut(alu_result),
			.Branch_Enable(alu_branch_enable)
		);
		
	mux2to1 lui_mux( 
			.input0(alu_result),
			.input1(id_ex_out[139:108]),
			.select(id_ex_out[9]),
			.out(lui_result)
		);
	
	//EX/MEM Pipeline Register
	ex_mem ex_mem_reg( 
			.clk(clk), 
			.data_in({id_ex_out[177:166], id_ex_out[155:151], wb_fwd2_mux_out, lui_result, alu_branch_enable, addr_adder_sum, id_ex_out[43:12], ex_cont_mux_out[8:0]}), 
			.data_out(ex_mem_out)
		);
	
	//Memory Access Stage
	branch_decision branch_decide(
			.Branch(ex_mem_out[6]), 
			.Predicted(ex_mem_out[7]), 
			.Branch_Enable(ex_mem_out[73]), 
			.Jump(ex_mem_out[0]), 
			.Mistake(mistake_trigger),
			.Decision(actual_branch_decision),
			.Branch_Jump_Trigger(pcsrc)
		);
	
	mux2to1 auipc_mux( 
			.input0(ex_mem_out[105:74]),
			.input1(ex_mem_out[72:41]),
			.select(ex_mem_out[8]),
			.out(auipc_mux_out)
		);
	
	mux2to1 mem_csrr_mux( 
			.input0(auipc_mux_out),
			.input1(ex_mem_out[137:106]),
			.select(ex_mem_out[3]),
			.out(mem_csrr_mux_out)
		);
	
	//MEM/WB Pipeline Register
	mem_wb mem_wb_reg( 
			.clk(clk), 
			.data_in({ex_mem_out[154:143], ex_mem_out[142:138], data_mem_out, mem_csrr_mux_out, ex_mem_out[105:74], ex_mem_out[3:0]}), 
			.data_out(mem_wb_out)
		);
	
	//Writeback to Register Stage
	mux2to1 wb_mux( 
			.input0(mem_wb_out[67:36]),
			.input1(mem_wb_out[99:68]),
			.select(mem_wb_out[1]),
			.out(wb_mux_out)
		);
	
	mux2to1 reg_dat_mux( 
			.input0(wb_mux_out),
			.input1(ex_mem_out[40:9]),
			.select(mem_wb_out[0]),
			.out(reg_dat_mux_out)
		);
	
	//Forwarding Unit
	ForwardingUnit forwarding_unit(
			.rs1(id_ex_out[160:156]),
			.rs2(id_ex_out[165:161]),
			.MEM_RegWriteAddr(ex_mem_out[142:138]),
			.WB_RegWriteAddr(mem_wb_out[104:100]),
			.MEM_RegWrite(ex_mem_out[2]),
			.WB_RegWrite(mem_wb_out[2]),
			.EX_CSRR_Addr(id_ex_out[177:166]), 
			.MEM_CSRR_Addr(ex_mem_out[154:143]), 
			.WB_CSRR_Addr(mem_wb_out[116:105]), 
			.MEM_CSRR(ex_mem_out[3]), 
			.WB_CSRR(mem_wb_out[3]),
			.MEM_fwd1(mfwd1),
			.MEM_fwd2(mfwd2),
			.WB_fwd1(wfwd1),
			.WB_fwd2(wfwd2)
		);
	
	mux2to1 mem_fwd1_mux( 
			.input0(id_ex_out[75:44]),
			.input1(dataMemOut_fwd_mux_out),
			.select(mfwd1),
			.out(mem_fwd1_mux_out)
		);
	
	mux2to1 mem_fwd2_mux( 
			.input0(id_ex_out[107:76]),
			.input1(dataMemOut_fwd_mux_out),
			.select(mfwd2),
			.out(mem_fwd2_mux_out)
		);
	
	mux2to1 wb_fwd1_mux( 
			.input0(mem_fwd1_mux_out),
			.input1(wb_mux_out),
			.select(wfwd1),
			.out(wb_fwd1_mux_out)
		);
	
	mux2to1 wb_fwd2_mux( 
			.input0(mem_fwd2_mux_out),
			.input1(wb_mux_out),
			.select(wfwd2),
			.out(wb_fwd2_mux_out)
		);
	
	mux2to1 dataMemOut_fwd_mux( 
			.input0(ex_mem_out[105:74]),
			.input1(data_mem_out),
			.select(ex_mem_out[1]),
			.out(dataMemOut_fwd_mux_out)
		);
	
	//Branch Predictor
	branch_predictor branch_predictor_FSM(
			.clk(clk),
			.actual_branch_decision(actual_branch_decision),
			.branch_decode_sig(cont_mux_out[6]), 
			.branch_mem_sig(ex_mem_out[6]), 
			.in_addr(if_id_out[31:0]), 
			.offset(imm_out), 	
			.branch_addr(branch_predictor_addr),
			.prediction(predict)
		);
	
	mux2to1 branch_predictor_mux(
			.input0(fence_mux_out),
			.input1(branch_predictor_addr),
			.select(predict),
			.out(branch_predictor_mux_out)
		);
	
	mux2to1 mistaken_branch_mux(
			.input0(branch_predictor_mux_out),
			.input1(id_ex_out[43:12]),
			.select(mistake_trigger),
			.out(pc_mux0)
		);
	
	//OR gate assignments, used for flushing
	assign decode_ctrl_mux_sel = pcsrc | mistake_trigger;
	assign inst_mux_sel = pcsrc | predict | mistake_trigger | Fence_signal;
	
	//Instruction Memory Connections
	assign inst_mem_in = pc_out;
	
	//Data Memory Connections
	assign data_mem_addr = lui_result;
	assign data_mem_WrData = wb_fwd2_mux_out;
	assign data_mem_memwrite = ex_cont_mux_out[4];
	assign data_mem_memread = ex_cont_mux_out[5];
	assign data_mem_sign_mask = id_ex_out[150:147];
	
endmodule
	
