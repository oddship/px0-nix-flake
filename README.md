# px0 Nix flake

A source-built Nix package for [px0](https://github.com/px0-ai/px0), a fast
browser-based code navigator and AI code review tool.

## Try it

```sh
nix run github:oddship/px0-nix-flake -- .
nix run github:oddship/px0-nix-flake -- -agent codex ~/workspace/project
nix run github:oddship/px0-nix-flake -- https://github.com/owner/repo/pull/123
```

px0 opens your browser at http://127.0.0.1:7777. Flags precede the project path.
For headless use, add `-no-open`; `-port 0` chooses a free port.

## NixOS / Home Manager

Add the input (following nixpkgs requires a version with `buildGo126Module`):

```nix
inputs.px0-nix = {
  url = "github:oddship/px0-nix-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then install the package using either `environment.systemPackages` for NixOS
or `home.packages` for Home Manager:

```nix
environment.systemPackages = [
  inputs.px0-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
];
```

An overlay is also available as `overlays.default`, exposing `pkgs.px0`.

## Updates

A daily GitHub Action checks the latest stable upstream release, updates the
version and fixed source/Go dependency hashes with `nix-update`, builds the
package (including upstream Go tests), and tests the installed binary's HTTP UI
and repository API. It commits passing updates directly to `main`, then starts
the multiarch checks. Failed updates leave the previous pin in place.
The daily updater gates publication on x86_64-linux; ARM builds run after publication.

Your system remains reproducible and pinned by its own lock file. To consume a
new package release, run these commands in your system flake:

```sh
nix flake update px0-nix
just switch
```

px0's built-in auto-update is disabled. `px0 -update` explains how to update
through Nix instead. Source builds do not embed an upstream telemetry API key.
Git, GitHub CLI, and (on Linux) xdg-open are included on the runtime PATH.
AI harnesses and language servers are detected from your own environment.

## Maintenance

```sh
nix develop --command bash update.sh       # newest stable release
nix develop --command bash update.sh 0.1.13
nix fmt ./*.nix
nix flake check --all-systems --no-build
nix flake check -L
nix develop --command actionlint
```

Outputs cover x86_64/aarch64 Linux and macOS. CI builds and runs HTTP checks
on both Linux architectures; macOS outputs are evaluated but are not CI-tested.
The frontend is bundled with upstream's dependency-free Node.js bundler and
embedded in the Go binary. The source and Go vendor tree are hash-pinned.
