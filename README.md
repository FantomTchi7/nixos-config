## Install from the NixOS live USB

```bash
sudo gdisk /dev/nvme0n1
```


```bash
sudo mkfs.vfat -F32 /dev/nvme0n1p1
```

```bash
sudo mkfs.btrfs -f /dev/nvme0n1p2
```

```bash
sudo mount /dev/nvme0n1p2 /mnt
```

```bash
sudo btrfs subvolume create /mnt/@
```

```bash
sudo btrfs subvolume create /mnt/@home
```

```bash
sudo btrfs subvolume create /mnt/@nix
```

```bash
sudo btrfs subvolume create /mnt/@log
```

```bash
sudo umount /mnt
```


```bash
O=compress=zstd:1,noatime,nodiscard
```

```bash
sudo mount -o $O,subvol=@ /dev/nvme0n1p2 /mnt
```

```bash
sudo mkdir -p /mnt/{boot,home,nix,var/log}
```

```bash
sudo mount -o $O,subvol=@home /dev/nvme0n1p2 /mnt/home
```

```bash
sudo mount -o $O,subvol=@nix  /dev/nvme0n1p2 /mnt/nix
```

```bash
sudo mount -o $O,subvol=@log  /dev/nvme0n1p2 /mnt/var/log
```

```bash
sudo mount -o umask=0077 /dev/nvme0n1p1 /mnt/boot
```


```bash
cp .env.example .env
```

```bash
# mkpasswd -m yescrypt
```

```bash
vim .env
```


```bash
sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/YUV-PC/hardware.nix
```


```bash
# "compress=zstd:1" "noatime" "nodiscard"
```

```bash
vim hosts/YUV-PC/hardware.nix
```


```bash
git add .
```


```bash
sudo nixos-install --flake path:.#YUV-PC --no-root-passwd --option extra-substituters "https://cache.lantian.pub/lantian" --option extra-trusted-public-keys "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
```


```bash
sudo cp -r . /mnt/home/fantomtchi7/nixos-config
```

```bash
sudo chown -R 1000:100 /mnt/home/fantomtchi7/nixos-config
```


```bash
reboot
```
