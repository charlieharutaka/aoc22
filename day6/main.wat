(module
  (memory (import "js" "mem") 10)
  (import "js" "putchar" (func $putchar (param i32)))
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)
  (func (export "part1") (result i32)
    (local $i i32)

    ;; for each iteration:
    ;; a contains bitset of most recent byte
    ;; b contains bitset of 2 most recent bytes
    ;; c contains bitset of 3 most recent bytes
    ;; i-3  i-2  i-1  i
    ;;           <A>  t
    ;;      <---B-->  m
    ;; <-----C----->  p

    ;; in loop:
    ;; first compute D := C | tmp
    ;; if popcnt(D) == 4 then break
    ;; otherwise
    ;; A := tmp
    ;; B := A | tmp
    ;; C := B | tmp
    
    (local $a i32)
    (local $b i32)
    (local $c i32)
    (local $d i32)
    (local $tmp i32)

    i32.const 0
    local.set $i

    (block
      (loop
        ;; if i >= inputLength then we reached the end of the buffer
        local.get $i
        global.get $inputLength
        i32.ge_u
        br_if 1

        ;; prepare stack for shl
        i32.const 1

        ;; load in whatever is at input[i]
        local.get $i
        i32.load8_u
        i32.const 97 ;; 'a'
        i32.sub
        i32.shl

        ;; this is our set
        local.tee $tmp

        ;; shift it down
        ;; b = a | tmp -> x + y
        ;; c = b | tmp -> x + y + z
        ;; d = c | tmp -> x + y + z + w

        ;; increment and loop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )

    i32.const 0
  )
  (func (export "part2") (result i32)
    i32.const 0
  )
)