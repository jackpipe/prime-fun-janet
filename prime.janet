#!/usr/bin/env janet

(defn svg-header []
  `<?xml version="1.0" encoding="UTF-8"?>
    <svg height="500" width="500" viewBox="-250 -250 500 500" xmlns="http://www.w3.org/2000/svg">`)


(defn svg-footer []
  `</svg>`)


# FIXME add scale too
(defn svg-sacks-point [x y p]
  (string/format `<circle cx="%f" cy="%f" r="2" stroke="black" stroke-width="0.1" fill="red" num="%d"/>` x y p))


(defn svg-ulam-point [x y p scale]
  (string/format `<rect x="%f" y="%f" width="%d" height="%d" stroke="black" stroke-width="0.1" fill="#aaa" transform="rotate(45, %f, %f)" num="%d"/>`
    (- (* x scale) (/ scale 2))
    (- (* y scale) (/ scale 2))
    (* 1.2 scale)
    (* 1.2 scale)
    (* x scale)
    (* y scale)
    p))


(defn is-prime [n]
  "Check if n is prime by checking if it divides cleanly by any number up to n/2+1"
	(var r (if (> n 1) true false))
	(for i 2 (inc (/ n 2))
		(when (zero? (mod n i))
				(set r false)
				(break)))
	r)


(defn is-prime-filter [n]
  "
  Check if n is prime by checking if it divides cleanly by any number up to n/2+1
  Does it in a more 'functional' way, but it's much much slower
  "
	(not (any?
    (filter
      (fn [x] (zero? (mod n x)))
        (range 2 (math/ceil (inc (/ n 2))))))
	))


(defn is-prime-reduce [n]
  "
  Check if n is prime by checking if it divides cleanly by any number up to n/2+1
  Does it in a more 'functional' way, but it's much much slower
  "
	(not (reduce
      (fn [t x] (if t t (zero? (mod n x))))
      false
      (range 2 (math/ceil (inc (/ n 2)))))))


(defn primes []
  "
  Prime number generator/fiber
  yields primes as an iterator or with (resume) 
  "
  (fiber/new (fn []
    (yield 2)

    (loop [n :range [3]]
      (if (is-prime-filter n)
        (yield n)))
  )))


  (defn primes-sieve []
    "
    Prime numbers generator using sieve of Eratosthenes

    Count upwards, building a 'sieve' of discovered primes, and discarding numbers that are
    composites of primes already in the sieve.
    Each entry in the sieve is a key pointing to a list of primes, where the key is
    the 'next upcoming composite (multiple)' divisible by it's primes, eg { 45 @[3 5] }

    For each number, check if it's one of the composites recorded in the sieve.
    If it is, update the sieve with recalculated 'upcoming composite' entries for each prime
    and delete the current entry.
    If not, it must be a new prime; yield the number, and add an entry for it in the sieve.
    "
    (fiber/new (fn []
      (yield 2) # the only even prime, yield it explicitly.

      (let [sieve (table/new (math/pow 2 12))]
        (loop [n :range [3 nil 2]]  # only odd numbers
          (if-let [current-composite (sieve n)]
            (do 
              (each prime-factor current-composite
                (let [next-composite-key (+ n (* 2 prime-factor))] # add 2*prime-factor, else composite would be even
                  (if-let [next-composite (sieve next-composite-key)]
                    (array/push next-composite prime-factor)
                    (put sieve next-composite-key @[prime-factor]))))
              (put sieve n nil))
            (do
              (yield n)
              (put sieve (* n n) @[n])) # next composite is n^2. Anything less is composite a smaller prime, already in the sieve
            ))))))


(defn square-spiral []
  "
  Yield [x y] co-cordinates of a square spiral, constructed from successive
  opposite corners (2 sides at right-angles), each corner length grows by 1

  Start moving 1 place north          1-1
  from the origin, then 1 east,       |
  to complete the first corner:       o

  Then the next corner,               1-1   Repeat:   3---3
  2 south, 2 west (the opposite       | |             |1-1|
  directions as the first corner      o |             || ||
  and longer by 1):                  2--2             |o ||
                                                      2--2|
                                                     4----4
  "
  (fiber/new (fn []
    (var- position [0 0])
    (var- len 0)

    (while true
      (loop [corner :in [ [[0  1] [ 1 0]]      # N,E
                          [[0 -1] [-1 0]] ]]   # S,W
        (++ len)
        (loop [direction :in corner]
          (loop [:repeat len]
            (yield position)
            (set position [(+(position 0)(direction 0)) (+(position 1)(direction 1))])
            )))))))


(defn ulam []
  "
  Generate Ulam spiral.
  Yield only the prime number representatives on the square spiral as [x y] points.
  "
  (fiber/new (fn []
    (let [prime (primes-sieve)]
      (var- next-prime (resume prime))
      (var- n 0)
      (loop [s :in (square-spiral) :before (++ n)]
        (when (= n next-prime)
          (yield s )
          (set next-prime (resume prime))))))))



(defn sacks []
  "
  Generate Sacks spiral.
  Yield only prime number representatives on the spiral as polar [turn-fraction radius] points.
  Use turns (1.0 = 1 revolution) as the most natural form instead of degrees/radians etc.
  "
  (fiber/new (fn []
    (let [prime (primes-sieve)]
    (var next-prime (resume prime))

      (for turn 1 nil
        (let [square (* turn turn)        # the starting number of this turn of the spiral
              interval (inc (* 2 turn))]  # interval between successive squares,
                                          # ie how many numbers are in this turn of the spiral

          (while (< next-prime (+ square interval))   # get all the primes in this turn
            (let [turn-fraction (/ (- next-prime square) interval)
                  radius (+ turn turn-fraction)]
              (yield [turn-fraction radius]))         # yield their angle and radius
            (set next-prime (resume prime)))
        ))))))


(defn polar-to-xy [scale turn-fraction radius]
    "
    convert polar (fraction-of-revolution radius) to cartesian (x y)
    "
    (let [angle (- (* turn-fraction 2 math/pi) (/ math/pi 2))]  # convert turns to radians, with 0 rad pointing north
      [(* scale radius (math/cos angle)) (* scale radius (math/sin angle))] ))


(defn svg-ulam [count scale]
  (var- n 0)
  (loop [u :in (ulam) :while (< n count) :before (++ n)]
    (print (svg-ulam-point (splice u) n scale)))
  )


(defn svg-sacks [count scale]
  (var- n 0)
  (loop [u :in (sacks) :while (< n count) :before (++ n)]
    (print (svg-sacks-point (splice (polar-to-xy scale (splice u))) n))))



(defn main [& args]
  ```
  usage:
  prime-fun-janet u|s number-of-primes
  ```
  (print (svg-header))
  (let [type (args 1)
        count (scan-number (args 2))]
    (if (= type "u")
      (do
        (svg-ulam count 4))
      (svg-sacks count 2)))
  (print (svg-footer))
)

