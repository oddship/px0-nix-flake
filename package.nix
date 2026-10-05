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
  version = "0.1.16";
  src = fetchFromGitHub {
    owner = "px0-ai";
    repo = "px0";
    tag = "v${finalAttrs.version}";
    hash = "sha256-fMV7V80CmgsGO/dL4xbEEtUBYpVBNxDCKyqy574w2KQ=";
  };
  vendorHash = "sha256-71+6I0u3en/Aw3PVMXx6dF+NQtCiE1T+kd7MENCKnlk=";
  subPackages = [ "." ];
  env.CGO_ENABLED = 0;
  nativeBuildInputs = [
    nodejs
    makeWrapper
  ];
  ldflags = [
    "-s"
    "-w"
  ];
  postPatch = ''
    # Nix store binaries cannot replace themselves. Keep updates declarative.
    substituteInPlace main.go \
      --replace-fail 'go autoUpdate(version)' '/* Updates are managed by the Nix flake. */' \
      --replace-fail 'if err := runSelfUpdate(version); err != nil {' \
        'if err := fmt.Errorf("px0 is managed by Nix; update the px0-nix input and rebuild, or run nix profile upgrade px0"); err != nil {'
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
