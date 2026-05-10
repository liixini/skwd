%global appname skwd

Name:           skwd
Version:        0.1.0
Release:        1%{?dist}
Summary:        Quickshell-based desktop shell suite backed by skwd-daemon

License:        MIT
URL:            https://github.com/liixini/skwd
Source0:        %{url}/archive/refs/heads/main.tar.gz#/%{name}-main.tar.gz

BuildArch:      noarch

Requires:       skwd-daemon
Requires:       quickshell
Requires:       qt6-qtmultimedia
Requires:       qt6-qtdeclarative
Requires:       qt6-qtimageformats
Requires:       matugen
Requires:       curl
Requires:       file
Requires:       inotify-tools
Requires:       iwd
Requires:       google-roboto-fonts
Requires:       google-roboto-condensed-fonts
Requires:       google-roboto-mono-fonts
Requires:       skwd-fonts
Requires:       cava

%description
A Quickshell-based desktop shell suite consisting of skwd-bar, skwd-launch,
skwd-music, skwd-notification, skwd-settings and skwd-switch. Provides a
status bar, application launcher, media player, notification center, settings
panel and window switcher; backed by skwd-daemon for IPC, lifecycle and
shared state.

%prep
%autosetup -n %{name}-main

%build
# Nothing to build - QML applications

%install
# skwd-bar
install -dm 0755 %{buildroot}%{_datadir}/%{appname}/skwd-bar
cp -a skwd-bar/shell.qml %{buildroot}%{_datadir}/%{appname}/skwd-bar/shell.qml
cp -a skwd-bar/qml       %{buildroot}%{_datadir}/%{appname}/skwd-bar/qml
cp -a skwd-bar/data      %{buildroot}%{_datadir}/%{appname}/skwd-bar/data
cp -a skwd-bar/ext       %{buildroot}%{_datadir}/%{appname}/skwd-bar/ext
install -Dpm 0755 packaging/wrappers/skwd-bar %{buildroot}%{_bindir}/skwd-bar

# skwd-launch
install -dm 0755 %{buildroot}%{_datadir}/%{appname}/skwd-launch
cp -a skwd-launch/shell.qml %{buildroot}%{_datadir}/%{appname}/skwd-launch/shell.qml
cp -a skwd-launch/qml       %{buildroot}%{_datadir}/%{appname}/skwd-launch/qml
install -Dpm 0755 packaging/wrappers/skwd-launch %{buildroot}%{_bindir}/skwd-launch

# skwd-music
install -dm 0755 %{buildroot}%{_datadir}/%{appname}/skwd-music
cp -a skwd-music/shell.qml %{buildroot}%{_datadir}/%{appname}/skwd-music/shell.qml
cp -a skwd-music/qml       %{buildroot}%{_datadir}/%{appname}/skwd-music/qml
cp -a skwd-music/data      %{buildroot}%{_datadir}/%{appname}/skwd-music/data
install -Dpm 0755 packaging/wrappers/skwd-music %{buildroot}%{_bindir}/skwd-music

# skwd-notification
install -dm 0755 %{buildroot}%{_datadir}/%{appname}/skwd-notification
cp -a skwd-notification/shell.qml %{buildroot}%{_datadir}/%{appname}/skwd-notification/shell.qml
cp -a skwd-notification/qml       %{buildroot}%{_datadir}/%{appname}/skwd-notification/qml
install -Dpm 0755 packaging/wrappers/skwd-notification %{buildroot}%{_bindir}/skwd-notification

# skwd-settings
install -dm 0755 %{buildroot}%{_datadir}/%{appname}/skwd-settings
cp -a skwd-settings/shell.qml %{buildroot}%{_datadir}/%{appname}/skwd-settings/shell.qml
cp -a skwd-settings/qml       %{buildroot}%{_datadir}/%{appname}/skwd-settings/qml
install -Dpm 0755 packaging/wrappers/skwd-settings %{buildroot}%{_bindir}/skwd-settings

# skwd-switch
install -dm 0755 %{buildroot}%{_datadir}/%{appname}/skwd-switch
cp -a skwd-switch/shell.qml %{buildroot}%{_datadir}/%{appname}/skwd-switch/shell.qml
cp -a skwd-switch/qml       %{buildroot}%{_datadir}/%{appname}/skwd-switch/qml
install -Dpm 0755 packaging/wrappers/skwd-switch %{buildroot}%{_bindir}/skwd-switch

# skwd-power
install -dm 0755 %{buildroot}%{_datadir}/%{appname}/skwd-power
cp -a skwd-power/shell.qml %{buildroot}%{_datadir}/%{appname}/skwd-power/shell.qml
cp -a skwd-power/qml       %{buildroot}%{_datadir}/%{appname}/skwd-power/qml
install -Dpm 0755 packaging/wrappers/skwd-power %{buildroot}%{_bindir}/skwd-power

install -Dpm 0644 data/config.json.example %{buildroot}%{_datadir}/%{appname}/data/config.json.example
install -Dpm 0644 LICENSE %{buildroot}%{_datadir}/licenses/%{name}/LICENSE

%post
echo "skwd installed."
echo "Make sure skwd-daemon is running:"
echo "  systemctl --user enable --now skwd-daemon.service"
echo "Available shells (launch via your compositor's spawn keybind):"
echo "  skwd-bar, skwd-launch, skwd-music, skwd-notification,"
echo "  skwd-power, skwd-settings, skwd-switch"

%files
%license LICENSE
%{_datadir}/%{appname}/
%{_bindir}/skwd-bar
%{_bindir}/skwd-launch
%{_bindir}/skwd-music
%{_bindir}/skwd-notification
%{_bindir}/skwd-power
%{_bindir}/skwd-settings
%{_bindir}/skwd-switch
