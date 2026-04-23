# Remove a Secret File from Git History

## Set Your Default Editor First

Notepad is commonly used for Windows:
```
git config --global core.editor "notepad"
```

nano is commonly used for Linux:
```
git config --global core.editor "nano"
```

---

## Know First the Commit ID That Has the Secret

```
git log --oneline
```

This gives you a clean list like:
```
a1b2c3d (HEAD -> feature-create-solvpn-deployment) latest commit message
f8f4cbe accidentally added env.passphrase.txt   <-- this one
9e8d7c6 some earlier commit
```

---

## For a More Specific Search If You Don't Know the Commit ID

Search by filename:
```
git log --oneline -S "env.passphrase.txt"
```

Or search by the actual secret string inside the file:
```
git log --oneline -S "your_secret_value"
```

Or use `--all` to search across all branches:
```
git log --all --oneline -S "env.passphrase.txt"
```

---

## Interactive Rebase Back to Before That Commit

```
git rebase -i f8f4cbed~1
```

In the editor, change `pick` to `edit` on `f8f4cbe`, save and close.
## If in case you've messed up the file, you can abort:
```
git rebase --abort
```
 or if you accidentally closed the file you can still continue:
 ```
 git rebase --continue
 ```
---

## Remove the File from That Commit

```
git rm --cached env.passphrase.txt
echo "env.passphrase.txt" >> .gitignore
git commit --amend --no-edit
```

---

## Continue Rebase

```
git rebase --continue
git push origin feature-create-solvpn-deployment --force
```