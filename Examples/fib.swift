func fib( x: Double) -> Double {
    if x < 3 {
        return 1
    } else {
        return fib(x: x - 1) + fib(x: x - 2)
    }
}
