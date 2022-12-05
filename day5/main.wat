(module
  (memory (import "js" "mem") 10)
  (import "js" "putchar" (func $putchar (param i64)))
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)
  (import "utils" "strtoll" (func $strtoll (param i32 i32) (result i64)))
  (import "utils" "strchr" (func $strchr  (param i32 i32) (result i32)))
  (global $stackSize i32 (i32.const 128)) ;; 128 elements per stack
  (global $stackStartPtr i32 (i32.const 0x10000)) ;; start data heap on second page
  (func $initStackSlice
    (param $startPtr i32) ;; pointer to start of data to parse
    (param $sliceIdx i32) ;; pointer to which element in the stack we are initializing
    (param $numStacks i32) ;; number of stacks to expect before stopping parsing
    (local $i i32)
    i32.const 0
    local.set $i

    (block
      (loop
        ;; break if ge numstacks
        local.get $i
        local.get $numStacks
        i32.ge_u
        br_if 1

        ;; each stack's value is at address startPtr + (i * 4) + 1
        local.get $startPtr
        local.get $i
        i32.const 4
        i32.mul
        i32.const 1
        i32.add
        i32.add
        i32.load8_u

        ;; if it is SPACE (0x20) then no value to initialize

        ;; increment and loop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )

    local.get $i
  )
  (func (export "part1") (result i32)
    (local $numStacks i32)
    ;; get number of stacks
    global.get $inputOffset
    i32.const 0x0A ;; \n
    call $strchr
    i32.const 1
    i32.add
    i32.const 4
    i32.div_u


  )
  (func (export "part2") (result i32)
    i32.const 0
  )
)