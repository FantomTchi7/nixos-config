{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.performance.cachyosSettings;
in
{
  options.my.performance.cachyosSettings.enable =
    lib.mkEnableOption "CachyOS sysctl, udev, systemd and kernel defaults";

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      "vm.swappiness" = lib.mkDefault 100;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_bytes" = 268435456;
      "vm.page-cluster" = 0;
      "vm.dirty_background_bytes" = 67108864;
      "vm.dirty_writeback_centisecs" = 1500;
      "kernel.nmi_watchdog" = 0;
      "kernel.unprivileged_userns_clone" = 1;
      "kernel.printk" = "3 3 3 3";
      "kernel.kptr_restrict" = 2;
      "net.core.netdev_max_backlog" = 4096;
      "fs.file-max" = 2097152;
      "kernel.sysrq" = 1;
    };

    boot.kernelParams = [
      "quiet"
      "nowatchdog"
    ];

    boot.blacklistedKernelModules = [
      "iTCO_wdt"
      "sp5100_tco"
      "wdat_wdt"
    ];

    boot.kernelModules = [ "ntsync" ];

    boot.extraModprobeConfig = ''
      options snd_hda_intel power_save=0
    '';

    services.udev.extraRules = ''
      # 60-ioschedulers.rules
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"

      # 50-sata.rules
      ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_supported}=="1", ATTR{link_power_management_policy}=="*", ATTR{link_power_management_policy}="max_performance"

      # 69-hdparm.rules
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ENV{ID_USB_DRIVER}=="", ENV{ID_BUS}=="ata", RUN+="${pkgs.hdparm}/bin/hdparm -B 254 -S 0 /dev/%k"

      # 40-hpet-permissions.rules
      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"

      # 99-cpu-dma-latency.rules
      DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
    '';

    security.pam.loginLimits = [
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }
      {
        domain = "@audio";
        item = "nice";
        type = "-";
        value = "-11";
      }
    ];

    systemd.tmpfiles.rules = [
      "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
      "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
      "e /var/lib/systemd/coredump - - - 3d"
    ];

    services.journald.extraConfig = ''
      SystemMaxUse=50M
    '';

    systemd.services.rtkit-daemon = lib.mkIf config.security.rtkit.enable {
      serviceConfig.LogLevelMax = "info";
    };

    systemd.settings.Manager = {
      DefaultTimeoutStartSec = "15s";
      DefaultTimeoutStopSec = "10s";
      DefaultLimitNOFILE = "2048:2097152";
    };

    systemd.user.extraConfig = ''
      DefaultTimeoutStartSec=15s
      DefaultTimeoutStopSec=10s
      DefaultLimitNOFILE=1024:1048576
    '';

    systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

    systemd.oomd.enable = true;
    systemd.slices.system.sliceConfig = {
      ManagedOOMSwap = "kill";
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "80%";
    };
    systemd.user.units = {
      "slice" = {
        overrideStrategy = "asDropin";
        text = ''
          [Slice]
          ManagedOOMSwap=kill
          ManagedOOMMemoryPressure=kill
          ManagedOOMMemoryPressureLimit=80%
        '';
      };
      "session.slice" = {
        overrideStrategy = "asDropin";
        text = ''
          [Slice]
          ManagedOOMPreference=omit
        '';
      };
    };

    systemd.services.pci-latency = {
      description = "Adjust latency timers for PCI peripherals";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      path = [ pkgs.pciutils ];
      script = ''
        setpci -v -s '*:*' latency_timer=20
        setpci -v -s '0:0' latency_timer=0
        setpci -v -d '*:*:04xx' latency_timer=80
      '';
    };

    services.timesyncd = {
      servers = [ "time.cloudflare.com" ];
      fallbackServers = [
        "time.google.com"
        "0.arch.pool.ntp.org"
        "1.arch.pool.ntp.org"
        "2.arch.pool.ntp.org"
        "3.arch.pool.ntp.org"
      ];
    };
  };
}
