"""Test data fidelity and assemble/execute a real translated object."""

from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from gas_to_nasm import convert


class TranslationTests(unittest.TestCase):
    def test_string_escapes_hashes_and_label_like_text_are_preserved(self):
        translated = convert('.string "line\\n.Llabel # \\101"')
        data = bytes(int(value) for value in translated.split("db ", 1)[1].strip().split(", "))
        self.assertEqual(data, b"line\n.Llabel # A\0")

    def test_strings_have_one_explicit_terminator(self):
        self.assertTrue(convert('.string ""').endswith("db 0\n"))

    def test_float_constants_keep_their_ieee_bits(self):
        self.assertIn("dd 0x3f000000", convert(".float 0.5"))
        self.assertIn("dd 0xbf000000", convert(".float -0.5"))

    def test_unknown_directives_fail_closed(self):
        with self.assertRaises(ValueError):
            convert(".unrecognized 42")

    def test_uninitialized_storage_uses_reservation_instead_of_file_bytes(self):
        result = convert(".bss\n.align 32\n.zero 64")
        self.assertIn("alignb 32", result)
        self.assertIn("resb 64", result)

    def test_file_scope_labels_do_not_become_nasm_parent_scoped_labels(self):
        result = convert("first:\njmp .Ltarget\nsecond:\n.Ltarget:\nret")
        self.assertIn("jmp __gas_Ltarget", result)
        self.assertIn("__gas_Ltarget:", result)

    def test_external_calls_use_plt_relocations(self):
        result = convert("call cosf@PLT")
        self.assertIn("extern cosf", result)
        self.assertIn("call cosf wrt ..plt", result)

    def test_stack_marker_is_non_executable(self):
        self.assertIn("noalloc noexec nowrite", convert('.section .note.GNU-stack,"",@progbits'))

    def test_scalar_x87_and_implicit_shift_operands_translate(self):
        result = convert("fstp st(1)\nsar eax\nmovabs rax, 4294967296")
        self.assertIn("fstp st1", result)
        self.assertIn("sar eax, 1", result)
        self.assertIn("mov rax, 4294967296", result)

    def test_translated_rip_relative_data_and_aliases_execute_correctly(self):
        nasm = os.environ.get("NASM") or shutil.which("nasm")
        if not nasm or not shutil.which("gcc"):
            self.skipTest("NASM and GCC are needed for the executable translator check")
        assembly = """.text
.globl probe
probe:
mov eax, DWORD PTR .LCvalue[rip]
ret
.section .rodata
.LCbase:
.long 7
.long 42
.set .LCvalue,.LCbase+4
.section .note.GNU-stack,"",@progbits
"""
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "probe.asm").write_text(convert(assembly))
            (directory / "driver.c").write_text(
                "extern int probe(void); int main(void) {return probe()!=42;}"
            )
            subprocess.run(
                [
                    nasm,
                    "-f",
                    "elf64",
                    "-Werror",
                    str(directory / "probe.asm"),
                    "-o",
                    str(directory / "probe.o"),
                ],
                check=True,
            )
            subprocess.run(
                [
                    "gcc",
                    str(directory / "driver.c"),
                    str(directory / "probe.o"),
                    "-o",
                    str(directory / "probe"),
                ],
                check=True,
            )
            subprocess.run([str(directory / "probe")], check=True)


if __name__ == "__main__":
    unittest.main()
