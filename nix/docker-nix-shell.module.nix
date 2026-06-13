{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) types;

  cfg = config.docker-sandbox;
  mountFormat = mode: path: ''-v "${path}":"${path}":${mode} '';
  roMounts = lib.concatMapStrings (mountFormat "ro") cfg.mounts.readOnly;
  rwMounts = lib.concatMapStrings (mountFormat "rw") cfg.mounts.readWrite;
  docker-run-options = [
    ''-w "$PWD"''
    roMounts
    rwMounts
  ];
  enableDirenv = cfg.direnv.enable;
  docker-container-args =
    if enableDirenv
    then ''sh -c "sleep 1 && direnv allow && direnv exec . \"''${@:-bash}\" " ''
    else ''sh -c "sleep 1 && nix develop --quiet . --command \"''${@:-bash}\" "'';
  extraDockerfile = lib.optionals enableDirenv [
    "RUN nix profile add nixpkgs#direnv nixpkgs#nix-direnv"
  ];
in {
  options.docker-sandbox = {
    enable = lib.mkEnableOption "docker-sandbox";
    direnv.enable = lib.mkEnableOption "direnv" // {default = true;};
    mounts = {
      readOnly = lib.mkOption {
        type = types.listOf types.str;
        default = [];
      };
      readWrite = lib.mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };
  };
  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.bashInteractive # for nicer shell in the sandbox
      (import ./docker-nix-shell.nix {
        inherit pkgs extraDockerfile docker-run-options docker-container-args;
      })
    ];
  };
}
