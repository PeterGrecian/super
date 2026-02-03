# bin

Scripts for managing repos alongside `super`.

| Script | What it does |
|---|---|
| `todo` | Appends a note to `TODO.md` at the current repo's root, commits, and pushes |
| `clone-all-repos` | Clones any GitHub repos not already present locally |
| `sync-repos.sh` | Pulls, pushes, commits, and collects TODOs across all local sibling repos |
| `collect-todos.py` | Scans sibling repos for TODO/FIXME/BUG markers and writes `TODO.md` |
