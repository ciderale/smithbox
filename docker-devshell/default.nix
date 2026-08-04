{pkgs, ...}: {
  packages.docker-devshell = pkgs.writeShellApplication {
    name = "docker-devshell";
    runtimeEnv.DOCKERFILE = ../network-sandbox/Dockerfile.docker-devshell;
    text = builtins.readFile ./docker-devshell.sh;
  };
}
