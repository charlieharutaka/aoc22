run with

```
> npm run test day*
```

this does:

1. compiles all `wat` -> `wasm`
2. loads `lib.wasm`
3. reads `day*/input.txt` into WASM memory
4. loads `day*/main.wasm` and instantiates it
5. calls `part1()` and `part2()` and logs the return values
