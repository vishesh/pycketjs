pycketjs
========

This is an attempt to run [Pycket](https://github.com/samth/pycket) on
JavaScript environment. We have partially ported
[pypyjs](https://github.com/pypyjs/pypy) asmjs backend patches to rpython to
latest PyPy release. Our changes can be found
[here](https://bitbucket.org/vishesh/pypy). Currently, non-jit target compiles
successfully.

## Installation

1. Install Racket, Pycket and NodeJS
2. If you do not plan to use `pycket.js` included in this repository follow you
   can skip rest of this section.
3. TODO

## Usage

Place your Racket program inside a directory and create a new file called
`build.rktl`. This file lists all the files you wish to compile and publish.

     
    (collects-dir . "./racket/collects")

    (pkgs-dir . "./racket/pkgs")

    (files "factorial.rkt"
           "heapsort.rkt"
           "racket/collects/syntax/module-reader.rkt"
           "racket/collects/racket/runtime-config.rkt")

Currently, `collects-dir` and `pkgs-dir` are ignored. All the dependencies
of files are automatically compiled, assuming they exist somewhere inside 
current directory.

Once the directory structure is prepared. You can use `pycketjs` script to
compile your program and bundle it in single gigantic JavaScript file.

1. Call `setup` before the very first time you build Pycket (or you did a clean)
    
           $ /path/to/pycketjs setup

2. Call `build` to compile Racket program and produce an output JavaScript
   file called `pycket.js`.

           $ /path/to/pycketjs build

   This command will compile _collects_ sources each time. Call `quickbuild`
   to just rebuild the files listed in build.rktl and their _non-collect_
   dependencies (i.e. everything except collects).

3. Call `clean` to remove everything except your sources. See #1.

### Executing JavaScript files

#### NodeJS

You can execute the generate `pycket.js` in NodeJS environment. All the files
relative to build directory are prefixed with _pycketjs_ component.

    $ node --stack-size=10000 pycket.js pycketjs/<path/to/your/rkt> [args ...]
