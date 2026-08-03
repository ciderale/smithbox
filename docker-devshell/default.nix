{pkgs, ...}: {
  packages.docker-devshell = pkgs.writeShellApplication {
    name = "docker-devshell";
    runtimeEnv.DOCKER_BUILD_CONTEXT = ./.;
    text = builtins.readFile ./docker-devshell.sh;
  };
}
