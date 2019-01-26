const instructionSet = require('./instructionSet');


const getRegister = string => {
    if (string[0] === 'x') {
        const num = Number(string.substr(1));
        if (Number.isNaN(num) && num < 0 && num >= 32) {
            return null;
        } else {
            return num;
        }
    } else if (string == 'zero') {
        return 0;
    } else if (string == 'ra') {
        return 1;
    } else if (string == 'sp') {
        return 2;
    } else if (string == 'gp') {
        return 3;
    } else if (string == 'tp') {
        return 4;
    } else if (string[0] == 'a') {
        const num = Number(string.substr(1));
        if (Number.isNaN(num) && num < 0 && num >= 8) {
            return null;
        } else {
            return num + 10;
        }
    } else if (string[0] == 's') {
        const num = Number(string.substr(1));
        if (Number.isNaN(num) && num < 0 && num >= 12) {
            return null;
        } else {
            return num + (num < 2 ? 8 : 16);
        }
    } else if (string[0] == 't') {
        const num = Number(string.substr(1));
        if (Number.isNaN(num) && num < 0 && num >= 7) {
            return null;
        } else {
            return num + (num < 3 ? 5 : 25);
        }
    }
    return null;
}

const getImmediate = string => {
    let base = 10;
    let numeric = string;

    if (string[0] === '-') {
        return -getImmediate(string.substr(1));
    }

    if (string[0] === '0') {
        if (string[1] === 'b') {
            base = 2;
            numeric = string.substr(2);
        } else if (string[1] === 'x') {
            base = 16;
            numeric = string.substr(2);
        } else {
            // fail on leading zero
            return string === '0' ? 0 : null;
        }
    }

    let immediate = parseInt(numeric, base);
    if (Number.isNaN(immediate) || immediate.toString(base) !== numeric) {
        return null;
    } else {
        return immediate;
    }
}


class AssembleError extends Error {

    constructor(which, {instruction, expected, actual, startIndex, endIndex}) {
        super(which);

        super.assembleError = true;
        super.instruction = instruction;
        super.expected = expected;
        super.actual = actual;
    }
};

const parseParts = ({string, parts, schema}) => {
    if (parts.length !== schema.length) {
        throw new AssembleError(
            `Too ${parts.length < schema.length ? 'few' : 'many'} arguments to instruction.`,
            {
                instruction: string,
                expected: schema.length,
                actual: parts.length
            },
        )
    }

    return parts.map((part, i) => {
        const error = expected => new AssembleError(`Invalid instruction argument ${i + 1}.`, {
            instruction: string,
            actual: part,
            expected,
        });

        switch (schema[i]) {
            case 'REGISTER': {
                const reg = getRegister(part);
                if (reg === null) {
                    throw error('register');
                }
                return reg;
            };
            case 'MEMORY LOCATION': {
                const openBracketIndex = part.indexOf('(');
                const closeBracketIndex = part.indexOf(')');
                if (openBracketIndex === -1) {
                    throw error('opening bracket');
                }
                if (closeBracketIndex !== part.length - 1) {
                    throw error('closing bracket as last character');
                }

                const imm = getImmediate(part.substring(0, openBracketIndex));

                if (imm === null) {
                    if (part[0] === '0') {
                        throw error(`immediate in decimal, binary or hex form`);
                    }
                    throw error(`immediate`);
                }
                if (imm < (-1 << 11) || imm >= (1 << 11)) {
                    throw error(`immediate in range -2048..2047`);
                }

                const reg = getRegister(part.substring(openBracketIndex + 1, closeBracketIndex));

                if (reg === null) {
                    throw error('register in brackets');
                }

                return [reg, imm];
            };
            case 'I IMMEDIATE': {
                const imm = getImmediate(part);
                if (imm === null) {
                    if (part[0] === '0') {
                        throw error(`immediate in decimal, binary or hex form`);
                    }
                    throw error(`immediate`);
                }
                if (imm < (-1 << 11) || imm >= (1 << 11)) {
                    throw error(`immediate in range -2048..2047`);
                }
                return imm;
            };
            case 'B IMMEDIATE': {
                const imm = getImmediate(part);
                if (imm === null) {
                    if (part[0] === '0') {
                        throw error(`immediate in decimal, binary or hex form`);
                    }
                    throw error(`immediate`);
                }
                if (imm < (-1 << 12) || imm >= (1 << 12)) {
                    throw error(`immediate in range -4096..4094`);
                }
                if (imm & 1 === 1) {
                    throw error(`even immediate`);
                }
                return imm;
            };
            case 'U IMMEDIATE': {
                const imm = getImmediate(part);
                if (imm === null) {
                    if (part[0] === '0') {
                        throw error(`immediate in decimal, binary or hex form`);
                    }
                    throw error(`immediate`);
                }
                if (imm < 0 || imm >= (1 << 20)) {
                    throw error(`immediate in range 0..1048575`);
                }
                return imm;
            };
            case 'J IMMEDIATE': {
                const imm = getImmediate(part);
                if (imm === null) {
                    if (part[0] === '0') {
                        throw error(`immediate in decimal, binary or hex form`);
                    }
                    throw error(`immediate`);
                }
                if (imm < (-1 << 20) || imm >= (1 << 20)) {
                    throw error(`immediate in range -1048576..1048574`);
                }
                if (imm & 1 === 1) {
                    throw error(`even immediate`);
                }
                return imm;
            };
            case 'SHAMT': {
                const imm = getImmediate(part);
                if (imm === null) {
                    if (part[0] === '0') {
                        throw error(`immediate in decimal, binary or hex form`);
                    }
                    throw error(`immediate`);
                }
                if (imm < 0 || imm >= (1 << 5)) {
                    throw error(`immediate in range 0..31`);
                }
                if (imm & 1 === 1) {
                    throw error(`even immediate`);
                }
                return imm;
            };
            default: {
                throw new Error(`Missing case statement for: ${schema[i]}`);
            }
        }
    });
}

exports.assemble = (input) => {
    const string = input.trim();

    const firstSpaceIndex =
        string.indexOf(' ') !== -1
            ? string.indexOf(' ')
            : string.length;

    const mnemonic = string.substr(0, firstSpaceIndex);

    const instruction = instructionSet[mnemonic.toUpperCase()];

    if (instruction === undefined) {
        throw new AssembleError(
            'Could not parse the assembly mnenomic.',
            {
                instruction: string,
                expected: 'an assembly mnemonic',
                actual: `'${mnemonic}'`,
            },
        )
    }

    const parts = parseParts({
        string,
        parts: string
            .substr(firstSpaceIndex + 1)
            .split(',')
            .map(s => s.trim())
            .filter(s => s !== ''),
        partStartIndex: firstSpaceIndex + 1,
        schema: instruction.args
    });

    return {
        binary: instruction.assemble(...parts),
        disassembly: instruction.disassemble(...parts),
    };
}
