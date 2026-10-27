# nixos-config

Modular NixOS flake for **YUV-PC** (Ryzen 7 5700X, B550 Aorus Elite V2, RX 6900 XT + GTX 1050 Ti).
Base channel is `nixos-26.05`; `pkgs.unstable` is available for packages picked on purpose.
See [PLAN.md](PLAN.md) for the full roadmap.

## Layout

| Path | Purpose |
|---|---|
| `flake.nix` | inputs and `nixosConfigurations` |
| `lib/` | `mkHost` helper and shared variables (`vars.nix`) |
| `hosts/<name>/` | per-host hardware, disks and `my.*` toggles |
| `modules/nixos/` | system modules, each behind a `my.*` option |
| `modules/home/` | Home Manager modules |
| `users/<name>/home.nix` | per-user Home Manager entry point |
| `overlays/` | `pkgs.unstable` and local package overlays |
| `secrets/` | plaintext for now, see `secrets/README.md` |

## Install from the NixOS live USB

```bash
nix-shell -p git
git clone <repo-url> /tmp/nixos-config && cd /tmp/nixos-config

# 1. Set the target disk in hosts/YUV-PC/disko.nix (ls -l /dev/disk/by-id)
# 2. Set timeZone, locale, keyboardLayout and sshKeys in lib/vars.nix

# 3. Partition, format and mount
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode destroy,format,mount --flake .#YUV-PC

# 4. Hardware config (filesystems are owned by disko)
sudo nixos-generate-config --no-filesystems --root /mnt --show-hardware-config > hosts/YUV-PC/hardware.nix

# 5. User password hash (root stays locked)
mkpasswd -m yescrypt > secrets/fantomtchi7.hash

# 6. Flakes only see tracked files
git add -A

# 7. Install without a root password
sudo nixos-install --flake .#YUV-PC --no-root-passwd \
  --option extra-substituters "https://cache.lantian.pub/lantian" \
  --option extra-trusted-public-keys "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="

sudo cp -r . /mnt/home/fantomtchi7/nixos-config
reboot
```

## Day to day

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#YUV-PC
nix flake update   # deliberate input bumps
nix fmt            # format with nixfmt
```
