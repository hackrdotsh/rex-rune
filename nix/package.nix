{
  lib,
  rustPlatform,
  fetchzip,
  runCommand,
  zig,
  pkg-config,
  makeWrapper,
  desktop-file-utils,
  fontconfig,
  libxkbcommon,
  wayland,
  libX11,
  libXcursor,
  libXi,
  libXrandr,
  libGL,
  vulkan-loader,
  glib,
}:
let
  ghosttySource = fetchzip {
    url = "https://tip.files.ghostty.org/83fb95624b0439ee660c2679b43b38c8b63769cd/libghostty-vt-source.tar.gz";
    hash = "sha256-uRtcTrlsOhUl1lBOwn+I2lc+dP9wDs0G8hxqr4T/5Vk=";
  };
  ghosttyDeps = zig.fetchDeps {
    pname = "libghostty-vt";
    version = "83fb956";
    src = ghosttySource;
    fetchAll = true;
    hash = "sha256-82Ife6Av0wfZLmovdEdJFgsG5MI4swCeOB3dbvgBDSU=";
  };
  # Zig 0.17 fetches archives, while --system expects extracted package trees.
  ghosttySystemDeps = runCommand "libghostty-vt-system-deps" { } ''
    mkdir -p $out
    for archive in ${ghosttyDeps}/*.tar.gz; do
      tar -xzf "$archive" -C $out
    done
  '';
  runtimeLibraries = [
    fontconfig
    libxkbcommon
    wayland
    libX11
    libXcursor
    libXi
    libXrandr
    libGL
    vulkan-loader
    glib
  ];
in
rustPlatform.buildRustPackage {
  pname = "rex-linux";
  version = (lib.importTOML ../Cargo.toml).package.version;
  src = lib.cleanSource ../.;

  cargoLock = {
    lockFile = ../Cargo.lock;
    outputHashes."rune-kit-0.0.1" = "sha256-qWQd1il3ccR69j7jQY3Whl3L7odgkaA8RvP+OVY5stA=";
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    desktop-file-utils
    zig
  ];
  buildInputs = runtimeLibraries;

  GHOSTTY_SOURCE_DIR = ghosttySource;
  GHOSTTY_ZIG_SYSTEM_DIR = ghosttySystemDeps;
  dontUseZigBuild = true;
  dontUseZigCheck = true;
  dontUseZigInstall = true;

  preConfigure = ''
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
  '';

  cargoBuildFlags = [ "--bin=rex-linux" ];
  cargoTestFlags = [ "--all-features" ];

  postInstall = ''
    desktop-file-install --dir=$out/share/applications \
      --set-key=Exec --set-value=$out/bin/rex-linux \
      --set-key=TryExec --set-value=$out/bin/rex-linux \
      resources/dev.shuv.rex-linux.desktop
    desktop-file-validate $out/share/applications/dev.shuv.rex-linux.desktop
    for size in 32 128 256; do
      install -Dm644 resources/icons/''${size}x''${size}/apps/dev.shuv.rex-linux.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/dev.shuv.rex-linux.png
    done
    wrapProgram $out/bin/rex-linux \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibraries}
  '';

  meta = {
    description = "Native Linux client for Rex terminal servers";
    homepage = "https://github.com/shuv1337/rex-rune";
    license = lib.licenses.mit;
    mainProgram = "rex-linux";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
