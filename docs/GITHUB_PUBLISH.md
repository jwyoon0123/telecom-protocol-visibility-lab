# GitHub Publish Procedure

## 1. Local validation

```bash
make check
```

## 2. Review license decision

Read `docs/LICENSING.md`. The package intentionally does not make this legal decision for the repository owner.

## 3. Initialize repository

```bash
git init
git branch -M main
git add .
git status
git diff --cached
```

Verify that `config/secrets.env`, generated configs, PCAP, logs and backups are not staged.

## 4. Commit and push

```bash
git commit -m "Initial public virtual mobile telecom lab"
git remote add origin <YOUR_GITHUB_REPOSITORY_URL>
git push -u origin main
```

## 5. Create release artifact

```bash
make package
```

The release builder runs syntax and safety scans before creating the ZIP and SHA-256 file.
