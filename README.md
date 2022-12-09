# Little Projects

Collection of small, single-file projects and solutions to LeetCode problems.

## C

1. Number of Good Subsets
   * [number\_of\_good\_subsets.c](number_of_good_subsets.c)
   * Solution to a [LeetCode
     problem](https://leetcode.com/problems/the-number-of-good-subsets/)

2. O(1) myPow
   * [o1_mypow.c](o1_mypow.c)
   * Solution to a [LeetCode problem](https://leetcode.com/problems/powx-n/)

## Zig

All tested with `zig 0.10.0`.

1. Bit Combination Iterator
   * `zig test combination_iterator.zig`
   * Iterate through bitsets in increasing order of bitcount, e.g.: \
     `0000`,\
     `0001` `0010` `0100` `1000`,\
     `0011`, `0101`, `0110`, `1001`, `1010`, `1100`,\
     `0111`,`1011`, `1101`, `1110`,\
     `1111`.
2. Booleanomial
   * `zig test booleanomial.zig`
   * Compute boolean polynomials (polynomials over GF(2) which are equivalent to
     boolean expressions)
3. Electron Config Generator
   * `zig build-exe econfig.zig && ./econfig`
   * Type in an atomic number, and the CLI responds with the element name,
     symbol, electron config, and quantum numbers.
4. Task Scheduler
   * `zig test task_scheduler.zig`
   * Based on a [LeetCode
     problem](https://leetcode.com/problems/maximum-profit-in-job-scheduling/)
   * Designed to be foolproof: no overflows and bad stuff for full range of
     input
   * Given a list of tasks with set times and profits, compute the optimal task
     which maximizes profit.
