// Calculate x^n using no other floating point operations than multiplication
// in O(1).
double my_pow(double x, int n) {
    double res = 1.0;
    
    // normalize n to a positve integer
    if (n < 0) {
        // x^n = (1/x)^-n
        x = 1.0 / x;

        // negate n
        if (n > -2147483648) {
            n = -n;
        } else {
            // if n = -2^31, then -n = 2^31 does not fit in a 32 bit signed
            // integer. set n = 2^31 - 1, and initialize the result to x to
            // account for the lost power.
            res = x;
            n = 2147483647;
        }
    }
    
    // normalize x to a positive number
    if (x < 0) {
        x = -x;
        // if x is negative and n is odd, the result should be negative
        if (n % 2 == 1) {
            res = -res;
        }
    }

    // now we do res *= x^n assuming x > 0 and n > 0.
    for (int i = 0; i < 31; i++) {
        // if this current bit is set in n, multiply the current power of x
        // into res
        if (n & (1 << i)) {
            res *= x;
        }
        // this will make the current x = x^(2^i)
        x *= x;
    }
    
    return res;
}
