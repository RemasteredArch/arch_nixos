# `arch_nixos`

`arch_nixos` (name subject to change) are my [NixOS](https://nixos.org/) configurations.

## Hosts

Currently, only `arch-server`, my home server, is tracked.
My other machines run Windows or Ubuntu,
but NixOS will eventually™ come for them too

## Layout

Future hosts will be added to `hosts/`.
Common code between hosts will be pulled out into another directory.
As of now, all code lives within `hosts/server/`,
because abstracting out common code would add complexity that is not necessary and would slow me down.
When I get around to porting more hosts to use NixOS,
I'll undoubtedly be more comfortable in the language and operating system,
which will make it easier and more effective to split it at that time.
