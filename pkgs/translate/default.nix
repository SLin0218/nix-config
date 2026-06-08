{ pkgs }:

let
  audioplayer = pkgs.python3Packages.buildPythonPackage rec {
    pname = "audioplayer";
    version = "0.6";
    format = "setuptools";
    src = pkgs.python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "1ribrgw0yvpz8g3m45xbi0sn07ldlmlpxz43hipm8rw0gb6qvccl";
    };
    doCheck = false;
    propagatedBuildInputs = with pkgs.python3Packages;
      pkgs.lib.optionals pkgs.stdenv.isDarwin [
        pyobjc-core
        pyobjc-framework-Cocoa
      ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        pygobject3
      ];
    nativeBuildInputs = propagatedBuildInputs;
  };
in
pkgs.python3Packages.buildPythonApplication {
  pname = "t";
  version = "1.0.0";

  src = ./.;

  pyproject = true;

  nativeBuildInputs = [
    pkgs.python3Packages.setuptools
  ];

  propagatedBuildInputs = with pkgs.python3Packages; [
    requests
    cryptography
    rich
    audioplayer
  ];

}
