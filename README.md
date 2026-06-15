# Sandboxing experiments

## setup based on docker container

General idea:

- open source sandboxing technology widely available on linux
- docker container infrastructure widely avaiable for easy start
- filesystem isolation with docker bind mount is nothing new
- on MacOS/windows, docker container run in a VM for extra isolation

Caveat:

- on linux, docker runs on the host kernel without VM isolation
- on MacOS/windows, one "docker VM" is shared for all sandboxes
- per sandbox vm is doable, but comes with an extra effort

## networkd-sandbox

General idea: allow reading from the world, but hinder data exfiltration.

The different classes of requests with increasing exfiltration potential:

- Http(s) GET (aka "read") are generally allowed
	- deny list to avoid certain domains to be read from
- Http(s) POST/PUT/etc (aka "write") are generally disallowd
	- allow list to allow write to some project specific domains
	- maybe rate limit or restrict size
- General UDP/TCP traffic (aka "uncontrolled") generally denied
	- allow list to allow access to such domains (e.g. DB Server)

Challenges:

- ip/nfttables firewall works at layer 3/4 not application layer 7
	- domain name resolution: for domain name allow/deny list
	- http get/post/etc filtering: distinguish GET from POST
- https: only target domain visible, the content is encrypted
	- MITM is needed to inspect GET from POST in https
	- configure CA in the sandboxed workload

Solutions:

- dnsmasq resolves domain names and feeds ip into nftables variable
	- control what ip addresses are known and reachable
	- primarily allow access to a layer 7 proxy (like squid)
- squid proxy for filtering on application layer filtering
	- may also do dns resolution/filtering
	- dnsmasq may not be needed if no plain tcp to domain names is needed
- squid supports SSL bump to inspect https traffic

## docker socket isolation

Problem: access to the docker socket provides essentially root priviliges

Genral Idea: provide a sandbox only with limited docker api capability.

Solutions:

1. Work with rootless-docker/podman
2. Proxy the docker socket and control the allowed operations

Caveats:

- without a "project-specific user", rootless podman likely not isolates from out other running container of that user
- filtering docker socket operations may be tricky to get right. in particular to avoid information leakage

Ideas using a docker api proxy

- restrict mounts to some controlled locations
- restrict certain operations (like --priviliged and added capabilities)
- filter all elements (container, etc.) not created by the same "proxy session"


# Open Tasks

- [ ] direnv configuration with out-of-tree gc-root
- [ ] nixify things for easy configuration and distribution
- [ ] decide on alpine vs debian base vs nix base image
- [ ] squid proxy SSL Bump for https introspection
- [ ] http(s) allow/deny rule configuration
- [ ] sydbox sandboxing for additional secomp hardening
- [ ] docker socket sandboxing
- [ ] dynamic adjustment of allow/deny lists
- [ ] look into eBPF tools (e.g. cilium, tetragon)
