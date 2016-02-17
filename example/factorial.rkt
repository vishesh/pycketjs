#lang racket

(define (factorial n)
  (if (zero? n)
    1
    (* n (factorial (- n 1)))))

(write (factorial 10000))
