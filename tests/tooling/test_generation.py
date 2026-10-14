"""Protect the boundary between handwritten gameplay and generated rendering."""

from pathlib import Path
import importlib
import re
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import generate


class FunctionExtractionTests(unittest.TestCase):
    def test_only_the_requested_definition_is_removed(self):
        source = "int keep(void) {return 7;}\nint replace(void) {return 9;}\n"
        result = generate.remove_definition(source, "replace")
        self.assertIn("int keep(void) {return 7;}", result)
        self.assertIn("int replace(void);", result)
        self.assertNotIn("return 9", result)

    def test_nested_scopes_do_not_truncate_the_next_function(self):
        source = "int f(int x) {if(x) {return 1;} return 0;}\nint next(void) {return 2;}\n"
        self.assertTrue(
            generate.remove_definition(source, "f").endswith("int next(void) {return 2;}\n")
        )

    def test_braces_inside_strings_characters_and_comments_are_data(self):
        source = """int f(void) { const char *s="}"; char c='{'; /* } */ // }
        return s[0]+c; }
int next(void) {return 2;}
"""
        self.assertEqual(
            generate.remove_definition(source, "f"), "int f(void);\nint next(void) {return 2;}\n"
        )

    def test_a_compound_literal_call_is_not_a_function_definition(self):
        source = 'void ui(void) {\n    text((Vector2){1,2}, "message");\n}\nvoid text(Vector2 p) {use(p);}\n'
        self.assertIn(
            'text((Vector2){1,2}, "message");', generate.remove_definition(source, "text")
        )

    def test_multiline_parameters_are_supported(self):
        self.assertEqual(
            generate.remove_definition("int f(\n int x,\n int y\n)\n{return x+y;}\n", "f"),
            "int f(\n int x,\n int y\n);\n",
        )

    def test_missing_function_fails_instead_of_silently_generating_it(self):
        with self.assertRaises(ValueError):
            generate.remove_definition("int unrelated(void) {return 1;}", "missing")

    def test_unbalanced_body_fails(self):
        with self.assertRaises(ValueError):
            generate.remove_definition("int f(void) { if(1) { }", "f")

    def test_importing_the_generator_does_not_run_the_compiler(self):
        with patch("subprocess.run") as run:
            importlib.reload(generate)
            run.assert_not_called()


class ArchitectureTests(unittest.TestCase):
    def test_generated_exports_are_limited_to_rendering(self):
        assembly = (ROOT / "src/generated/render.asm").read_text()
        exports = set(re.findall(r"^global (\w+)$", assembly, re.M))
        self.assertEqual(exports, generate.RENDER_EXPORTS)

    def test_generation_rejects_any_gameplay_export(self):
        for symbol in ("main", "UpdateHero", "CalculateDamage", "ManageWaves"):
            with self.subTest(symbol=symbol), self.assertRaises(ValueError):
                generate.validate_render_exports(".globl " + symbol)

    def test_rendering_exports_are_accepted(self):
        generate.validate_render_exports(".globl DrawGame\n.globl DrawMap")

    def test_domain_modules_do_not_import_platform_or_gameplay_operations(self):
        modules = list((ROOT / "src/domain").glob("*.asm"))
        allowed = {"pow", "powf", "fmodf"}
        for path in modules:
            allowed.update(re.findall(r"^global (\w+)$", path.read_text(), re.M))
        for path in modules:
            with self.subTest(module=path.name):
                imports = set(re.findall(r"^extern (\w+)$", path.read_text(), re.M))
                self.assertLessEqual(imports, allowed)

    def test_every_handwritten_module_declares_a_non_executable_stack(self):
        for path in (ROOT / "src").rglob("*.asm"):
            if "generated" not in path.parts:
                with self.subTest(module=str(path.relative_to(ROOT))):
                    self.assertIn(
                        "section .note.GNU-stack noalloc noexec nowrite progbits", path.read_text()
                    )

    def test_no_handwritten_exports_have_duplicate_owners(self):
        owners = {}
        for path in (ROOT / "src").rglob("*.asm"):
            if "generated" in path.parts:
                continue
            for symbol in re.findall(r"^global (\w+)$", path.read_text(), re.M):
                self.assertNotIn(
                    symbol, owners, f"{symbol} is owned by both {owners.get(symbol)} and {path}"
                )
                owners[symbol] = path
        self.assertIn("game", owners)
        self.assertIn("UpdateHero", owners)


if __name__ == "__main__":
    unittest.main()
