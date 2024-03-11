# flakes

A hack to efficiently install the flakes maintained at my home.

This is for:
- "dirty" (local, unlocked, probably temporary) flakes and packages
- ... that I currently maintain and install
- ... but do not want in my home-manager profile

It basically reinvents the "dirtiness" of `nix-env` and `nix-channel` with flakes.

Why? Here are some facts:
- each project has to be in its own git repository
- each package carries along its own dependencies, e.g. `nixpkgs`
- nix is terrible with git submodules, at least for now

Without this hack, we have the following problems:
- there will be N copies of deps, e.g. `nixpkgs` floating in my system
- bringing them up to date requires many `cd`s and `nix flake update`s

This flake solves the problem by:
- gathering all these packages into a single env so I can `nix profile install` all of them
- redirecting common dependencies e.g. `nixpkgs` to the nix registry so I can `nix flake update` all of them
- circumventing the submodule issues with a separate `--git-dir` at some other location; more on that later

## no home-manager

I _do_ use home-manager but these are the temporary packages I specifically do _not_ want to keep track of.
We are emulating the cursed `nix-env` functionality with `nix-channel`, where things are dirty yet efficient.

## no `.git`

If nix handled submodules gracefully, there would be no need for this hack.
However, nix does not, which means that this flake needs to:
- present itself as a `path` to nix, yet
- be a secret git repository for efficient bookkeeping.

Fortunately, git provides the `--separate-git-dir` flag for relocating the `.git` directory somewhere else,
so that nix could not identify this flake as a git repository.
We can then use a special `git` wrapped with the `--git-dir` flag to manage this repository.
This special `git` is defined in the `flake.nix` itself.
Combined with the help of `.envrc` and `devShells`, this wrapped git can be presented to the user seamlessly,
while keeping the git repository hidden from nix.

## no `flake.lock`

`flake.lock` is no checked into the repository, because it contains dynamically generated store paths
in the form of
```
file:///nix/store/qpifqsm65cc86nn001nk860cjrgdk3mf-source/...
```
where the hash changes whenever the host repository changes. This is not useful at all.
Relatedly, `.envrc` contains `nix_direnv_manual_reload` to avoid reloading all the time.
