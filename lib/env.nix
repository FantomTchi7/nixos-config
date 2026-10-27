{ lib }:
let
  file = ../.env;

  optional = {
    TIMEZONE = "";
    SSH_KEY = "";
  };

  required = [
    "USERNAME"
    "LOCALE"
    "KEYBOARD_LAYOUT"
    "PASSWORD_HASH"
  ];

  lines = lib.filter (line: line != "" && !lib.hasPrefix "#" line && lib.hasInfix "=" line) (
    lib.splitString "\n" (lib.fileContents file)
  );

  entry =
    line:
    let
      parts = lib.splitString "=" line;
    in
    lib.nameValuePair (lib.trim (lib.head parts)) (
      lib.trim (lib.concatStringsSep "=" (lib.tail parts))
    );

  env = builtins.listToAttrs (map entry lines);

  missing = lib.filter (key: (env.${key} or "") == "") required;
in
if !builtins.pathExists file then
  throw ''
    .env is missing. Copy .env.example to .env and fill it in.

    A flake only sees git-tracked files and .env is gitignored, so build with a
    `path:` reference (`path:.#YUV-PC`), never a plain `.#YUV-PC`.
  ''
else if missing != [ ] then
  throw ".env is missing a value for: ${lib.concatStringsSep ", " missing}. See .env.example."
else
  optional // env
