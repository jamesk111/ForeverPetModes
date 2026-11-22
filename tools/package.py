"""Build and verify the install ZIP using only the Python standard library."""
import argparse
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
NAME = "ForeverPetModes"
SOURCE = ROOT / NAME


def package(version, destination):
    toc = SOURCE / f"{NAME}.toc"
    lines = toc.read_text(encoding="utf-8").splitlines()
    for required in ("## Interface: 16001", "## SavedVariables: ForeverPetModesDB",
                     f"## Version: {version}", "## AllowLoadGameType: camelot"):
        if required not in lines:
            raise ValueError(f"Manifest missing {required}")
    modules = [line for line in lines if line.strip() and not line.startswith("#")]
    if any(Path(line).name != line or not line.endswith(".lua") for line in modules):
        raise ValueError("Expected top-level Lua module names")
    if len(set(modules)) != len(modules) or set(modules) != {p.name for p in SOURCE.glob("*.lua")}:
        raise ValueError("Manifest must list every Lua module exactly once")
    files = [toc, *(SOURCE / name for name in modules), ROOT / "LICENSE"]
    destination.mkdir(parents=True, exist_ok=True)
    target = destination / f"{NAME}-v{version}.zip"
    with ZipFile(target, "w") as archive:
        for file in files:
            info = ZipInfo(f"{NAME}/{file.name}", (2026, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, file.read_bytes(), compress_type=ZIP_DEFLATED)
    with ZipFile(target) as archive:
        assert archive.testzip() is None
        assert archive.namelist() == [f"{NAME}/{file.name}" for file in files]
        for file in files:
            assert archive.read(f"{NAME}/{file.name}") == file.read_bytes()
    return target


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("version", help="manifest version without the v prefix")
    parser.add_argument("--out", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    print(package(args.version, args.out))
