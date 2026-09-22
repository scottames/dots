{ lib, stdenvNoCC, fetchurl, installShellFiles }:

# Use the upstream binary until nixpkgs catches up with lockfile v2.
# Keep this version aligned with the lock generator in pr_mise_lock.yaml.
stdenvNoCC.mkDerivation rec {
  pname = "mise";
  version = "2026.9.12";

  src = fetchurl {
    url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-macos-arm64.tar.gz";
    sha256 = "0f1c7f3e74d8c9ae82976e6990058f2bc68821acc6b4c37a68c206c836692419";
  };

  nativeBuildInputs = [ installShellFiles ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 bin/mise "$out/bin/mise"
    installManPage man/man1/mise.1
    installShellCompletion --cmd mise \
      --bash <(bin/mise completion bash) \
      --fish <(bin/mise completion fish) \
      --zsh <(bin/mise completion zsh)
    mkdir -p "$out/lib/mise"
    touch "$out/lib/mise/.disable-self-update"
    runHook postInstall
  '';

  meta = {
    description = "Development tools, environment variables, and tasks";
    homepage = "https://mise.jdx.dev";
    license = lib.licenses.mit;
    mainProgram = "mise";
    platforms = [ "aarch64-darwin" ];
  };
}
