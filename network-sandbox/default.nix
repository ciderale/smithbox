{pkgs, ...}: {
  packages.smithbox = pkgs.writeShellApplication {
    name = "smithbox";
    runtimeEnv.DOCKER_BUILD_CONTEXT = ./.;
    text = builtins.readFile ./smithbox.sh;
  };
}
