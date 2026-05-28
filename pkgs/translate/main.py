#!/usr/bin/env python

import os
import sys
import platform

from iciba import ICibaTranslate

def main():
    t = ICibaTranslate()
    argv = sys.argv
    w = ""
    if len(argv) == 1:
        if platform.uname().system == "Linux":
            w = os.popen("xclip -selection clipboard -o").read()
        elif platform.uname().system == "Darwin":
            w = os.popen("pbpaste").read()
    elif len(argv) > 2:
        w = " ".join(argv[1:])
    else:
        w = argv[1]

    t.translate_print(w)

if __name__ == "__main__":
    main()
