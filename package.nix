{
  lib,
  stdenv,
  buildGo126Module,
  fetchFromGitHub,
  fetchurl,
  nodejs,
  makeWrapper,
  git,
  gh,
  xdg-utils,
}:
buildGo126Module (finalAttrs: {
  pname = "px0";
  version = "0.1.19";
  src = fetchFromGitHub {
    owner = "px0-ai";
    repo = "px0";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ogt7wfYw1Vhsl5ACqPJyyAReeuss26qOW2yROCZTtXY=";
  };
  vendorHash = "sha256-GJAd0mo4s7ybFizzXvfT79CyDR/qC6BkbUtS/2y1XEI=";
  subPackages = [ "." ];
  env.CGO_ENABLED = 0;
  # Upstream fixed multiline import stripping in v0.1.19.
  patches = lib.optionals (lib.versionOlder finalAttrs.version "0.1.19") [
    ./patches/node-multiline-imports.patch
  ];
  nativeBuildInputs = [
    nodejs
    makeWrapper
  ];
  ldflags = [
    "-s"
    "-w"
  ];
  postPatch =
    let
      legacyUpdater = lib.versionOlder finalAttrs.version "0.1.20";
      autoUpdate = if legacyUpdater then "autoUpdate" else "update.AutoUpdate";
      selfUpdate = if legacyUpdater then "runSelfUpdate" else "update.RunSelfUpdate";
    in
    ''
      # Nix store binaries cannot replace themselves. Keep updates declarative.
      substituteInPlace main.go \
        --replace-fail 'go ${autoUpdate}(version)' '/* Updates are managed by the Nix flake. */' \
        --replace-fail 'if err := ${selfUpdate}(version); err != nil {' \
          'if err := fmt.Errorf("px0 is managed by Nix; update the px0-nix input and rebuild, or run nix profile upgrade px0"); err != nil {'
    ''
    + lib.optionalString (!legacyUpdater) ''
      # All updater references above are removed, so the extracted updater import is unused.
      substituteInPlace main.go --replace-fail '"px0/internal/update"' ""
    '';
  preBuild = ''
    # Upstream no longer includes this runtime asset in its source archive.
    # Preserve the bundle from the last release that shipped it.
    cp ${
      fetchurl {
        url = "https://raw.githubusercontent.com/px0-ai/px0/v0.1.14/web/vendor/mermaid-12.0.0.min.js";
        hash = "sha256-KPynrm68fte7Y73mMTanS/7xTylqV+QDZX7rizKDYHM=";
      }
    } web/vendor/mermaid-12.0.0.min.js
    node scripts/build-web.js
    node --check web/app.js
    if [ -f web/workbench.js ]; then
      node --check web/workbench.js
    fi
  '';
  nativeCheckInputs = [ git ];
  preCheck = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
  '';
  postInstall = ''
    wrapProgram "$out/bin/px0" --prefix PATH : ${
      lib.makeBinPath (
        [
          git
          gh
        ]
        ++ lib.optionals (stdenv.hostPlatform.isLinux) [ xdg-utils ]
      )
    }
  '';
  meta = {
    description = "Fast browser-based code navigator and AI code review tool";
    homepage = "https://github.com/px0-ai/px0";
    license = lib.licenses.mit;
    mainProgram = "px0";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
