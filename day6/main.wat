(module
  (memory (import "js" "mem") 10)
  (import "js" "putchar" (func $putchar (param i32)))
  (import "js" "printint" (func $printint (param i32)))
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)
  (global $dataOffset i32 (i32.const 0x10000)) ;; start data heap on second page
  (global $nLastChars i32 (i32.const 14)) ;; from problem

  ;; heap layout starting at 0x10000
  ;; 0x00-0x03 0x04-0x07 ... 0x(N*4)-0x(N*4+3)
  ;; bitset 0  bitset 1  ... bitset N

  (func $getBitset (param $i i32) (result i32)
    ;; get bitset of character at position i in input
    ;; index of set bit is ascii code of input[i] - 97
    i32.const 1
    local.get $i
    global.get $inputOffset
    i32.add
    i32.load8_u
    i32.const 97 ;; 'a'
    i32.sub
    i32.shl
  )
  (func $loadBitset (param $idx i32) (result i32)
    local.get $idx
    i32.const 4
    i32.mul
    global.get $dataOffset
    i32.add
    i32.load
  )
  (func $storeBitset (param $idx i32) (param $set i32)
    local.get $idx
    i32.const 4
    i32.mul
    global.get $dataOffset
    i32.add
    local.get $set
    i32.store
  )
  (func (export "part1") (result i32)
    (local $i i32)

    ;; for each iteration:
    ;; a contains bitset of most recent byte
    ;; b contains bitset of 2 most recent bytes
    ;; c contains bitset of 3 most recent bytes
    ;; i-3  i-2  i-1  i
    ;;           <A>  s
    ;;      <---B-->  e
    ;; <-----C----->  t
    
    (local $a i32)
    (local $b i32)
    (local $c i32)
    (local $set i32)

    i32.const 0
    local.set $i

    (block
      (loop
        ;; if i >= inputLength then we reached the end of the buffer
        local.get $i
        global.get $inputLength
        i32.ge_u
        br_if 1

        local.get $i
        call $getBitset
        local.tee $set

        ;; in loop:
        ;; first compute C | set
        ;; if popcnt(C | set) == 4 then break, they are all diff
        local.get $c
        i32.or
        i32.popcnt
        i32.const 4
        i32.eq
        br_if 1

        ;; otherwise
        ;; C := B | set
        ;; B := A | set
        ;; A := set

        local.get $b
        local.get $set
        i32.or
        local.set $c
        local.get $a
        local.get $set
        i32.or
        local.set $b
        local.get $set
        local.set $a

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
    i32.const 1
    i32.add
  )
  ;; basically the same as part 1 except use the heap instead of 14 local vars
  (func (export "part2") (result i32)
    (local $i i32)
    (local $j i32)
    (local $set i32)
    
    i32.const 0
    local.set $i

    ;; clear bitsets
    (block
      (loop
        local.get $i
        global.get $nLastChars
        i32.ge_u
        br_if 1

        local.get $i
        i32.const 0
        call $storeBitset

        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )

    i32.const 0
    local.set $i

    (block
      (loop
        ;; if i >= inputLength then we reached the end of the buffer
        local.get $i
        global.get $inputLength
        i32.ge_u
        br_if 1

        local.get $i
        call $getBitset
        local.tee $set

        ;; in loop:
        ;; first compute bitsets[nLastChars-2] | set
        ;; if popcnt(...) == nLastChars then break, they are all diff
        global.get $nLastChars
        i32.const 2
        i32.sub
        call $loadBitset
        i32.or
        i32.popcnt
        global.get $nLastChars
        i32.eq
        br_if 1

        ;; otherwise
        ;; loop backwards
        ;; for j = nLastChars-2, j > 0, j--
        global.get $nLastChars
        i32.const 2
        i32.sub
        local.set $j
        (block
          (loop
            local.get $j
            i32.const 0
            i32.le_s
            br_if 1

            ;; bitsets[j] = bitsets[j - 1] | set
            local.get $j
            local.get $j
            i32.const 1
            i32.sub
            local.tee $j
            call $loadBitset
            local.get $set
            i32.or
            call $storeBitset

            ;; loop
            br 0
          )
          unreachable
        )

        ;; bitsets[0] = set
        i32.const 0
        local.get $set
        call $storeBitset

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
    i32.const 1
    i32.add
  )
)