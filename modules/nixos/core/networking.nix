{
  config,
  lib,
  env,
  ...
}:
let
  cfg = config.my.core.networking;
in
{
  options.my.core = {
    networking.enable = lib.mkEnableOption "NetworkManager with systemd-resolved and a firewall" // {
      default = true;
    };
    ssh.enable = lib.mkEnableOption "key-only OpenSSH server";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      networking.networkmanager = {
        enable = true;
        dns = "systemd-resolved";
      };
      services.resolved.enable = true;
      networking.firewall.enable = true;

      users.users.${env.USERNAME}.extraGroups = [ "networkmanager" ];
    })

    (lib.mkIf config.my.core.ssh.enable {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
    })
  ];
}
