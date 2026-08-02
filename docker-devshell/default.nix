{pkgs, ...}: {
  packages.docker-devshell = pkgs.writeShellApplication {
    name = "docker-devshell";
    text = builtins.readFile ./docker-devshell.sh;
  };
}
