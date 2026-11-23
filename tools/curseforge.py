"""Submit the tested release ZIP to the existing CurseForge project."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess


API = "https://wow.curseforge.com/api"
PROJECT = 1826325
GAME_VERSION = "1.60.1"
PENDING = "CurseForge upload pending"


def release_notes(changelog, tag):
    sections = re.split(r"^## (\S+)[^\n]*\n", changelog, flags=re.MULTILINE)
    for heading, body in zip(sections[1::2], sections[2::2]):
        if heading == tag and body.strip():
            return body.strip()
    raise ValueError(f"Missing changelog entry for {tag}")


def curseforge(path, *arguments):
    token = os.environ.get("CF_API_TOKEN")
    if not token:
        raise ValueError("Missing repository secret CF_API_TOKEN")
    result = subprocess.run(
        ["curl", "--silent", "--show-error", "--fail", "--max-time", "120",
         "--header", "@-", *arguments, f"{API}/{path}"],
        input=f"X-Api-Token: {token}\n", text=True, stdout=subprocess.PIPE, check=True,
    )
    return json.loads(result.stdout)


def metadata(tag, versions, notes):
    matches = [v["id"] for v in versions if v["name"] == GAME_VERSION]
    if len(matches) != 1:
        raise ValueError(f"Expected one CurseForge version for WoW {GAME_VERSION}, found {matches}")
    return {"displayName": f"Forever Pet Modes {tag}", "releaseType": "release",
            "gameVersions": matches, "changelogType": "markdown", "changelog": notes}


def github(path, *arguments):
    return json.loads(subprocess.check_output(["gh", "api", path, *arguments], text=True))


def publish(tag, archive, data):
    repo = os.environ["GITHUB_REPOSITORY"]
    release = github(f"repos/{repo}/releases/tags/{tag}")
    asset, = [a for a in release["assets"] if a["name"] == archive.name]
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    if asset["digest"] != f"sha256:{digest}":
        raise ValueError("The tested ZIP differs from the published GitHub asset")
    label = asset.get("label") or ""
    if re.fullmatch(re.escape(archive.name) + r" \(CurseForge file [1-9]\d*\)", label):
        print(f"Already submitted: {label}")
        return
    if label:
        raise ValueError(f"Asset label is '{label}'. Check the CurseForge Files page before retrying.")
    asset_path = f"repos/{repo}/releases/assets/{asset['id']}"
    github(asset_path, "--method", "PATCH", "-f", f"label={archive.name} ({PENDING})")
    result = curseforge(f"projects/{PROJECT}/upload-file", "--form-string",
                        f"metadata={json.dumps(data)}", "--form", f"file=@{archive}")
    file_id = result["id"]
    if type(file_id) is not int or file_id <= 0:
        raise ValueError("CurseForge returned no valid file ID. Check the Files page.")
    print(f"CurseForge accepted file {file_id}", flush=True)
    github(asset_path, "--method", "PATCH", "-f", f"label={archive.name} (CurseForge file {file_id})")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tag")
    parser.add_argument("--check-only", action="store_true", help="Check credentials and metadata without uploading")
    args = parser.parse_args()
    if not re.fullmatch(r"v\d+\.\d+\.\d+", args.tag):
        parser.error("Expected a stable vX.Y.Z release tag")
    notes = release_notes(Path("CHANGELOG.md").read_text(encoding="utf-8"), args.tag)
    data = metadata(args.tag, curseforge("game/versions"), notes)
    print(f"Resolved WoW {GAME_VERSION} to {data['gameVersions']} for project {PROJECT}.")
    if not args.check_only:
        publish(args.tag, Path("dist") / f"ForeverPetModes-{args.tag}.zip", data)


if __name__ == "__main__":
    main()
