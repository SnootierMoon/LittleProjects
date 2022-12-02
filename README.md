# Little Projects

Collection

## C

1. Number of Good Subsets
 * Solution to a [LeetCode
   problem](https://leetcode.com/problems/the-number-of-good-subsets/)
 * [number\_of\_good\_subsets.c](number_of_good_subsets.c)

## Zig

All tested with `zig 0.10.0`.

1. Bit Combination Iterator (3/13/22)
 * `zig test combination_iterator.zig`
 * Iterate through bitsets in increasing order of bitcount, e.g.: \ `0000`,
   `0001` `0010` `0100` `1000`,\ `0011`, `0101`, `0110`, `1001`, `1010`,
   `1100`,\ `0111`,`1011`, `1101`, `1110`, `1111`.
 * [source](https://github.com/SnootierMoon/Booleanomial-v2)
2. Booleanomial (3/13/22)
 * `zig test booleanomial.zig`
 * Compute boolean polynomials (polynomials over GF(2) which are equivalent to
   boolean expressions)
 * [source](https://github.com/SnootierMoon/Booleanomial-v2)
3. Electron Config Generator (9/24/22)
 * `zig build-exe econfig.zig && ./econfig`
 * Type in an atomic number, and the CLI responds with the element name,
   symbol, electron config, and quantum numbers.
 * [source](https://gist.github.com/SnootierMoon/b0a3c4bca360a3600eca79400c73de1c)
4. Task Scheduler (11/27/22)
 * `zig test task_scheduler.zig`
 * Based on a [LeetCode
   problem](https://leetcode.com/problems/maximum-profit-in-job-scheduling/)
 * Designed to be foolproof: no overflows and bad stuff for full range of
   input
 * Given a list of tasks with set times and profits, compute the optimal task
   which maximizes profit.
