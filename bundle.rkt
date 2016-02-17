#lang racket

(provide get-module-deps)

(require syntax/moddep
         json)

(define verbose-mode (make-parameter #f))
(define src-dir (make-parameter (current-directory)))
(define output-dir (make-parameter (build-path (current-directory) "build/")))
(define js-prefix (make-parameter "/pycketjs/"))
(define collects-dir (make-parameter (build-path (current-directory) "racket/collects")))
(define ignore-collects (make-parameter #f))

(define ++ string-append)

(define (get-module-deps mod-path graph)
  (define (build-graph mod-path)
    (define path (resolve-module-path mod-path #f))
    (define code (get-module-code path))
    (define imports (module-compiled-imports code))
    (hash-set! graph path '())
    (for ([r imports])
      (match-define (cons i mods) r)
      (for ([mod mods])
        (match (resolve-module-path-index mod path)
          [#f (void)]
          [`(submod ,path ,mod) (void)]
          [(? symbol? b) (void)]
          [`,resolved-path (define new-mod (simplify-path resolved-path))
                           (hash-update! graph path (λ (v) (cons new-mod v)))
                           (unless (hash-ref graph new-mod #f)
                             (build-graph new-mod))]))))
  (build-graph mod-path)
  graph)

(define (read-config fpath)
  (with-input-from-file fpath
    (λ ()
      (let loop ([result (hash)])
        (match (read)
          [`(,conf . ,path) (loop (hash-set result conf path))]
          [`(files ,files ...) (loop (hash-set result 'files files))]
          [eof result])))))

;; TODO: compile in topological order?
(define (build-mod-graph files)
  (define graph (make-hash))
  (for ([f files])
    (get-module-deps f graph))
  graph)

(define (compile-json-file f)
  (displayln (format "Compiling ~a" f))
  ;; TODO: this is lazy
  (system (format "racket --collects ~a -l pycket/expand -- ~a"
                  (collects-dir)
                  f)))

;; rename file name in src to the one in build output directory
;; FIXME: naive replacing
(define (file-name-in-build fname)
  (string-replace fname (path->string (src-dir)) (path->string (output-dir))))

;; rebase-moduel-ast : String -> String
;; Takes the json ast source and changes all paths expected in
;; isolated js filesystem
(define (rebase-module-ast str)
  ;; FIXME: this is naive
  (string-replace str
                  (path->string (src-dir))
                  (js-prefix)))

;; copy-module : Path -> Void
;; Copies the module source and json ast to build output directory
(define (copy-module f)
  (define fs (path->string f))
  (call-with-input-file (++ fs ".json")
    (λ (in)
      (define new-path (file-name-in-build fs)) ;; to be copied there

      (make-parent-directory* new-path)
      (copy-file fs new-path #t)
      
      (with-output-to-file (++ new-path ".json") #:exists 'truncate
        (λ ()
          (write-string (rebase-module-ast (port->string in))))))))

(define (collects-file? f)
  (string-prefix? (path->string f) (path->string (collects-dir))))

(define (make-bundle config)
  (define graph (build-mod-graph (hash-ref config 'files)))

  ;; compile and put files in build output
  (for ([(f _) (in-hash graph)])
    (unless (and (ignore-collects) (collects-file? f))
      (compile-json-file f)
      (copy-module f)))

  ;; create and index file listing all output files to be loaded
  #;(call-with-output-file (build-path (output-dir) "index.json")
      (λ (out)
        (define (convert-path path)
          (path->string
           (find-relative-path (current-directory) path)))
        (write-json (map convert-path (hash-keys graph))
                    out)))

  (displayln "Finished."))

(define (module-builder)
  (command-line
   #:program "module-bundler.rkt"
   #:once-each
   [("-v" "--verbose") "Compile with verbose messages"
    (verbose-mode #t)]
   [("--ignore-collects") "Don't compile collects sources"
    (ignore-collects #t)]
   #:args (bundle-make)
   bundle-make))

(module+ main
  (define config (read-config (module-builder)))
  (make-bundle config))
