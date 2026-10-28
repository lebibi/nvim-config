"""The formatters a project's pre-commit hooks run on each file, as stdin commands.

    python precommit_formatters.py <root> <file>...

Runs under pre-commit's own interpreter, which carries yaml and identify. Prints JSON:
{"missing": bool, "files": {file: [formatter, ...]}}. A formatter is {"name", "cmd"} with
"{file}" standing for the file's path, or {"name", "builtin"} for conform's own trims.
"missing" is true when a hook's environment is not installed yet. A local hook with
no environment runs its entry from PATH, as pre-commit does.
"""

from __future__ import annotations

import glob
import json
import os
import re
import shlex
import shutil
import sqlite3
import sys

import yaml
from identify import identify

# Formatting hooks as stdin-to-stdout commands. `drop` lists their in-place flags.
STDIN = {
    "ruff-format": {"tail": ["--stdin-filename", "{file}", "-"], "drop": []},
    "ruff": {
        "tail": ["--exit-zero", "--stdin-filename", "{file}", "-"],
        "drop": [],
        "needs": "--fix",
    },
    "ruff-check": {
        "tail": ["--exit-zero", "--stdin-filename", "{file}", "-"],
        "drop": [],
        "needs": "--fix",
    },
    "black": {"tail": ["-q", "--stdin-filename", "{file}", "-"], "drop": []},
    "isort": {"tail": ["--filename", "{file}", "-"], "drop": []},
    "clang-format": {"tail": ["--assume-filename={file}"], "drop": ["-i"]},
    "prettier": {"tail": ["--stdin-filepath", "{file}"], "drop": ["--write", "-w"]},
}
# pre-commit's own names for local environments, and the languages that use none.
LOCAL_REF = "1"
PATH_LANGUAGES = {"system", "unsupported", "script", "unsupported_script"}
BUILTIN = {
    "end-of-file-fixer": "trim_newlines",
    "trailing-whitespace": "trim_whitespace",
}


def env_paths() -> dict[tuple[str, str], str]:
    db = os.path.join(
        os.environ.get("PRE_COMMIT_HOME", os.path.expanduser("~/.cache/pre-commit")),
        "db.db",
    )
    if not os.path.exists(db):
        return {}
    with sqlite3.connect(db) as connection:
        return {
            (repo, ref): path
            for repo, ref, path in connection.execute(
                "select repo, ref, path from repos"
            )
        }


def executable(env: str, name: str) -> str | None:
    for found in sorted(glob.glob(os.path.join(env, "*_env-*", "bin", name))):
        if os.access(found, os.X_OK):
            return found
    return None


def matches(hook: dict, tags: set[str], path: str) -> bool:
    if hook.get("types") and not set(hook["types"]) <= tags:
        return False
    if hook.get("types_or") and not set(hook["types_or"]) & tags:
        return False
    if set(hook.get("exclude_types") or []) & tags:
        return False
    if hook.get("files") and not re.search(hook["files"], path):
        return False
    return not (
        hook.get("exclude")
        and hook["exclude"] != "^$"
        and re.search(hook["exclude"], path)
    )


def local_env(envs: dict[tuple[str, str], str], hook: dict) -> str | None:
    deps = hook.get("additional_dependencies") or []
    return envs.get((f"local:{','.join(deps)}" if deps else "local", LOCAL_REF))


def hooks(root: str) -> tuple[list[dict], bool, dict]:
    with open(os.path.join(root, ".pre-commit-config.yaml")) as handle:
        config = yaml.safe_load(handle) or {}
    envs, found, missing = env_paths(), [], False
    for repo in config.get("repos") or []:
        url, ref = repo.get("repo"), repo.get("rev")
        if url == "meta":
            continue
        env = None if url == "local" else envs.get((url, ref))
        manifest = {}
        if env and os.path.exists(os.path.join(env, ".pre-commit-hooks.yaml")):
            with open(os.path.join(env, ".pre-commit-hooks.yaml")) as handle:
                manifest = {h["id"]: h for h in yaml.safe_load(handle) or []}
        for override in repo.get("hooks") or []:
            hook_id = override.get("id")
            if hook_id not in STDIN and hook_id not in BUILTIN:
                continue
            hook = {**manifest.get(hook_id, {}), **override, "rev": ref}
            if url == "local":
                env = local_env(envs, hook)
                if env is None and hook.get("language") not in PATH_LANGUAGES:
                    missing = missing or hook_id in STDIN
                    continue
            elif hook_id in STDIN and (not env or hook_id not in manifest):
                missing = True
                continue
            hook["env"] = env
            found.append(hook)
    return found, missing, config


def formatters(hook: dict) -> dict | None:
    hook_id = hook["id"]
    if hook_id in BUILTIN:
        return {"name": hook_id, "builtin": BUILTIN[hook_id]}
    spec = STDIN[hook_id]
    args = list(hook.get("args") or [])
    if spec.get("needs") and spec["needs"] not in args:
        return None
    entry = shlex.split(hook.get("entry", hook_id))
    if hook["env"]:
        binary = executable(hook["env"], entry[0])
    else:
        binary = shutil.which(entry[0])
    if not binary:
        return None
    cmd = (
        [binary] + [a for a in entry[1:] + args if a not in spec["drop"]] + spec["tail"]
    )
    name = f"{hook_id}@{hook['rev']}" if hook.get("rev") else hook_id
    return {"name": name, "cmd": cmd}


def main() -> None:
    root, files = sys.argv[1], sys.argv[2:]
    found, missing, config = hooks(root)
    top_files, top_exclude = config.get("files", ""), config.get("exclude", "^$")
    out = {}
    for file in files:
        rel = os.path.relpath(os.path.abspath(file), root)
        chosen = []
        if (not top_files or re.search(top_files, rel)) and not (
            top_exclude != "^$" and re.search(top_exclude, rel)
        ):
            try:
                tags = identify.tags_from_path(file)
            except ValueError:
                tags = identify.tags_from_filename(file)
            for hook in found:
                if matches(hook, tags, rel):
                    made = formatters(hook)
                    if made:
                        chosen.append(made)
        out[file] = chosen
    json.dump({"missing": missing, "files": out}, sys.stdout)


if __name__ == "__main__":
    main()
