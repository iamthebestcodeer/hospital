#!/usr/bin/env python3
"""Convert the GCC Intel-syntax subset used by this game into NASM ELF64.

The checked-in .asm files are the build inputs. This translator is only needed
when regenerating render.asm from the C reference. Unknown directives fail closed.
"""

import ast
from pathlib import Path
import re
import struct
import sys


def symbols(text):
    # GAS .L labels have file scope; NASM .labels have parent-label scope.
    return re.sub(r"(?<![\w.])\.L([\w.]+)", r"__gas_L\1", text)


def convert(source):
    externs = set(re.findall(r"\b([\w.]+)@PLT", source))
    if not re.search(r"^game:", source, re.M) and re.search(r"\bgame\[", source):
        externs.add("game")
    result = ["; NASM x86-64, System V ABI. See tools/generate.py.", "bits 64", "default rel"]
    result += [f"extern {name}" for name in sorted(externs)]
    bss = False
    for number, original in enumerate(source.splitlines(), 1):
        # GAS comments never occur inside string literals in these inputs.
        line = original.strip()
        if not line or line.startswith("#"):
            result.append(line.replace("#", ";", 1))
            continue
        if not line.startswith(".string"):
            line = line.split("#", 1)[0].rstrip()
        # String contents are data, including any text resembling a .L label.
        if not line.startswith(".string"):
            line = symbols(line)
        label = re.match(r"^([\w.]+):\s*(.*)$", line)
        if label:
            result.append(label[1] + ":")
            line = label[2]
            if not line:
                continue
        op, _, arg = line.replace("\t", " ").partition(" ")
        arg = arg.strip()
        if op in {".file", ".intel_syntax", ".type", ".size", ".ident"}:
            continue
        if op in {".text", ".bss", ".data", ".section"}:
            section = arg.split(",")[0] if op == ".section" else op
            bss = section == ".bss"
            if section.startswith(".rodata"):
                section = ".rodata"
            elif section.startswith(".text"):
                section = ".text"
            if section == ".note.GNU-stack":
                flags = " noalloc noexec nowrite progbits"
            elif section == ".data.rel.ro.local":
                flags = " alloc noexec write progbits align=8"
            else:
                flags = ""
            result.append("section " + section + flags)
        elif op == ".include":
            result.append("%include " + arg)
        elif op == ".globl":
            result.append("global " + arg)
        elif op in {".align", ".p2align"}:
            value = int(arg.split(",")[0])
            if op == ".p2align":
                value = 1 << value
            result.append(f'{"alignb" if bss else "align"} {value}')
        elif op in {".set", ".equ"}:
            name, value = arg.split(",", 1)
            result.append(name.strip() + " equ " + value.strip())
        elif op == ".string":
            data = ast.literal_eval("b" + arg) + b"\0"
            result.append("db " + ", ".join(str(byte) for byte in data))
        elif op in {".long", ".quad", ".byte", ".word"}:
            result.append(
                {".long": "dd ", ".quad": "dq ", ".byte": "db ", ".word": "dw "}[op] + arg
            )
        elif op == ".float":
            bits = struct.unpack("<I", struct.pack("<f", float(arg)))[0]
            result.append(f"dd 0x{bits:08x}")
        elif op == ".zero":
            result.append(("resb " if bss else "times " + arg + " db ") + (arg if bss else "0"))
        elif op.startswith("."):
            raise ValueError(f"Unsupported directive on line {number}: {original}")
        else:
            # GAS writes displacement[base]; NASM requires [base+displacement].
            arg = re.sub(r"([\w.+-]+)\[([^\]]+)\]", r"[\2+\1]", arg)
            arg = re.sub(r"\brip\b\+?", "rel ", arg)
            arg = re.sub(
                r"\b(XMMWORD|QWORD|DWORD|WORD|BYTE) PTR\b",
                lambda m: {"XMMWORD": "oword"}.get(m[1], m[1].lower()),
                arg,
            )
            arg = arg.replace("@PLT", " wrt ..plt")
            arg = re.sub(r"\bst\((\d)\)", r"st\1", arg)
            if op == "movabs":
                op = "mov"
            if op in {"sal", "sar", "shl", "shr", "rol", "ror", "rcl", "rcr"} and "," not in arg:
                arg += ", 1"
            if op == "movsx" and re.match(r"r\w+,\s*e\w+$", arg):
                op = "movsxd"
            result.append("    " + op + (" " + arg if arg else ""))
    return "\n".join(result) + "\n"


if __name__ == "__main__":
    source, destination = map(Path, sys.argv[1:])
    destination.write_text(convert(source.read_text()))
