{
  config,
  lib,
  vars,
  ...
}:
let
  cfg = config.my.core.users;

  passwordHash = ../../../secrets + "/${vars.username}.hash";
in
{
  options.my.core.users.enable = lib.mkEnableOption "immutable users with a locked root account" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    users.mutableUsers = false;

    users.users.root.hashedPassword = "!";

    users.users.${vars.username} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "audio"
        "input"
      ];
      hashedPasswordFile = "${passwordHash}";
      openssh.authorizedKeys.keys = vars.sshKeys;
    };

    security.sudo.wheelNeedsPassword = true;

    assertions = [
      {
        assertion = lib.hasPrefix "$" (lib.fileContents passwordHash);
        message = ''
          secrets/${vars.username}.hash does not contain a password hash.
          Generate one with: mkpasswd -m yescrypt > secrets/${vars.username}.hash
        '';
      }
    ];
  };
}
