FROM alpine

RUN apk add --no-cache curl
RUN curl -sSfL https://artifacts.nixos.org/nix-installer \
			| sh -s -- install linux --init none --enable-flakes --no-confirm
ENV PATH=/nix/var/nix/profiles/default/bin:$PATH

RUN nix profile add \
        nixpkgs#direnv nixpkgs#nix-direnv nixpkgs#gosu \
    && nix store gc

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "sh" ]
