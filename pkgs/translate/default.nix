{ pkgs }:

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
    rich
    pycryptodome
    cryptography
    certifi
    cffi
    charset-normalizer
    idna
    markdown-it-py
    mdurl
    pycparser
    pygments
    urllib3
  ];

}
