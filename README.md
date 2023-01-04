# Little Projects

Collection of small, single-file projects and solutions to LeetCode problems.

## C

1. Number of Good Subsets
   * Count subsets of a list that have a product with distinct prime factors
   * [number\_of\_good\_subsets.c](number_of_good_subsets.c)
   * Solution to a [LeetCode
     problem](https://leetcode.com/problems/the-number-of-good-subsets/)

2. O(1) myPow
   * Calculate [float]^[integer]
   * [o1_mypow.c](o1_mypow.c)
   * Solution to a [LeetCode problem](https://leetcode.com/problems/powx-n/)

## Zig

All tested with `zig 0.10.0`.

1. Bit Combination Iterator
   * Iterate through bitsets in increasing order of bitcount, e.g.: \
     `0000`,\
     `0001` `0010` `0100` `1000`,\
     `0011`, `0101`, `0110`, `1001`, `1010`, `1100`,\
     `0111`,`1011`, `1101`, `1110`,\
     `1111`.
   * `zig test combination_iterator.zig`
2. Booleanomial
   * Compute a boolean polynomial (polynomials with 0/1 as inputs and outputs
     which behave equivalently to a given boolean expression)
   * `zig test booleanomial.zig`
3. Electron Config Generator
   * Type in an atomic number, and the CLI responds with the element name,
     symbol, electron config, and quantum numbers.
   * `zig build-exe econfig.zig && ./econfig`
4. Task Scheduler
   * Given a list of tasks with set times and profits, compute the optimal task
     which maximizes profit.
   * Designed to be foolproof: no overflows and bad stuff for full range of
     input
   * `zig test task_scheduler.zig`
   * Based on a [LeetCode
     problem](https://leetcode.com/problems/maximum-profit-in-job-scheduling/)

## LeetCode Hard 100%s

Solutions that beat 100% of other solutions in both memory and runtime at time
of submission.

1. [Number of Atoms (C)](https://leetcode.com/problems/number-of-atoms)
   * [num_atoms.c](num_atoms.c)
   * Count the number of each atom in a general molecular formula, e.g.
     `K4(ON(SO3)2)2` -> `K4N2O14S4`.
2. [Parse Lisp (C)](https://leetcode.com/problems/parse-lisp-expression)
   * Parse an s-expression with `let`, `add`, and `mul`.
   * [parse_lisp.c](parse_lisp.c)
3. [Dice Roll (Java)](https://leetcode.com/problems/dice-roll-simulation)
   * Calculate the number of dice roll sequences of length n given a max number
     of same consecutive rolls for each number.
   * [DiceRoll.java](DiceRoll.java)
