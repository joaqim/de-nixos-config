# This file, being separate, enables using the same overlays for the NixOS system configuration
# (which affects operations like `nixos-rebuild`) and for the users' configurations (which affects
# operations like `nix-env` and `home-manager`) that also import this file.

deps:  # `deps` is a function that returns dependencies for here, given a `self` and `super` pair.

let
  inherit (builtins) elem match;
  isStableVersion =
    pkgs: isNull (match "pre.*" pkgs.lib.trivial.versionSuffix);
in

[
  # Make the nixos-unstable channel available as pkgs.unstable, for stable
  # versions of pkgs only.
  (self: super:
    if isStableVersion super then
      {
        unstable = assert ! (super ? unstable);
          # Pass the same config so that attributes like allowUnfreePredicate
          # are propagated.
          import <nixos-unstable> { inherit (self) config; };
      }
    else {})

  # Provide my own library of helpers.
  (self: super:
    assert ! (super ? myLib);
    {
      myLib = import ../lib { pkgs = self; };
    })

  # Rust pre-built toolchains from official static.rust-lang.org.
  (self: super: let
    oxalica = import <oxalica-rust-overlay>;  # From channel that I added.
  in
    assert ! (super ? rust-bin);
    {
      inherit (oxalica self super) rust-bin;  # (Exclude its other attributes, for now.)
    })

  # Subversion client with support for storing passwords in GNOME Keyring.
  # TODO: Maybe contribute (something like) this to the official Nixpkgs package.
  (self: super: let
    flag = "--with-gnome-keyring";
  in {
    subversionClient = super.subversionClient.overrideAttrs (previousAttrs:
      assert ! (elem flag previousAttrs.configureFlags);
      {
        nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [self.pkg-config self.makeWrapper];
        buildInputs       = previousAttrs.buildInputs       ++ [self.libsecret];
        configureFlags    = previousAttrs.configureFlags    ++ [flag];
        postFixup =
          assert ! (previousAttrs ? postFixup);
          ''
            for x in $out/bin/*; do
              wrapProgram $x --prefix LD_LIBRARY_PATH : $out/lib
            done
          '';
      });
  })

  # Packages with debugging support.  This causes rebuilding of these.
  (self: super: let
    inherit (super) myLib;
    inherit (deps self super) debuggingSupportConfig;

    selection = {
      inherit (super)
        hello  # Have this to always exercise my Nix library for debugging support.
        # You may add more here:
      ;
    };
  in (myLib.pkgWithDebuggingSupport.byMyConfig debuggingSupportConfig).overlayResult selection)
]
