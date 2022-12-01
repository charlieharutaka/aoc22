run with

```
> npm run test day*
```

this does:

1. converts all `wat` -> `wasm`
2. reads `day*/input.txt` into WASM memory
3. loads `utils/utils.wasm` and instantiates it
4. loads `day*/main.wasm` and instantiates it with `utils` as a module
5. calls `part1()` and `part2()` and logs the return values
