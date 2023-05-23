# prime-fun-janet

Prime number sieve, Sacks and Ulam spiral generator in Janet, teaching my kids coding.

We started with a few 'is prime?' functions using iteration and then a more functional version using a filter and one using reduce. Then a 'primes' function to actually generate primes, using the 'is prime?' functions.

Then we made a new implementation of a primes generator, using the sieve of eratosthenes algorithm, but using a table to record primes as we hit them, rather than the usual method of marking 'future' composites in a big array.

Finally there is a function to generate a Sacks spiral and one for an Ulam spiral, and some SVG utility functions to render them as SVG.

A nice little exercise in coding and an introduction to Janet and 'lisp'-like languiages for my kids. And me actually, to some extent.
