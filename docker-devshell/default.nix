{pkgs, ...}: {
  packages.docker-devshell = pkgs.writeShellApplication {
    name = "docker-devshell";
    runtimeEnv.DOCKERFILE = ./Dockerfile;
    text = builtins.readFile ./docker-devshell.sh;
  };
}
