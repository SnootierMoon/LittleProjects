# Little Projects

## Zig

All tested with `zig 0.10.0`.

1. Bit Combination Iterator (8/24/22)
 * `zig test combination_iterator.zig`
 * Iterate through bitsets in increasing order of bitcount, e.g.: \
   `0000`, `0001` `0010` `0100` `1000`,\
   `0011`, `0101`, `0110`, `1001`, `1010`, `1100`,\
   `0111`,`1011`, `1101`, `1110`, `1111`.
2. Electron Config Generator (9/24/22)
 * `zig build-exe econfig.zig && ./econfig`
 * Type in an atomic number, and the CLI responds with the element name, symbol,
   electron config, and quantum numbers.
3. Task Scheduler (11/27/22)
 * `zig test task_scheduler.zig`
 * Given a list of tasks with set times and profits, compute the optimal task
   which maximizes profit.
