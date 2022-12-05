(module
  (memory (import "js" "mem") 10)
  (import "js" "putchar" (func $putchar (param i64)))
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)
  (import "utils" "strtoll" (func $strtoll (param i32 i32) (result i64)))
  (import "utils" "strchr" (func $strchr  (param i32 i32) (result i32)))
  (data (i32.const 0)  "\00") ;; 00000000 low > 7 / high < 0
  (data (i32.const 1)  "\01") ;; 00000001 low = 7
  (data (i32.const 2)  "\03") ;; 00000011 low = 6
  (data (i32.const 3)  "\07") ;; 00000111 low = 5
  (data (i32.const 4)  "\0F") ;; 00001111 low = 4
  (data (i32.const 5)  "\1F") ;; 00011111 low = 3
  (data (i32.const 6)  "\3F") ;; 00111111 low = 2
  (data (i32.const 7)  "\7F") ;; 01111111 low = 1
  (data (i32.const 8)  "\FF") ;; 11111111 low <= 0 / high >= 7
  (data (i32.const 9)  "\FE") ;; 11111110 high = 6
  (data (i32.const 10) "\FC") ;; 11111100 high = 5
  (data (i32.const 11) "\F8") ;; 11111000 high = 4
  (data (i32.const 12) "\F0") ;; 11110000 high = 3
  (data (i32.const 13) "\E0") ;; 11100000 high = 2
  (data (i32.const 14) "\C0") ;; 11000000 high = 1
  (data (i32.const 15) "\80") ;; 10000000 high = 0
  ;; assume 0 index, not case for problem
  (func $get64Bitset (param $low i32) (param $high i32) (result i64)
    (local $i i32)
    (local $byteIndex i32)
    (local $byteToSet i64)
    (local $r i64)

    (block
      ;; for i = 0; i < 8; i++
      i32.const 0
      local.set $i
      (loop
        ;; i < 8?
        local.get $i
        i32.const 8
        i32.ge_u
        br_if 1

        i64.const 0
        local.set $byteToSet

        (block
          ;; subtract low from 8 and clamp between 0 <= byteIndex <= 8
          i32.const 8
          local.get $low
          i32.sub
          local.tee $byteIndex

          ;; if lt 0 then it's all 0
          i32.const 0
          i32.lt_s
          br_if 0

          ;; if gt 8 then set all 1, high will deal with setting 0 again
          local.get $byteIndex
          i32.const 8
          i32.gt_s
          (if
            (then
              i32.const 8
              local.set $byteIndex
            )
          )

          ;; get byte to set
          local.get $byteIndex
          i64.load8_u
          local.set $byteToSet

          ;; subtract high from 15
          i32.const 15
          local.get $high
          i32.sub
          local.tee $byteIndex

          ;; if lt 8 then its all 1, branch out of block
          i32.const 8
          i32.lt_s
          br_if 0

          ;; if gt 15 then set all 0
          local.get $byteIndex
          i32.const 15
          i32.gt_s
          (if
            (then
              i32.const 0
              local.set $byteIndex
            )
          )

          ;; get bytes to set, shl, and
          local.get $byteIndex
          i64.load8_u
          local.get $byteToSet
          i64.and
          local.set $byteToSet
        )

        ;; shift + set bit
        local.get $byteToSet
        i32.const 7
        local.get $i
        i32.sub
        i32.const 8
        i32.mul
        i64.extend_i32_u
        i64.shl
        local.get $r
        i64.or
        local.set $r

        ;; subtract 8 from high and low
        local.get $low
        i32.const 8
        i32.sub
        local.set $low
        local.get $high
        i32.const 8
        i32.sub
        local.set $high

        ;; i++
        i32.const 1
        local.get $i
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )

    local.get $r
  )
  (func $get128Bitset (param $low i32) (param $high i32) (result v128)
    ;; poor man's 128-bit arithmetic
    v128.const i64x2 0 0
    local.get $low
    local.get $high
    call $get64Bitset
    i64x2.replace_lane 0

    local.get $low
    i32.const 64
    i32.sub
    local.get $high
    i32.const 64
    i32.sub
    call $get64Bitset
    i64x2.replace_lane 1
  )
  (func (export "part1") (result i64)
    (local $i i32)
    (local $ptr i32)
    (local $len i32)
    (local $numPairs i64)
    (local $lo1 i64)
    (local $hi1 i64)
    (local $lo2 i64)
    (local $hi2 i64)
    (local $a v128)
    (local $b v128)
    (local $and v128)

    i64.const 0
    local.set $numPairs

    (block
      (loop
        ;; break if oob
        local.get $i
        global.get $inputLength
        i32.ge_u
        br_if 1

        ;; find first lower bound
        global.get $inputOffset
        local.get $i
        i32.add
        local.tee $ptr
        local.get $ptr
        i32.const 0x2D ;; -
        call $strchr
        local.tee $len
        local.get $len
        local.get $i
        i32.const 1
        i32.add
        i32.add
        local.set $i
        call $strtoll
        local.set $lo1

        ;; find first upper bound
        global.get $inputOffset
        local.get $i
        i32.add
        local.tee $ptr
        local.get $ptr
        i32.const 0x2C ;; ,
        call $strchr
        local.tee $len
        local.get $len
        local.get $i
        i32.const 1
        i32.add
        i32.add
        local.set $i
        call $strtoll
        local.set $hi1

        ;; find second lower bound
        global.get $inputOffset
        local.get $i
        i32.add
        local.tee $ptr
        local.get $ptr
        i32.const 0x2D ;; -
        call $strchr
        local.tee $len
        local.get $len
        local.get $i
        i32.const 1
        i32.add
        i32.add
        local.set $i
        call $strtoll
        local.set $lo2

        ;; find second upper bound
        global.get $inputOffset
        local.get $i
        i32.add
        local.tee $ptr
        local.get $ptr
        i32.const 0x0A ;; \n
        call $strchr
        local.tee $len
        local.get $len
        local.get $i
        i32.const 1
        i32.add
        i32.add
        local.set $i
        call $strtoll
        local.set $hi2

        ;; get bitsets
        local.get $lo1
        i32.wrap_i64
        i32.const 1
        i32.sub
        local.get $hi1
        i32.wrap_i64
        i32.const 1
        i32.sub
        call $get128Bitset
        local.tee $a

        local.get $lo2
        i32.wrap_i64
        i32.const 1
        i32.sub
        local.get $hi2
        i32.wrap_i64
        i32.const 1
        i32.sub
        call $get128Bitset
        local.tee $b

        v128.and
        local.set $and

        ;; compare to a / b, if equal to either then subset.
        (block
          local.get $a
          local.get $and
          v128.xor
          v128.any_true

          (if
            (then)
            (else
              i64.const 1
              local.get $numPairs
              i64.add
              local.set $numPairs
              br 1
            )
          )

          local.get $b
          local.get $and
          v128.xor
          v128.any_true

          (if
            (then)
            (else
              i64.const 1
              local.get $numPairs
              i64.add
              local.set $numPairs
            )
          )
        )

        ;; loop
        br 0
      )
      unreachable
    )
    local.get $numPairs
  )
  (func (export "part2") (result i64)
    (local $i i32)
    (local $ptr i32)
    (local $len i32)
    (local $numPairs i64)
    (local $lo1 i64)
    (local $hi1 i64)
    (local $lo2 i64)
    (local $hi2 i64)
    (local $a v128)
    (local $b v128)
    (local $and v128)

    i64.const 0
    local.set $numPairs

    (block
      (loop
        ;; break if oob
        local.get $i
        global.get $inputLength
        i32.ge_u
        br_if 1

        ;; find first lower bound
        global.get $inputOffset
        local.get $i
        i32.add
        local.tee $ptr
        local.get $ptr
        i32.const 0x2D ;; -
        call $strchr
        local.tee $len
        local.get $len
        local.get $i
        i32.const 1
        i32.add
        i32.add
        local.set $i
        call $strtoll
        local.set $lo1

        ;; find first upper bound
        global.get $inputOffset
        local.get $i
        i32.add
        local.tee $ptr
        local.get $ptr
        i32.const 0x2C ;; ,
        call $strchr
        local.tee $len
        local.get $len
        local.get $i
        i32.const 1
        i32.add
        i32.add
        local.set $i
        call $strtoll
        local.set $hi1

        ;; find second lower bound
        global.get $inputOffset
        local.get $i
        i32.add
        local.tee $ptr
        local.get $ptr
        i32.const 0x2D ;; -
        call $strchr
        local.tee $len
        local.get $len
        local.get $i
        i32.const 1
        i32.add
        i32.add
        local.set $i
        call $strtoll
        local.set $lo2

        ;; find second upper bound
        global.get $inputOffset
        local.get $i
        i32.add
        local.tee $ptr
        local.get $ptr
        i32.const 0x0A ;; \n
        call $strchr
        local.tee $len
        local.get $len
        local.get $i
        i32.const 1
        i32.add
        i32.add
        local.set $i
        call $strtoll
        local.set $hi2

        ;; get bitsets
        local.get $lo1
        i32.wrap_i64
        i32.const 1
        i32.sub
        local.get $hi1
        i32.wrap_i64
        i32.const 1
        i32.sub
        call $get128Bitset
        local.tee $a

        local.get $lo2
        i32.wrap_i64
        i32.const 1
        i32.sub
        local.get $hi2
        i32.wrap_i64
        i32.const 1
        i32.sub
        call $get128Bitset
        local.tee $b

        v128.and
        ;; if any set then is intersecting
        v128.any_true
        (if
          (then
            i64.const 1
            local.get $numPairs
            i64.add
            local.set $numPairs
          )
        )

        ;; loop
        br 0
      )
      unreachable
    )
    local.get $numPairs
  )
)