{ pkgs, lib, config, inputs, ... }:

{
  claude.code.enable = true;
  languages.dotnet.enable = true;
  languages.rust.enable = true;
  packages = [ pkgs.asciinema pkgs.mdBook ];
}
