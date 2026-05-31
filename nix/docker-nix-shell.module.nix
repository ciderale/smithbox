{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) types;

  cfg = config.docker-sandbox;
  mountFormat = mode: path: ''-v "${path}":"$(stripProject "${path}")":${mode} '';
  roMounts = lib.concatMapStrings (mountFormat "ro") cfg.mounts.readOnly;
  rwMounts = lib.concatMapStrings (mountFormat "rw") cfg.mounts.readWrite;
  docker-run-options = [
    "-w ${cfg.projectDir}"
    roMounts
    rwMounts
  ];
  enableDirenv = cfg.direnv.enable;
  cmd = ''"''${@:-bash}"'';
  docker-container-args =
    if enableDirenv
    then ''sh -c "direnv allow && direnv exec . \"''${@:-bash}\" " ''
    else ''nix develop . --command ${cmd}'';
in {
  options.docker-sandbox = {
    enable = lib.mkEnableOption "docker-sandbox";
    direnv.enable = lib.mkEnableOption "direnv" // {default = true;};
    user = lib.mkOption {
      type = types.str;
      default = "claude";
    };
    projectDir = lib.mkOption {
      type = types.str;
      default = "/project";
    };
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
      (import ./docker-nix-shell.nix {
        inherit pkgs docker-run-options docker-container-args enableDirenv;
        inherit (cfg) user projectDir;
        gitRoot = config.git.root.shellVariable;
      })
    ];
  };
}
