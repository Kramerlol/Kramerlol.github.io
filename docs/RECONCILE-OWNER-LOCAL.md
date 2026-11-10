# Owner Local Reconciliation — run this on YOUR machine (PowerShell)

Goal: retire the old messy local clones and end up with exactly one fresh clone matching `main` at https://github.com/Kramerlol/Kramerlol.github.io. Your earlier attempt compared against a stale nested clone and missed the stray `~/assets` — the compare loop below covers BOTH stray folders (`~/docs` and `~/assets`).

> **Everything under the repo root is PUBLIC** at `https://kramerlol.github.io/<path>` (including `docs/`). Never put anything private in this repo.

## Rule

Always use `git -C <repo>` and run `git rev-parse --show-toplevel` before any git command, so you know which working tree you are in.

## Step a — Inventory stray top-level repo folders

```powershell
Test-Path "$env:USERPROFILE\.git"                       # a stray repo at the profile root?
Test-Path "$env:USERPROFILE\docs"                      # stray docs folder
Test-Path "$env:USERPROFILE\assets"                     # stray assets folder
Test-Path "$env:USERPROFILE\websites"                   # the old clone(s) live here
```

If `~\.git` exists (a repo accidentally created at your profile root), park it — do NOT delete yet:

```powershell
Rename-Item "$env:USERPROFILE\.git" ".git.PARKED"      # neutralize; delete later once satisfied
```

## Step b — Fresh clone (the single source of truth going forward)

```powershell
gh repo clone Kramerlol/Kramerlol.github.io "$env:USERPROFILE\code\kramerlol.github.io"
$repo = "$env:USERPROFILE\code\kramerlol.github.io"
git -C $repo rev-parse --show-toplevel                  # sanity: which tree is this?
git -C $repo status -sb
git -C $repo log --oneline -6
```

You should see `origin/main` clean, with recent history containing the Phase 3 merge (`Merge pull request #18 ...`).

## Step c — Compare the TWO stray folders against the fresh clone

This is the two-mapping loop (checks BOTH `~\docs` and `~\assets`, which the earlier attempt missed):

```powershell
$map = @{
  "$env:USERPROFILE\docs"    = "$repo\docs"
  "$env:USERPROFILE\assets"  = "$repo\assets"
}
foreach ($local in $map.Keys) {
  $remote = $map[$local]
  if (-not (Test-Path $local)) { Write-Host "SKIP (absent): $local"; continue }
  Write-Host "`n== $local =="
  Get-ChildItem -Recurse -File $local | ForEach-Object {
    $rel   = $_.FullName.Substring($local.Length + 1)
    $match = Join-Path $remote $rel
    if (-not (Test-Path $match)) {
      Write-Host "ONLY-LOCAL: $rel"                      # file not in the real repo
    } elseif ((Get-FileHash $_.FullName).Hash -ne (Get-FileHash $match).Hash) {
      Write-Host "DIFFERS:     $rel"                     # different content vs repo
    }
  }
}
```

Review everything printed. If a file matters, copy it into `$repo` and open a PR — do not hand-edit outside the repo.

## Step d — Delete strays ONLY if Step c printed nothing (or only disposable files)

```powershell
# ONLY after you are satisfied with the Step c output:
Remove-Item -Recurse -Force "$env:USERPROFILE\docs", "$env:USERPROFILE\assets"
```

## Step e — Retire the old clone under ~\websites

Check whether the old clone has anything of value:

```powershell
git -C "$env:USERPROFILE\websites" status -sb
git -C "$env:USERPROFILE\websites" log --oneline origin/main..main   # commits only in the old local main
git -C "$env:USERPROFILE\websites" diff origin/main > "$env:USERPROFILE\websites-local-changes.patch"
```

If `git log --merges --oneline` there shows **merge commits only** and the patch is trivial/empty, the old clone is stale and safe to retire:

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\websites"
```

Keep `websites-local-changes.patch` until you are sure. **NEVER `git push` from the old clone** — pushes come only from the fresh `$repo` (or from the assistant via PRs).

## Step f — Final state

```powershell
git -C $repo fetch
git -C $repo checkout main
git -C $repo pull
git -C $repo status -sb        # expect: nothing to commit, working tree clean
```

After any merge to `main`, hard-refresh https://kramerlol.github.io (Pages caches aggressively; allow ~1 minute for deploys).
