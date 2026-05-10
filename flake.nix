{
  description = "A Skewed (Quick)shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    quickshell.url = "github:quickshell-mirror/quickshell";
    skwd-daemon.url = "github:liixini/skwd-daemon";
  };

  outputs = { self, nixpkgs, quickshell, skwd-daemon, ... }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in {
      packages = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          qsPkgs = quickshell.inputs.nixpkgs.legacyPackages.${system};

          quickshellWithModules = quickshell.packages.${system}.default.withModules (with qsPkgs.qt6; [
            qtimageformats
            qtmultimedia
            qtsvg
            qt5compat
            qtwayland
          ]);

          daemon = skwd-daemon.packages.${system}.default;

          runtimeDeps = with pkgs; [
            daemon
            matugen
            ffmpeg
            imagemagick
            inotify-tools
            curl
            file
            iwd
          ];

          daemonDeps = runtimeDeps ++ [ quickshellWithModules ];

          fonts = with pkgs; [
            nerd-fonts.symbols-only
            roboto
            roboto-mono
            material-design-icons
          ];
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "skwd";
            version = "unstable";
            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              # skwd-bar
              mkdir -p $out/share/skwd/skwd-bar
              cp -a skwd-bar/shell.qml $out/share/skwd/skwd-bar/shell.qml
              cp -a skwd-bar/qml       $out/share/skwd/skwd-bar/qml
              cp -a skwd-bar/data      $out/share/skwd/skwd-bar/data
              cp -a skwd-bar/ext       $out/share/skwd/skwd-bar/ext
              makeWrapper ${quickshellWithModules}/bin/quickshell $out/bin/skwd-bar \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set SKWD_INSTALL "$out/share/skwd" \
                --set SKWD_BAR_INSTALL "$out/share/skwd/skwd-bar" \
                --add-flags "-p $out/share/skwd/skwd-bar/shell.qml"

              # skwd-launch
              mkdir -p $out/share/skwd/skwd-launch
              cp -a skwd-launch/shell.qml $out/share/skwd/skwd-launch/shell.qml
              cp -a skwd-launch/qml       $out/share/skwd/skwd-launch/qml
              makeWrapper ${quickshellWithModules}/bin/quickshell $out/bin/skwd-launch \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set SKWD_INSTALL "$out/share/skwd" \
                --set SKWD_LAUNCH_INSTALL "$out/share/skwd/skwd-launch" \
                --add-flags "-p $out/share/skwd/skwd-launch/shell.qml"

              # skwd-music
              mkdir -p $out/share/skwd/skwd-music
              cp -a skwd-music/shell.qml $out/share/skwd/skwd-music/shell.qml
              cp -a skwd-music/qml       $out/share/skwd/skwd-music/qml
              cp -a skwd-music/data      $out/share/skwd/skwd-music/data
              makeWrapper ${quickshellWithModules}/bin/quickshell $out/bin/skwd-music \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set SKWD_INSTALL "$out/share/skwd" \
                --set SKWD_MUSIC_INSTALL "$out/share/skwd/skwd-music" \
                --add-flags "-p $out/share/skwd/skwd-music/shell.qml"

              # skwd-notification
              mkdir -p $out/share/skwd/skwd-notification
              cp -a skwd-notification/shell.qml $out/share/skwd/skwd-notification/shell.qml
              cp -a skwd-notification/qml       $out/share/skwd/skwd-notification/qml
              makeWrapper ${quickshellWithModules}/bin/quickshell $out/bin/skwd-notification \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set SKWD_INSTALL "$out/share/skwd" \
                --set SKWD_NOTIFICATION_INSTALL "$out/share/skwd/skwd-notification" \
                --add-flags "-p $out/share/skwd/skwd-notification/shell.qml"

              # skwd-settings
              mkdir -p $out/share/skwd/skwd-settings
              cp -a skwd-settings/shell.qml $out/share/skwd/skwd-settings/shell.qml
              cp -a skwd-settings/qml       $out/share/skwd/skwd-settings/qml
              makeWrapper ${quickshellWithModules}/bin/quickshell $out/bin/skwd-settings \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set SKWD_INSTALL "$out/share/skwd" \
                --set SKWD_SETTINGS_INSTALL "$out/share/skwd/skwd-settings" \
                --add-flags "-p $out/share/skwd/skwd-settings/shell.qml"

              # skwd-switch
              mkdir -p $out/share/skwd/skwd-switch
              cp -a skwd-switch/shell.qml $out/share/skwd/skwd-switch/shell.qml
              cp -a skwd-switch/qml       $out/share/skwd/skwd-switch/qml
              makeWrapper ${quickshellWithModules}/bin/quickshell $out/bin/skwd-switch \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set SKWD_INSTALL "$out/share/skwd" \
                --set SKWD_SWITCH_INSTALL "$out/share/skwd/skwd-switch" \
                --add-flags "-p $out/share/skwd/skwd-switch/shell.qml"

              # daemon CLI + service unit
              makeWrapper ${daemon}/bin/skwd $out/bin/skwd \
                --prefix PATH : ${pkgs.lib.makeBinPath daemonDeps} \
                --set SKWD_INSTALL "$out/share/skwd"

              makeWrapper ${daemon}/bin/skwd-daemon $out/bin/skwd-daemon \
                --prefix PATH : ${pkgs.lib.makeBinPath daemonDeps} \
                --set SKWD_INSTALL "$out/share/skwd"

              mkdir -p $out/lib/systemd/user
              substitute ${daemon}/lib/systemd/user/skwd-daemon.service \
                $out/lib/systemd/user/skwd-daemon.service \
                --replace-fail "${daemon}/bin/skwd-daemon" "$out/bin/skwd-daemon"

              install -Dm644 data/config.json.example $out/share/skwd/data/config.json.example
              install -Dm644 LICENSE $out/share/licenses/skwd/LICENSE

              mkdir -p $out/share/fonts
              for font in ${pkgs.lib.concatMapStringsSep " " toString fonts}; do
                if [ -d "$font/share/fonts" ]; then
                  for f in $(find "$font/share/fonts" -type f); do
                    ln -sf "$f" "$out/share/fonts/$(basename $f)"
                  done
                fi
              done
            '';

            meta = {
              description = "Quickshell-based desktop shell suite (bar, launcher, music, notifications, settings, switcher) backed by skwd-daemon";
              homepage = "https://github.com/liixini/skwd";
              license = pkgs.lib.licenses.mit;
              mainProgram = "skwd-bar";
            };
          };
        });

      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.skwd;
          skwd = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in {
          options.programs.skwd.enable =
            lib.mkEnableOption "Skwd desktop shell suite (bar, launcher, music, notifications, settings, switcher) and skwd-daemon user service";

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ skwd ];
            systemd.packages = [ skwd ];
          };
        };
    };
}
