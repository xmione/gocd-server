# Git Comparison Reference Guide

This guide summarizes how to compare files and branches when working between a **feature branch** and a **master/main** branch.

## 1. Comparing Files with VS Code (Windows/PowerShell)
To compare a specific file (e.g., `package.json`) side-by-side using VS Code as your diff tool.

### One-Time Setup
Configure Git to use VS Code as the default tool:
```powershell
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
```

### Run Comparison
```powershell
git difftool master package.json
```

---

## 2. Viewing File Status
Use these commands to see which files are new, modified, or deleted without seeing the actual code changes.

| Command | Description |
| :--- | :--- |
| `git diff master --name-status` | Shows file paths with status (A=Added, M=Modified, D=Deleted) |
| `git diff master --name-only` | Shows a clean list of changed filenames |
| `git diff master --stat` | Shows a summary of insertions and deletions per file |

---

## 3. Viewing Content in Terminal
If you just want a quick look at the differences or the content of a file on another branch.

- **See line-by-line changes:**
  ```bash
  git diff master path/to/file.ext
  ```
- **View the version of a file on master (without switching branches):**
  ```bash
  git show master:path/to/file.ext
  ```

---

## 4. Understanding Symbols
When using `--name-status`, the letters indicate the following:
* **A**: Added — The file is new in your current branch.
* **M**: Modified — The file exists in both, but the code is different.
* **D**: Deleted — The file was removed in your current branch but exists in master.

---

## 5. Branch vs. Merge Base
- **`git diff master..HEAD`**: Compares the tip of master to your current work.
- **`git diff master...HEAD`**: Compares the "merge base" (the point where you branched off) to your current work. This is usually what you want for Pull Requests.