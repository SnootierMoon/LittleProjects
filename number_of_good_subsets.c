// Source: https://leetcode.com/problems/the-number-of-good-subsets/

// Problem Statement:
//
// Given an array `nums` where `1 <= nums[i] <= 30`, return the number of
// distinct good subsets of nums.
// - A subset of an array is an array that can be formed by removing elements
//   from the array. Two subsets of an array are distinct if the elements
//   chosen to remove are different. A subset is good if its product is a good
//   number.
// - A good number is a number that can be represented as a product of distinct
//   prime numbers.
//
// Return the answer modulo `10^9 + 7`.

// Analysis:
//
// 1. The prime factors of the product of any subset in `nums` will not have
//    prime numbers outside the range `[1, 30]`. Therefore, the products will
//    only have the following prime factors: 2, 3, 5, 7, 11, 13, 17, 19, 23,
//    29.
// 2. Since good numbers cannot have duplicate prime factors, they can only
//    have any given factor at most once. Therefore, every good number either
//    has a certain prime factor or does not. Consequently, there are 2^10 =
//    1024 good numbers.
// 3. We never need to consider any products that are not good. A number that
//    is not good cannot be used to create a good number, because if it has a
//    factor multiple times, any products that includes it will have the same
//    factor multiple times.
// 4. The presence of a 1 doubles the amount of good subsets that can be formed
//    from an array. Any good subset in the array without the 1 could either
//    contain the 1 or not contain the 1 and still be good, and no other good
//    subsets can be formed using the one.

// Solution:
//
// Because every good number either has or doesn't have each of the 10 primes,
// I will convert every number in `nums` to a 10-bit bitset. The nth bit in the
// bitset will be 1 if the number contains the nth prime as a factor. This is a
// convenient form because to check if `x*y` is bad given that `x` and `y` are
// good, I can just check that `bitset(x) & bitset(y) != 0`. Additionally, to
// get the bitset representation of `x * y`, I can do `bitset(x) | bitset(y)`.
// I will never need the original number form because I can do every operation
// I need quickly with the bitset form.
//
// I would like to use a dynamic programming approach. The algorithm could
// store how many subsets of the first `i` elements of `nums` can form each of
// the 1024 good numbers, and then update these numbers using `nums[i]` until
// `i` reaches `nums.len`. However, this would be too slow: even if it is O(n),
// it could require iteration over a 1024-length array for each item in `nums`.
// Instead, I will preprocess the array by converting it to a 30-length array
// called `num_counts`, where `nums_count[k-1]` is the count of k in the array.

const int M = 1000000007;

// prime_factor_table[i-1] is the bitset representation of `i`
const int prime_factor_table[30];

int numberOfGoodSubsets(int* nums, int nums_len) {

    // Count how many of each of the 30 numbers are present in the input list,
    // and store the counts in `num_counts`.
    long num_counts[30];
    for (int i = 0; i < 30; i++) num_counts[i] = 0L;
    for (int i = 0; i < nums_len; i++) num_counts[nums[i] - 1]++;

    // goods[k] is the amount of subsets that can be formed to create a good
    // number which has a bitset representation of k.
    // Initialize `goods[0]` to `1` (one subset can be formed with a product of
    // 1 which is what the bitset 0 represents: the empty subset, for the sake
    // of generality). Initialize `goods[i]` where `i != 0`.
    long goods[1024];
    goods[0] = 1L;
    for (int i = 1; i < 1024; i++) goods[i] = 0L;

    // Iterate through the counts of non-one numbers in `num_counts` (ones will
    // be handled later).
    for (int i = 2; i <= 30; i++) {

        // Get the bitset representation of the current number `i`.
        unsigned i_bitset = prime_factor_table[i-1];

        // If the number is good...
        if (i_bitset != ~0U) {

            // Iterate through the good numbers `j` that can be made.
            for (unsigned j_bitset = 0; j_bitset < 1024; j_bitset++) {
                // If the product `i*j` is good...
                if ((i_bitset & j_bitset) == 0U) {
                    // Increment the number of times that the product `i*j` can
                    // be made by the number of ways that `j` can be made times
                    // the number of `i` there are in `num_counts`.
                    long to_add = (goods[j_bitset] * num_counts[i-1]) % M;
                    goods[i_bitset | j_bitset] 
                        = (goods[i_bitset | j_bitset] + to_add) % M;
                }
            }
        }
    }

    // Accumulate the counts of non-one good numbers that can be made.
    long accum = 0;
    for (int i = 1; i < 1024; i++) accum = (accum + goods[i]) % M;

    for (int i = 0; i < num_counts[0]; i++) accum = (accum << 1) % M;

    return (int)accum;
}

const int prime_factor_table[30] = {
    0b0000000000U, //  1 =     1 : @(0)
    0b0000000001U, //  2 =     2 : @(1<<0)
    0b0000000010U, //  3 =     3 : @(1<<1)
    ~0U,
    0b0000000100U, //  5 =     5 : @(1<<2)
    0b0000000011U, //  6 =   3*2 : @(1<<1 | 1<<0)
    0b0000001000U, //  7 =     7 : @(1<<3)
    ~0U,
    ~0U,
    0b0000000101U, // 10 =   5*2 : @(1<<2 | 1<<0)
    0b0000010000U, // 11 =    11 : @(1<<4)
    ~0U,
    0b0000100000U, // 13 =    13 : @(1<<5)
    0b0000001001U, // 14 =   7*2 : @(1<<4 | 1<<0)
    0b0000000110U, // 15 =   5*3 : @(1<<2 | 1<<1)
    ~0U,
    0b0001000000U, // 17 =    17 : @(1<<6)
    ~0U,
    0b0010000000U, // 19 =    19 : @(1<<7)
    ~0U,
    0b0000001010U, // 21 =   7*3 : @(1<<3 | 1<<1)
    0b0000010001U, // 22 =  11*2 : @(1<<4 | 1<<0)
    0b0100000000U, // 23 =    23 : @(1<<8)
    ~0U,
    ~0U,
    0b0000100001U, // 26 =  13*2 : @(1<<5 | 1<<0)
    ~0U,
    ~0U,
    0b1000000000U, // 29 =    29 : @(1<<9)
    0b0000000111U, // 30 = 2*3*5 : @(1<<0 | 1<<1 | 1<<2)
};
