# Implementation Plan: Lightweight Modular NixOS Flake for YUV-PC

**Status**: v2 approved. Phases 1–6 are implemented. They evaluate and dry-run build in WSL but have not been tested on hardware. Next is Phase 7.

**Changes made during implementation (Phases 4–6):**
- `AQ_DRM_DEVICES` is set through `environment.sessionVariables` (system-wide), not a UWSM env file. The udev alias is `/dev/dri/primary-gpu`, and it only becomes active once `primaryPciAddress` is set in `hosts/YUV-PC/gpu.nix`.
- `programs.gamescope.capSysNice = false`, because the capability wrapper fails inside Steam's bubblewrap sandbox. ananicy-cpp handles process priorities instead.
- The Quickshell bar shows workspaces and a clock only. Tray and volume widgets, and click-to-switch workspaces, are added after it runs on hardware.
- No NVENC apps (OBS, ffmpeg-full) are installed yet. The driver and `nvidia-smi` are in place.
**Complexity**: Large. Phases 1–6 give a usable gaming desktop. Phases 7–9 are VFIO, Secure Boot and ARM.
**Repo state**: empty. There are no existing patterns to follow, so this plan sets the conventions.

---

## 1. Requirements

| # | Requirement | What this config does |
|---|---|---|
| 1 | Flake, installable with `nixos-install` from a live USB | `nixos-install --flake .#YUV-PC --no-root-passwd` from the stock NixOS ISO. Partitioning is declarative (disko). |
| 2 | Modular, ARM later (with kernel compilation), x86_64 first | `mkHost { system = …; }` helper. Modules sit behind `my.*` options. A reusable custom-kernel module also covers cross-compiling for aarch64. |
| 3 | Secret encryption planned, not now | Every secret-shaped value lives in `secrets/` and is read through `*File` options. Moving to sops-nix later only touches that folder. |
| 4 | CachyOS gaming optimizations | CachyOS kernel (nix-cachyos-kernel), scx, ananicy-cpp + CachyOS rules, zram, and the CachyOS-Settings values **checked against upstream** (section 4). |
| 5 | EAC Linux v2: as close as possible, kept simple | **One boot entry**, no draft kernel. It turns on the requirements that cost nothing (Secure Boot, TPM, BPF LSM, kexec off, IOMMU in translated mode). It does not enforce lockdown or module signatures, because those would reject the unsigned NVIDIA module (section 6). |
| 6 | Emulation + single-GPU passthrough | KVM/libvirt hooks hand the **RX 6900 XT** to a Windows 11 guest. The guest has a TPM, Secure Boot, hugepages and CPU pinning so anti-cheat games run where their anti-cheat allows VMs. The GTX 1050 Ti stays on the host for NVENC. aarch64 binfmt is included. |
| 7 | Home Manager | NixOS module, `release-26.05`. |
| 8 | nixos-hardware | `gigabyte-b550`, `common-cpu-amd`, `common-cpu-amd-pstate`, `common-gpu-amd`, `common-pc`, `common-pc-ssd`. |
| 9 | Hyprland **configured in Lua**, Quickshell (nixpkgs), greetd autologin | Hyprland 0.55.4 (in 26.05; this is the first release with Lua config), HM `configType = "lua"`, `pkgs.quickshell`, greetd `initial_session`. |
| 10 | PipeWire | For now: PipeWire with ALSA, PulseAudio and JACK, and nothing else. |
| 11 | No root password | `root.hashedPassword = "!"`, `--no-root-passwd`, admin access only through `wheel`. |
| — | Stable base | `nixos-26.05` everywhere. `nixos-unstable` is exposed as `pkgs.unstable` and used only for packages chosen on purpose. |

**Identity**: user `fantomtchi7`, hostname `YUV-PC`. The flake attribute is `nixosConfigurations."YUV-PC"` and host files live in `hosts/YUV-PC/`.

---

## 2. Repository Layout

```
nixos-config/
├── flake.nix
├── flake.lock
├── lib/
│   ├── default.nix               # mkHost
│   └── vars.nix                  # username = "fantomtchi7"; timezone; locale
├── hosts/
│   ├── YUV-PC/
│   │   ├── default.nix           # imports + my.* toggles
│   │   ├── hardware.nix          # from nixos-generate-config --no-filesystems
│   │   ├── disko.nix             # GPT + ESP + btrfs subvolumes
│   │   ├── gpu.nix               # PCI addresses of 6900 XT functions + 1050 Ti
│   │   └── vms/win11.xml         # reference libvirt domain (not auto-defined)
│   └── arm-board/                # stub (Phase 9)
├── modules/
│   ├── nixos/
│   │   ├── default.nix
│   │   ├── core/                 # nix.nix users.nix locale.nix networking.nix boot.nix
│   │   ├── kernel/               # cachyos.nix custom.nix
│   │   ├── performance/          # scx.nix ananicy.nix zram.nix cachyos-settings.nix
│   │   ├── hardware/             # amdgpu.nix nvidia.nix gpu-priority.nix
│   │   ├── security/             # secureboot.nix tpm.nix hardening.nix
│   │   ├── desktop/              # hyprland.nix greetd.nix portals.nix fonts.nix
│   │   ├── audio/pipewire.nix
│   │   ├── gaming/               # steam.nix gamescope.nix tools.nix
│   │   └── virtualisation/       # libvirt.nix vfio-single-gpu.nix win11-guest.nix binfmt.nix hooks/
│   └── home/
│       ├── hyprland/
│       │   ├── default.nix       # configType = "lua"; thin generated hyprland.lua
│       │   └── lua/              # hand-written: binds.lua rules.lua looks.lua …
│       ├── quickshell/           # default.nix + config/ (QML)
│       └── shell/ …
├── users/fantomtchi7/home.nix
├── overlays/default.nix          # pkgs.unstable + local pkgs
├── pkgs/                         # iommu-groups, eac-status
├── secrets/
│   ├── README.md                 # sops-nix migration path
│   └── fantomtchi7.hash          # plaintext yescrypt hash, not encrypted yet
└── PLAN.md
```

**Conventions:**
- Each module declares `options.my.<area>.<feature>` with `lib.mkEnableOption` and wraps its config in `lib.mkIf cfg.enable`.
- Hosts only flip toggles and provide hardware data.
- File names are kebab-case, one concern per file.
- Rules between options are enforced with `assertions`, for example `my.vfio.enable → my.desktop.greetd.enable`.

---

## 3. Flake Inputs (stable first)

| Input | URL | Notes |
|---|---|---|
| `nixpkgs` | `github:NixOS/nixpkgs/nixos-26.05` | Base system. 26.05 is supported until **2026-12-31**. Moving to `nixos-26.11` after its release (late Nov 2026) means changing the two `26.05` references. |
| `nixpkgs-unstable` | `github:NixOS/nixpkgs/nixos-unstable` | Only exposed as `pkgs.unstable` through an overlay. |
| `home-manager` | `github:nix-community/home-manager/release-26.05` | follows `nixpkgs` |
| `nixos-hardware` | `github:NixOS/nixos-hardware` | |
| `nix-cachyos-kernel` | `github:xddxdd/nix-cachyos-kernel/release` | **Do not** make it follow nixpkgs. Use `overlays.pinned` so builds come from its binary cache. |
| `disko` | `github:nix-community/disko` | follows `nixpkgs` |
| `lanzaboote` | `github:nix-community/lanzaboote/<release tag>` | Added in Phase 8 |

Binary caches: `cache.nixos.org`, `nix-community.cachix.org`, and `https://cache.lantian.pub/lantian` with key `lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=`.

**What comes from unstable.** Nothing is required at the start. Hyprland 0.55.4 (with Lua), Quickshell 0.3.0, ananicy-rules-cachyos and scx are all in 26.05. Packages can move to `pkgs.unstable.*` on purpose, one at a time. Likely first candidates are `proton-ge-bin` and `gamescope`. **One rule:** if Hyprland moves to unstable, `hardware.graphics.package`/`package32` (Mesa) move with it, because a Mesa version mismatch breaks the compositor.

---

## 4. CachyOS Settings: Checked Against Upstream

Source: [CachyOS/CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings) `master` (fetched 2026-10-27) and the CachyOS installer's `kernelParams: [ "quiet", "nowatchdog" ]`.

**Corrections to draft v1:**
- NVMe uses **kyber**, not `none`.
- Swappiness ends up at **150** while zram is active (set by a udev rule), not 100.
- `vm.watermark_*`, `vm.max_map_count` and `kernel.split_lock_mitigate` are **not** in CachyOS-Settings and have been removed. NixOS already sets `vm.max_map_count = 1048576`.

| CachyOS file | Upstream value | NixOS implementation (`performance/cachyos-settings.nix` unless noted) |
|---|---|---|
| `sysctl.d/70-cachyos-settings.conf` | `vm.swappiness=100`, `vm.vfs_cache_pressure=50`, `vm.dirty_bytes=268435456`, `vm.dirty_background_bytes=67108864`, `vm.dirty_writeback_centisecs=1500`, `vm.page-cluster=0`, `kernel.nmi_watchdog=0`, `kernel.unprivileged_userns_clone=1`, `kernel.printk="3 3 3 3"`, `kernel.kptr_restrict=2`, `kernel.sysrq=1`, `net.core.netdev_max_backlog=4096`, `fs.file-max=2097152` | `boot.kernel.sysctl`, copied one to one. Swappiness is set to **150** directly (see the zram row). `unprivileged_userns_clone` relies on the CachyOS kernel patch, which this kernel has. |
| `zram-generator.conf` | `zstd`, `zram-size = ram`, `swap-priority = 100` | `zramSwap = { enable = true; algorithm = "zstd"; memoryPercent = 100; priority = 100; }` (`zram.nix`) |
| `udev/30-zram.rules` | when zram0 is up: `vm.swappiness=150`, zswap off | `vm.swappiness = 150` plus `boot.kernelParams = [ "zswap.enabled=0" ]` |
| installer `kernelParams` | `quiet nowatchdog` | `boot.kernelParams = [ "quiet" "nowatchdog" ]` |
| `modprobe.d/blacklist.conf` | `iTCO_wdt`, `sp5100_tco`, `wdat_wdt` | `boot.blacklistedKernelModules` (`sp5100_tco` matters on Ryzen) |
| `modules-load.d/ntsync.conf` | `ntsync` | `boot.kernelModules = [ "ntsync" ]` |
| `udev/60-ioschedulers.rules` | HDD → `bfq`, SATA SSD/mmc → `mq-deadline`, NVMe → `kyber` | `services.udev.extraRules`, copied as is |
| `udev/50-sata.rules` | SATA ALPM `max_performance` | `services.udev.extraRules` |
| `udev/69-hdparm.rules` | rotational ATA disks: `hdparm -B 254 -S 0` | `services.udev.extraRules` with `${pkgs.hdparm}`. Does nothing if there is no HDD. |
| `udev/40-hpet-permissions.rules`, `99-cpu-dma-latency.rules` | `rtc0` and `hpet` group `audio`; `cpu_dma_latency` 0660 group `audio` | `services.udev.extraRules` |
| `limits.d/20-audio.conf` | `@audio rtprio 99`, `nice -11` | `security.pam.loginLimits` |
| `udev/20-audio-pm.rules` | turns off `snd_hda_intel` power saving on AC power | Desktop equivalent: `options snd_hda_intel power_save=0` in `boot.extraModprobeConfig` |
| `tmpfiles.d/thp.conf`, `thp-shrinker.conf` | THP `defrag=defer+madvise`, `khugepaged/max_ptes_none=409` | `systemd.tmpfiles.rules` (`w!` lines) |
| `tmpfiles.d/coredump.conf` | coredumps deleted after 3 days | `systemd.tmpfiles.rules` |
| `modprobe.d/nvidia.conf` | `NVreg_InitializeSystemMemoryAllocations=0` | `boot.extraModprobeConfig` (`hardware/nvidia.nix`) |
| `udev/71-nvidia.rules` | runtime power management `auto` when the driver binds, `on` when it unbinds | `services.udev.extraRules` (`hardware/nvidia.nix`) |
| `journald.conf.d/00-journal-size.conf` | `SystemMaxUse=50M` | `services.journald.extraConfig` |
| `system.conf.d/00-timeout.conf`, `user.conf.d/00-timeout.conf` | start 15 s, stop 10 s | systemd manager settings, system and user (exact option name checked against 26.05 when implementing) |
| `system.conf.d/10-limits.conf`, `user.conf.d/10-limits.conf` | `DefaultLimitNOFILE=2048:2097152` (system), `1024:1048576` (user) | same |
| `user@.service.d/delegate.conf` | `Delegate=cpu cpuset io memory pids` | `systemd.services."user@".serviceConfig.Delegate` |
| `system.slice.d/` and `user/slice.d/10-oomd-per-slice-defaults.conf`, `session.slice.d/10-ignore-session-slice.conf` | `ManagedOOMSwap=kill`, `ManagedOOMMemoryPressure=kill`, limit 80%; session slice `ManagedOOMPreference=omit` | `systemd.oomd.{enableSystemSlice,enableUserSlices} = true` plus `ManagedOOMSwap=kill` and the session-slice override, so the result matches upstream exactly |
| `pci-latency.service` | `setpci` latency timers: 20 for everything, 0 for the host bridge, 80 for audio | `systemd.services.pci-latency` (oneshot, `${pkgs.pciutils}`) |
| `timesyncd.conf.d/10-timesyncd.conf` | NTP `time.cloudflare.com`, fallback Google and Arch pool | `networking.timeServers` |
| `NetworkManager/conf.d/dns.conf` | `dns=systemd-resolved` | `networking.networkmanager.dns = "systemd-resolved"` + `services.resolved.enable` (`core/networking.nix`) |
| ananicy-cpp | CachyOS rules | `services.ananicy = { enable = true; package = pkgs.ananicy-cpp; rulesProvider = pkgs.ananicy-rules-cachyos; }` |
| scx | scx with lavd | `services.scx = { enable = true; scheduler = "scx_lavd"; }` |

**Skipped on purpose:**

| CachyOS item | Why it is skipped |
|---|---|
| `amdgpu.conf` (SI/CIK support) | Navi 21 is not Southern Islands or Sea Islands. |
| `iw-set-regdomain` | Wi-Fi only |
| touchpad, GNOME login schema, debuginfod URLs | not relevant here |
| `xswap-generator` | CachyOS-specific mechanism; NixOS `zramSwap` replaces it |
| `bin/` helper scripts (`game-performance`, `dlss-swapper`, …) | can be packaged later if wanted |

---

## 5. Implementation Phases

### Phase 1: Flake skeleton, installable base
1. `flake.nix` and `lib/default.nix`. `mkHost` does the following:
   - imports `modules/nixos`, `hosts/<name>`, disko, and Home Manager (`useGlobalPkgs`, `useUserPackages`, `backupFileExtension = "hm-bak"`)
   - applies the overlays: `nix-cachyos-kernel.overlays.pinned`, plus `unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; }`
   - passes `inputs` and `vars` through `specialArgs`
2. `hosts/YUV-PC/disko.nix`:
   - GPT with a 1 GiB ESP (`/boot`, vfat, `umask=0077`)
   - btrfs subvolumes `@` `/`, `@home`, `@nix`, `@log` with `compress=zstd:1,noatime`
   - no swap partition (zram is used instead)
   - the disk is referenced by `/dev/disk/by-id`
3. Boot: systemd-boot with `configurationLimit = 10` and `efi.canTouchEfiVariables = true`. Stage 1 runs on systemd, which is the 26.05 default.
4. Validate: `nix flake check` and `nix build .#nixosConfigurations.YUV-PC.config.system.build.toplevel`. These need Nix: the live USB, NixOS-WSL, or any Linux machine with Nix.

### Phase 2: Core
1. `core/nix.nix`: flakes, caches, `trusted-users = [ "@wheel" ]`, weekly garbage collection, `auto-optimise-store`.
2. `core/users.nix`:
   - `mutableUsers = false`
   - `root.hashedPassword = "!"`
   - `fantomtchi7` in `wheel video audio input libvirtd kvm networkmanager`, with `hashedPasswordFile = ../../secrets/fantomtchi7.hash`
   - sudo asks for a password
3. `core/networking.nix`: `networking.hostName = "YUV-PC"`, NetworkManager with systemd-resolved, firewall on. OpenSSH with key-only login is **required**: it is the only way into the host while the GPU is passed through.
4. `core/locale.nix`: timezone and locale from `vars.nix`.
5. Validate: `nixos-rebuild build-vm`. Login works and root is locked.

### Phase 3: Kernel and CachyOS stack
1. `kernel/cachyos.nix`: `boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3`. This is the Clang ThinLTO build for x86-64-v3, matching CachyOS's own default build style. It is in the binary cache. The variant is an option.
2. `performance/scx.nix`, `performance/ananicy.nix`, `performance/zram.nix` and `performance/cachyos-settings.nix`, implemented exactly as in section 4.
3. Validate:
   - `uname -r` shows the cachyos lto kernel
   - `cat /sys/kernel/sched_ext/root/ops` shows lavd
   - `systemctl is-active ananicy-cpp`
   - `zramctl` shows zstd at RAM size
   - `sysctl vm.swappiness` returns 150
   - `cat /sys/block/nvme0n1/queue/scheduler` shows `[kyber]`
   - `cat /sys/module/zswap/parameters/enabled` returns N

### Phase 4: Hardware
1. nixos-hardware modules come in through `mkHost` (listed in section 1). `gigabyte-b550` fixes the board waking up right after suspend. `common-cpu-amd-pstate` sets `amd_pstate=active`.
2. `hardware/amdgpu.nix`:
   - `hardware.graphics = { enable = true; enable32Bit = true; }`
   - `hardware.amdgpu.initrd.enable = true`
   - `hardware.amdgpu.overdrive.enable = true`
   - `services.lact.enable = true` for clocks and fan curves
3. `hardware/nvidia.nix` (GTX 1050 Ti, Pascal):
   - `services.xserver.videoDrivers = [ "amdgpu" "nvidia" ]`
   - `hardware.nvidia = { open = false; modesetting.enable = true; nvidiaSettings = false; package = config.boot.kernelPackages.nvidiaPackages.legacy_580; }`. The current production driver (595) dropped Pascal; `legacy_580` (580.178.04 in 26.05) is the last branch that supports it.
   - CachyOS's nvidia modprobe option and udev rule from section 4
   - no PRIME
   - NVENC through `ffmpeg-full` and OBS. Check with `nvidia-smi` and `ffmpeg -encoders | grep nvenc`.
4. `hardware/gpu-priority.nix`:
   - A udev rule creates `/dev/dri/amd-primary` from the 6900 XT's PCI path, because Aquamarine splits `AQ_DRM_DEVICES` on `:`.
   - `AQ_DRM_DEVICES=/dev/dri/amd-primary` goes into the UWSM env file (`~/.config/uwsm/env-hyprland` via Home Manager), so it is set before Hyprland starts.

### Phase 5: Desktop: Hyprland (Lua), Quickshell, greetd
1. `desktop/hyprland.nix`:
   - `programs.hyprland = { enable = true; withUWSM = true; xwayland.enable = true; }` (26.05 → 0.55.4)
   - portals: hyprland and gtk
   - polkit agent, hyprlock PAM
   - The NixOS module installs the Hyprland Lua API stub under `/run/current-system/sw/share/hypr`. That gives `lua-language-server` autocompletion for `hl.*`.
2. `desktop/greetd.nix`:
   ```nix
   services.greetd = {
     enable = true;
     settings = {
       initial_session = { user = "fantomtchi7"; command = "uwsm start hyprland-uwsm.desktop"; };
       default_session = { command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'"; };
     };
   };
   ```
   Autologin happens once per boot. After a logout, or after the VFIO hook restarts greetd, tuigreet asks for a password.
3. `home/hyprland/default.nix`, Lua config:
   ```nix
   wayland.windowManager.hyprland = {
     enable = true;
     package = null; portalPackage = null;   # from the NixOS module
     systemd.enable = false;                 # UWSM handles the session
     configType = "lua";                     # writes ~/.config/hypr/hyprland.lua
     settings = { /* only Nix-derived values: monitors, GPU paths, colours */ };
     extraConfig = ''
       require("binds")
       require("rules")
       require("looks")
     '';
   };
   xdg.configFile."hypr/lua".source = ./lua;   # hand-written *.lua modules
   ```
   Most of the config lives in real `.lua` files, so it can be edited and linted as Lua. Nix only produces the small `hyprland.lua` entry point, plus values that have to be computed. The `package.path` for `require` is set up in the generated header; the exact mechanism is checked against Hyprland 0.55's Lua loader when implementing.
4. `home/quickshell/`:
   - `home.packages = [ pkgs.quickshell ]` (nixpkgs 0.3.0)
   - `xdg.configFile."quickshell".source = ./config`
   - `systemd.user.services.quickshell` bound to `graphical-session.target`
   - Starts as a minimal bar: workspaces, clock, tray, volume.
5. Validate:
   - after a reboot the system logs straight into Hyprland on the AMD outputs
   - `hyprctl systeminfo` shows the AMD GPU
   - `hyprctl reload` picks up the Lua config
   - Quickshell is visible

### Phase 6: Audio and gaming
1. `audio/pipewire.nix` contains only:
   ```nix
   security.rtkit.enable = true;
   services.pulseaudio.enable = false;
   services.pipewire = {
     enable = true;
     alsa.enable = true;
     alsa.support32Bit = true;
     pulse.enable = true;
     jack.enable = true;
   };
   ```
   This is a single file with no extra config. The folder layout leaves room to grow later.
2. `gaming/steam.nix`:
   - `programs.steam = { enable = true; gamescopeSession.enable = true; extraCompatPackages = [ pkgs.proton-ge-bin ]; }`
   - `programs.gamescope = { enable = true; capSysNice = true; }`
   - `hardware.steam-hardware.enable`
3. `gaming/tools.nix`:
   - `mangohud`
   - `protonplus` for Proton-CachyOS builds at runtime
   - gamemode stays **off**, because ananicy-cpp and scx already do that job, as on CachyOS
4. Validate: Steam launches through Proton and `/dev/ntsync` is present.

### Phase 7: Virtualisation: single-GPU passthrough and Windows 11 guest
1. `virtualisation/libvirt.nix`:
   - `virtualisation.libvirtd = { enable = true; qemu = { package = pkgs.qemu_kvm; runAsRoot = true; swtpm.enable = true; }; }`
   - `programs.virt-manager.enable = true`
   - SPICE USB redirection
2. Kernel: `kvm-amd`, `vfio`, `vfio_pci`, `vfio_iommu_type1`. **No `iommu=pt`.** VFIO does not need it, and leaving it out keeps the IOMMU in translated mode, which EAC requires. IOMMU is on by default on AMD; check that SVM and IOMMU are on in the BIOS.
3. `hosts/YUV-PC/gpu.nix` lists every 6900 XT function: VGA, HDMI audio, and the USB-C xHCI and UCSI controllers on reference cards. `pkgs/iommu-groups` checks their IOMMU groups.
4. `virtualisation/vfio-single-gpu.nix` generates `virtualisation.libvirtd.hooks.qemu` for `my.vfio.vms = [ "win11" ]`:
   - **prepare**:
     - stop greetd
     - wait for the GPU to be released
     - unbind the vtconsoles and the framebuffer
     - reserve hugepages
     - restrict host slices to the host CPUs
     - `virsh nodedev-detach` each 6900 XT function
     - `modprobe vfio-pci`
   - **release**: undo every step in reverse order, then start greetd.
   - Every step runs under `set -euo pipefail`, an error trap tries to restore the host display, and output is logged with `logger -t vfio-hook`.
5. `virtualisation/win11-guest.nix`:
   - **TPM 2.0 and Secure Boot**: swtpm, plus the Secure Boot OVMF build with Microsoft keys pre-enrolled.
   - **virtio-win**: `pkgs.virtio-win` linked to `/var/lib/libvirt/isos/virtio-win.iso` with `systemd.tmpfiles`.
   - **Hugepages, allocated dynamically**: 2 MiB pages, `my.vfio.vmMemoryGiB = 16`, reserved in prepare and freed in release. Nothing is reserved at boot.
   - **CPU pinning**: 6 cores / 12 threads go to the guest. Cores 0 and 4 with their SMT siblings stay on the host. Done at runtime with `systemctl set-property --runtime … AllowedCPUs=`, with no `isolcpus`.
   - **Reference `win11.xml`**: `host-passthrough` CPU, Hyper-V enlightenments, `<memoryBacking><hugepages/>`, virtio disk and network, the passed-through 6900 XT and its functions.
   - **Anti-cheat in the guest**: the guest looks like a normal Windows 11 machine (TPM, Secure Boot, real GPU). Games whose anti-cheat allows VMs will run. Many EAC and BattlEye titles do, depending on the developer's settings; some anti-cheats, such as Vanguard and FACEIT, block VMs outright. This plan does **not** include hiding the VM from anti-cheat (masking the hypervisor, spoofing SMBIOS): that is anti-cheat circumvention and can get accounts banned.
6. `virtualisation/binfmt.nix`: `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`.
7. Validate:
   - start `win11` over SSH
   - the 6900 XT works in the guest
   - Windows reports TPM 2.0 and Secure Boot
   - `grep Huge /proc/meminfo` shows the pages in use
   - after shutdown, tuigreet comes back with all CPUs and RAM returned

### Phase 8: Secure Boot, TPM and EAC-friendly hardening (post-install)
1. `security/tpm.nix`: `security.tpm2 = { enable = true; pkcs11.enable = true; tctiEnvironment.enable = true; }`. Turn on AMD fTPM in the BIOS.
2. `security/secureboot.nix`:
   - `boot.lanzaboote = { enable = true; pkiBundle = "/var/lib/sbctl"; }` and `systemd-boot.enable = lib.mkForce false`
   - Lanzaboote keeps systemd-boot as the boot manager.
   - Steps:
     1. `sbctl create-keys`
     2. rebuild
     3. `sbctl verify`
     4. BIOS: switch Secure Boot to Setup Mode
     5. `sbctl enroll-keys --microsoft`
     6. turn Secure Boot on
   - **Keep `--microsoft`.** The 6900 XT's GOP option ROM is signed by the Microsoft UEFI CA; without that key there is no display before the OS loads.
   - `/var/lib/sbctl` holds private keys. Keep it out of git and back it up.
3. `security/hardening.nix` covers the EAC v2 items that are cheap and don't break anything:
   - `security.protectKernelImage = true` → `kexec_load_disabled=1`. This also turns off hibernation, which doesn't work with zram-only swap anyway.
   - BPF LSM: NixOS 26.05 already passes `lsm=landlock,yama,bpf` through `security.lsm`. Check that the CachyOS kernel has `CONFIG_BPF_LSM=y`.
   - IOMMU stays in translated mode (Phase 7).
4. Measured boot: check `systemd-analyze pcrs` / `tpm2_pcrread sha256:11,12` with lanzaboote. If PCR 11 is empty, write that down and accept it for now. The systemd UKI fallback is not worth the extra complexity at this stage.
5. Optional `pkgs/eac-status`: a small read-only script that prints each EAC v2 item as pass or fail, so how close the system gets is something you can measure.

### Phase 9: ARM scaffolding (structure only)
1. `kernel/custom.nix`: `my.kernel.custom = { src; version; configfile ? null; structuredExtraConfig ? {}; patches ? []; }`. It builds with `linuxManualConfig` when given a full `configfile` (vendor BSP kernels), otherwise with `buildLinux`.
2. `hosts/arm-board/`: `nixpkgs.hostPlatform = "aarch64-linux"`. It can cross-compile with `nixpkgs.buildPlatform = "x86_64-linux"` (fast) or build natively through binfmt (simple). The nixos-hardware module is picked once the device is known.
3. x86-only modules (cachyos, nvidia, vfio, steam, lanzaboote) are gated with `lib.mkIf pkgs.stdenv.hostPlatform.isx86_64` or an assertion.
4. Validate: `nix build .#nixosConfigurations.arm-board.config.system.build.toplevel`.

### Phase 10: Secrets (future)
- Today the only secret-like file is `secrets/fantomtchi7.hash`, a plaintext yescrypt hash.
- Later: sops-nix with an age key derived from the SSH host key, `neededForUsers = true`, and `hashedPasswordFile = config.sops.secrets."fantomtchi7-password".path`. No module needs to change.

---

## 6. EAC Linux v2: What This Config Meets

| Requirement | Status | Note |
|---|---|---|
| Secure Boot | ✅ Phase 8 | lanzaboote + systemd-boot |
| TPM 2.0 | ✅ Phase 8 | AMD fTPM |
| IOMMU in translated mode | ✅ Phase 7 | `iommu=pt` deliberately left out |
| kexec disabled | ✅ Phase 8 | `protectKernelImage` |
| BPF LSM | ✅ NixOS default | needs `CONFIG_BPF_LSM` (check) |
| Measured boot (PCR 11/12) | ⚠️ check | depends on the lanzaboote stub |
| Signed kernel | ⚠️ partial | signed with **your own** key, not a "well-known" distribution key |
| Signed modules enforced | ❌ | would reject the unsigned NVIDIA 580 module |
| Lockdown (integrity) | ❌ | same reason. Could be revisited if NVIDIA is dropped or module signing is added later. |

**Expected result:** EAC v2 titles still refuse to run natively, because of the well-known key, lockdown and module signing. The Windows 11 VM is the route for anti-cheat games whose anti-cheat allows VMs.

---

## 7. Installation (from the NixOS 26.05 live USB)

```bash
nix-shell -p git
git clone <repo-url> /tmp/nixos-config && cd /tmp/nixos-config
# set disk id in hosts/YUV-PC/disko.nix  (ls -l /dev/disk/by-id)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode destroy,format,mount hosts/YUV-PC/disko.nix
sudo nixos-generate-config --no-filesystems --root /mnt --show-hardware-config > hosts/YUV-PC/hardware.nix
mkpasswd -m yescrypt > secrets/fantomtchi7.hash
git add -A
sudo nixos-install --flake .#YUV-PC --no-root-passwd \
  --option extra-substituters "https://cache.lantian.pub/lantian" \
  --option extra-trusted-public-keys "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
sudo cp -r . /mnt/home/fantomtchi7/nixos-config
reboot
```
After the first boot, do Phase 8 (Secure Boot enrollment).

---

## 8. Dependencies Between Phases

```
1 ─► 2 ─► 3 ─► 4 ─► 5 ─► 6        usable gaming desktop
               └──► 7 ◄─┘          VFIO needs GPU IDs + greetd
2 ─► 8                             Secure Boot / hardening (post-install)
3 ─► 9                             custom kernel module for ARM
2 ─► 10                            secrets convention
```

---

## 9. Risks

| Level | Risk | Mitigation |
|---|---|---|
| HIGH | Enrolling Secure Boot keys without the Microsoft CA leaves the GPU option ROM blocked, so there is no display before the OS loads. | Always use `--microsoft`. Keep the BIOS reset procedure noted. |
| HIGH | A VFIO hook fails and leaves the host without a display. | SSH, an error trap that restores the display, journal logging, first tests run from SSH. |
| MEDIUM | NixOS 26.05 reaches end of life on 2026-12-31. | Move to 26.11 after it releases (two URL changes plus `nix flake update`). |
| MEDIUM | Hyprland's Lua API is new (0.55) and changes between releases. | Keep Hyprland on stable. Keep the Lua modules small. Check the changelog before moving Hyprland to unstable, together with Mesa. |
| MEDIUM | nix-cachyos-kernel temporarily breaks against its pinned nixpkgs. | Use the `release` branch, update `flake.lock` deliberately, keep `linuxPackages_latest` as a fallback option. |
| LOW | The lanzaboote stub doesn't measure into PCR 11. | Accept and record it (Phase 8). |
| LOW | Hyprland picks the NVIDIA card. | `AQ_DRM_DEVICES` symlink (Phase 4). |
| LOW | Root is locked, so the emergency shell is unavailable. | Live USB + `nixos-enter`; 10 previous generations in the boot menu. |
| LOW | Plaintext password hash in the repo. | yescrypt hash, private repo until Phase 10. |

---

## 10. Estimated Effort

| Block | Phases | Estimate |
|---|---|---|
| Skeleton + core | 1–2 | 3–5 h |
| Kernel/CachyOS + hardware | 3–4 | 3–5 h |
| Hyprland Lua + Quickshell + greetd | 5 | 4–8 h |
| Audio + gaming | 6 | 1–2 h |
| VFIO + Windows 11 guest | 7 | 5–10 h |
| Secure Boot + hardening | 8 | 2–4 h |
| ARM scaffold | 9 | 2–3 h |
| **Total** | | **≈ 20–37 h** |

---

## 11. Decisions

| Topic | Decision |
|---|---|
| User / host | `fantomtchi7` / `YUV-PC` |
| Channel | `nixos-26.05`, with `pkgs.unstable` used only on purpose |
| Filesystem | btrfs with subvolumes |
| Networking | NetworkManager + systemd-resolved |
| scx | `scx_lavd` |
| Kernel | `linuxPackages-cachyos-latest-lto-x86_64-v3` (nix-cachyos-kernel) |
| EAC approach | one boot entry, no draft kernel, cheap hardening only |
| Hyprland | 0.55.4 from 26.05, Lua config through HM `configType = "lua"` + hand-written modules |
| Quickshell | nixpkgs |
| PipeWire | ALSA/PulseAudio/JACK only |
| Emulation | KVM + single-GPU passthrough, Windows 11 guest extras, aarch64 binfmt (no console emulators) |
| Proton-CachyOS | protonplus at runtime |

**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes / no / modify: …)

---

### Sources
- [CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings) · [cachyos-calamares bootloader.conf](https://github.com/CachyOS/cachyos-calamares)
- [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel)
- [Hyprland: Lua-ification of configs](https://hypr.land/news/26_lua/) · [Phoronix: Hyprland 0.55](https://www.phoronix.com/news/Hyprland-0.55-Wayland-Comp)
- [NixOS 26.05 release](https://nixos.org/blog/announcements/2026/nixos-2605/)
- [EAC Linux v2 requirements (coverage)](https://hwbusters.com/news/fortnite-on-linux-is-coming-and-easy-anti-cheat-v2-wants-secure-boot-a-tpm-and-not-your-steam-deck/) · [Bazzite check-anticheat PR](https://github.com/ublue-os/bazzite/pull/6065)
- [nixos-hardware flake](https://github.com/NixOS/nixos-hardware/blob/master/flake.nix)
