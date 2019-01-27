
const assembleFormat = {
    R(opcode, funct3, funct7) {
        return (rd, rs1, rs2) =>
            ((funct7 & 0x3F) << 25) |
            ((rs2 & 0x1F) << 20) |
            ((rs1 & 0x1F) << 15) |
            ((funct3 & 0b111) << 12) |
            ((rd & 0x1F) << 7) |
            (opcode & 0x7F);
    },
    I(opcode, funct3) {
        return (rd, rs1, imm) =>
            ((imm & 0xFFF) << 20) | // imm[11:0], inst[31:20]
            ((rs1 & 0x1F) << 15) |
            ((funct3 & 0b111) << 12) |
            ((rd & 0x1F) << 7) |
            (opcode & 0x7F);
    },
    S(opcode, funct3) {
        return (rs2, [rs1, imm]) =>
            ((imm & 0b111111100000) << 20) | // imm[11:5], inst[31:25]
            ((rs2 & 0x1F) << 20) |
            ((rs1 & 0x1F) << 15) |
            ((funct3 & 0b111) << 12) |
            ((imm & 0b000000011111) << 7) | // imm[11:5], inst[31:25]
            (opcode & 0x7F);
    },
    B(opcode, funct3) {
        return (rs1, rs2, imm) =>
            ((imm & 0b1000000000000) << 19) | // imm[12], inst[31]
            ((imm & 0b0011111100000) << 20) | // imm[10:5], inst[30:25]
            ((imm & 0b0000000011110) << 7) |  // imm[4:1], inst[11:8]
            ((imm & 0b0100000000000) >> 4) |  // imm[11], inst[7]
            ((rs2 & 0x1F) << 20) |
            ((rs1 & 0x1F) << 15) |
            ((funct3 & 0b111) << 12) |
            (opcode & 0x7F);
    },
    U(opcode) {
        return (rd, imm) => ((imm & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F);
    },
    J(opcode) {
        return (rd, imm) =>
            ((imm & 0x100000) << 11) | // imm[20], inst[31]
            ((imm & 0x0003FE) << 20) | // imm[10:1], inst[30:21]
            ((imm & 0x000800) << 9) |  // imm[11], inst[20]
            ((imm & 0x0FF000)) | // imm[19:12], inst[19:12]
            ((rd & 0x1F) << 7) |
            (opcode & 0x7F);
    }
};

const disassembleFormat = {
    R(mnemonic) {
        return (rd, rs1, rs2) => `${mnemonic} x${rd},x${rs1},x${rs2}`
    },
    I(mnemonic) {
        return (rd, rs1, imm) => `${mnemonic} x${rd},x${rs1},${imm}`
    },
    S(mnemonic) {
        return (rd, rs1, imm) => `${mnemonic} x${rd},${imm}(x${rs1})`
    },
    B(mnemonic) {
        return (rs1, rs2, imm) => `${mnemonic} x${rs1},${rs2},${imm}`
    },
    U(mnemonic) {
        return (rd, imm) => `${mnemonic} x${rd},0x${imm.toString(16)}`
    },
    J(mnemonic) {
        return (rd, imm) => `${mnemonic} x${rd},${imm}`
    },
    SHIFT(mnemonic) {
        return (rd, rs1, shamt) => `${mnemonic} x${rd},x${rs1},${shamt}`
    }
}

const baseInstructions = Object.freeze({
    LUI: {
        args: ['REGISTER', 'U IMMEDIATE'],
        assemble: assembleFormat.U(0b0110111),
        disassemble: disassembleFormat.U('lui'),
        format: 'U',
    },
    AUIPC: {
        args: ['REGISTER', 'U IMMEDIATE'],
        assemble: assembleFormat.U(0b0010111),
        disassemble: disassembleFormat.U('auipc'),
        format: 'U',
    },
    JAL: {
        args: ['REGISTER', 'J IMMEDIATE'],
        assemble: assembleFormat.J(0b1101111),
        disassemble: disassembleFormat.J('jal'),
        format: 'J',
    },
    JALR: {
        args: ['REGISTER', 'REGISTER', 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b1100111, 0b000),
        disassemble: disassembleFormat.I('jalr'),
        format: 'I',
    },
    BEQ: {
        args: ['REGISTER', `REGISTER`, 'B IMMEDIATE'],
        assemble: assembleFormat.B(0b1100011, 0b000),
        disassemble: disassembleFormat.B('beq'),
        format: 'B',
    },
    BNE: {
        args: ['REGISTER', `REGISTER`, 'B IMMEDIATE'],
        assemble: assembleFormat.B(0b1100011, 0b001),
        disassemble: disassembleFormat.B('bne'),
        format: 'B',
    },
    BLT: {
        args: ['REGISTER', `REGISTER`, 'B IMMEDIATE'],
        assemble: assembleFormat.B(0b1100011, 0b100),
        disassemble: disassembleFormat.B('blt'),
        format: 'B',
    },
    BGE: {
        args: ['REGISTER', `REGISTER`, 'B IMMEDIATE'],
        assemble: assembleFormat.B(0b1100011, 0b101),
        disassemble: disassembleFormat.B('bge'),
        format: 'B',
    },
    BLTU: {
        args: ['REGISTER', `REGISTER`, 'B IMMEDIATE'],
        assemble: assembleFormat.B(0b1100011, 0b110),
        disassemble: disassembleFormat.B('bltu'),
        format: 'B',
    },
    BGEU: {
        args: ['REGISTER', `REGISTER`, 'B IMMEDIATE'],
        assemble: assembleFormat.B(0b1100011, 0b111),
        disassemble: disassembleFormat.B('bgeu'),
        format: 'B',
    },
    LB: {
        args: ['REGISTER', `REGISTER`, 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0000011, 0b000),
        disassemble: disassembleFormat.I('lb'),
        format: 'I',
    },
    LH: {
        args: ['REGISTER', `REGISTER`, 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0000011, 0b001),
        disassemble: disassembleFormat.I('lh'),
        format: 'I',
    },
    LW: {
        args: ['REGISTER', `REGISTER`, 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0000011, 0b010),
        disassemble: disassembleFormat.I('lw'),
        format: 'I',
    },
    LBU: {
        args: ['REGISTER', `REGISTER`, 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0000011, 0b100),
        disassemble: disassembleFormat.I('lbu'),
        format: 'I',
    },
    LHU: {
        args: ['REGISTER', `REGISTER`, 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0000011, 0b101),
        disassemble: disassembleFormat.I('lhu'),
        format: 'I',
    },
    SB: {
        args: ['REGISTER', 'MEMORY LOCATION'],
        assemble: assembleFormat.S(0b0100011, 0b000),
        disassemble: disassembleFormat.S('sb'),
        format: 'S',
    },
    SH: {
        args: ['REGISTER', 'MEMORY LOCATION'],
        assemble: assembleFormat.S(0b0100011, 0b001),
        disassemble: disassembleFormat.S('sh'),
        format: 'S',
    },
    SW: {
        args: ['REGISTER', 'MEMORY LOCATION'],
        assemble: assembleFormat.S(0b0100011, 0b010),
        disassemble: disassembleFormat.S('sw'),
        format: 'S',
    },
    ADDI: {
        args: ['REGISTER', 'REGISTER', 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0010011, 0b000),
        disassemble: disassembleFormat.I('addi'),
        format: 'I',
    },
    SLTI: {
        args: ['REGISTER', 'REGISTER', 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0010011, 0b010),
        disassemble: disassembleFormat.I('slti'),
        format: 'I',
    },
    SLTIU: {
        args: ['REGISTER', 'REGISTER', 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0010011, 0b011),
        disassemble: disassembleFormat.I('sltiu'),
        format: 'I',
    },
    XORI: {
        args: ['REGISTER', 'REGISTER', 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0010011, 0b100),
        disassemble: disassembleFormat.I('xori'),
        format: 'I',
    },
    ORI: {
        args: ['REGISTER', 'REGISTER', 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0010011, 0b110),
        disassemble: disassembleFormat.I('ori'),
        format: 'I',
    },
    ANDI: {
        args: ['REGISTER', 'REGISTER', 'I IMMEDIATE'],
        assemble: assembleFormat.I(0b0010011, 0b111),
        disassemble: disassembleFormat.I('andi'),
        format: 'I',
    },
    SLLI: {
        args: ['REGISTER', 'REGISTER', 'SHAMT'],
        assemble: assembleFormat.R(0b0010011, 0b001, 0b0000000),
        disassemble: disassembleFormat.SHIFT('slli'),
        format: 'I-SHIFT',

    },
    SRLI: {
        args: ['REGISTER', 'REGISTER', 'SHAMT'],
        assemble: assembleFormat.R(0b0010011, 0b101, 0b0000000),
        disassemble: disassembleFormat.SHIFT('srli'),
        format: 'I-SHIFT',
    },
    SRAI: {
        args: ['REGISTER', 'REGISTER', 'SHAMT'],
        assemble: assembleFormat.R(0b0010011, 0b101, 0b0100000),
        disassemble: disassembleFormat.SHIFT('srai'),
        format: 'I-SHIFT',
    },
    ADD: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b000, 0b0000000),
        disassemble: disassembleFormat.R('add'),
        format: 'R',
    },
    SUB: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b000, 0b0100000),
        disassemble: disassembleFormat.R('sub'),
        format: 'R',
    },
    SLL: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b001, 0b0000000),
        disassemble: disassembleFormat.R('sll'),
        format: 'R',
    },
    SLT: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b010, 0b0000000),
        disassemble: disassembleFormat.R('slt'),
        format: 'R',
    },
    SLTU: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b011, 0b0000000),
        disassemble: disassembleFormat.R('sltu'),
        format: 'R',
    },
    XOR: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b100, 0b0000000),
        disassemble: disassembleFormat.R('xor'),
        format: 'R',
    },
    SRL: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b101, 0b0000000),
        disassemble: disassembleFormat.R('srl'),
        format: 'R',
    },
    SRA: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b101, 0b0100000),
        disassemble: disassembleFormat.R('sra'),
        format: 'R',
    },
    OR: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b110, 0b0000000),
        disassemble: disassembleFormat.R('or'),
        format: 'R',
    },
    AND: {
        args: ['REGISTER', 'REGISTER', 'REGISTER'],
        assemble: assembleFormat.R(0b0110011, 0b111, 0b0000000),
        disassemble: disassembleFormat.R('and'),
        format: 'R',
    },
});

const psuedoOp = ({assemble, disassemble, format}, args, mappingFunc) => ({
    assemble: (...args) => assemble(...mappingFunc(...args)),
    disassemble: (...args) => disassemble(...mappingFunc(...args)),
    args,
    format
});

const reg0 = 0;

// See: RISC-V spec v2.2, ch20
const psuedoInstructions = Object.freeze({
    NOP: psuedoOp(baseInstructions.ADDI, [], () => [0, 0, 0]),
    LI: psuedoOp(baseInstructions.ADDI, ['REGISTER', 'I IMMEDIATE'], (rd, imm) => [rd, reg0, imm]),
    MV: psuedoOp(baseInstructions.ADDI, ['REGISTER', 'REGISTER'], (rd, rs) => [rd, rs, 0]),
    NOT: psuedoOp(baseInstructions.XORI, ['REGISTER', 'REGISTER'], (rd, rs) => [rd, rs, -1]),
    NEG: psuedoOp(baseInstructions.SUB, ['REGISTER', 'REGISTER'], (rd, rs) => [rd, reg0, rs]),
    SEQZ: psuedoOp(baseInstructions.SLTIU, ['REGISTER', 'REGISTER'], (rd, rs) => [rd, rs, 1]),
    SNEZ: psuedoOp(baseInstructions.SLTU, ['REGISTER', 'REGISTER'], (rd, rs) => [rd, reg0, rs]),
    SLTZ: psuedoOp(baseInstructions.SLT, ['REGISTER', 'REGISTER'], (rd, rs) => [rd, rs, reg0]),
    SGTZ: psuedoOp(baseInstructions.SLT, ['REGISTER', 'REGISTER'], (rd, rs) => [rd, reg0, rs]),
});

module.exports = Object.freeze(Object.assign({}, baseInstructions, psuedoInstructions));
