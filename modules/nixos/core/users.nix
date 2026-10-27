{
  config,
  lib,
  env,
  ...
}:
let
  cfg = config.my.core.users;

  sshKeys = lib.filter (key: key != "") (map lib.trim (lib.splitString ";" env.SSH_KEY));
in
{
  options.my.core.users.enable = lib.mkEnableOption "immutable users with a locked root account" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    users.mutableUsers = false;

    users.users.${env.USERNAME} = {
      isNormalUser = true;
      hashedPassword = env.PASSWORD_HASH;
      extraGroups = [
        "wheel"
        "video"
        "audio"
        "input"
      ];
      openssh.authorizedKeys.keys = sshKeys;
    };

    security.sudo.wheelNeedsPassword = true;
  };
}
