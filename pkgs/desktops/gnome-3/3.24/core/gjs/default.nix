{ fetchurl, stdenv, pkgconfig, gnome3, gtk3, gobjectIntrospection
, spidermonkey_38, pango, readline, glib, libxml2, dbus }:

let
  patchMozjs = file: ''
    install_name_tool -change "@executable_path/libmozjs-38.dylib" \
      "${spidermonkey_38}/lib/libmozjs-38.dylib" ${file}
  '';
in stdenv.mkDerivation rec {
  inherit (import ./src.nix fetchurl) name src;

  buildInputs = [ libxml2 gobjectIntrospection pkgconfig gtk3 glib pango readline dbus ];

  propagatedBuildInputs = [ spidermonkey_38 ];

  # GJS expects mozjs-38.pc but spidermonkey_38 only provides js.pc
  preConfigure = ''
    sed -i s/mozjs-38/js/ configure
  '';

  NIX_LDFLAGS = stdenv.lib.optionalString stdenv.isDarwin "-lintl";

  # required because tests are executed before patching binaries on OS X
  preBuild = ''
    export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:${spidermonkey_38}/lib
  '';

  postInstall = ''
    sed 's|-lreadline|-L${readline.out}/lib -lreadline|g' -i $out/lib/libgjs.la
  '' + stdenv.lib.optionalString stdenv.isDarwin ''
    ${patchMozjs "$out/bin/gjs"}
    ${patchMozjs "$out/lib/libgjs.0.dylib"}
  '';

  meta = with stdenv.lib; {
    maintainers = gnome3.maintainers;
    platforms = platforms.unix;
  };

}
