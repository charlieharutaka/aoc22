(module
  (memory (import "js" "mem") 10)
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
  (data (i32.const 8)  "\FF") ;; 11111111 low = 0 / high >= 7
  (data (i32.const 9)  "\FE") ;; 11111110 high = 6
  (data (i32.const 10) "\FC") ;; 11111100 high = 5
  (data (i32.const 11) "\F8") ;; 11111000 high = 4
  (data (i32.const 12) "\F0") ;; 11110000 high = 3
  (data (i32.const 13) "\E0") ;; 11100000 high = 2
  (data (i32.const 14) "\C0") ;; 11000000 high = 1
  (data (i32.const 15) "\80") ;; 10000000 high = 0
  ;; assume 0 index, not case for problem
  (func $getBitset (param $low i64) (param $high i64) (result i64 i64)
    (local $i i32)
    (local $byteIndex i32)
    ;; poor man's 128-bit arithmetic
    (local $rlow v128)
    (local $rhigh v128)
  
    ;; init rlow/rhigh to 0
    i64.const 0
    local.tee $rlow
    local.set $rhigh

    ;; compute RLOW
    ;; iterate 8 times
    i32.const 0
    local.set $i
    (block (loop
      ;; branch if i >= 8
      local.get $i
      i32.const 8
      i32.ge_u
      br_if 1

      ;; try low
      (block
        (block
          ;; skip if low is already below zero, it means we're looking for high
          local.get $low
          i32.const 0
          i32.lt_s
          br_if 0
        
          ;; get index for swizzle
          i32.const 8
          local.get $low
          i32.sub
          local.tee $byteIndex

          ;; if less than 0 then skip, we haven't hit low yet
          i32.const 0
          i32.lt_s
          br_if 1

          ;; now 0 < byteIndex <= 8
          local.get $byteIndex
          i64.load8_u

          ;; set bits using SHL OR
          local.get $i
          i64.extend_i32_u
          i64.const 8
          i64.mul
          i64.shl
          local.get $rlow
          i64.or
          local.set $rlow
        )
      )


      ;; increment i and loop
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      br 0
    ) unreachable)
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
        
        ;; find first upper bound
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

        ;; if lo1 <= lo2 & hi1 >= h2 | lo1 >= lo2 & hi1 <= hi2
        local.get $lo1 
        local.get $lo2 
        i64.le_u
        local.get $hi1
        local.get $hi2
        i64.ge_u
        i32.and
        local.get $lo1 
        local.get $lo2 
        i64.ge_u
        local.get $hi1
        local.get $hi2
        i64.le_u
        i32.and
        i32.or
        (if (then
          i64.const 1
          local.get $numPairs
          i64.add
          local.set $numPairs
        ))

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
        
        ;; find first upper bound
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

        ;; if lo1 <= lo2 & hi1 >= h2 | lo1 >= lo2 & hi1 <= hi2
        local.get $lo1 
        local.get $lo2 
        i64.le_u
        local.get $hi1
        local.get $hi2
        i64.ge_u
        i32.and
        local.get $lo1 
        local.get $lo2 
        i64.ge_u
        local.get $hi1
        local.get $hi2
        i64.le_u
        i32.and
        i32.or
        (if (then
          i64.const 1
          local.get $numPairs
          i64.add
          local.set $numPairs
        ))

        ;; loop
        br 0
      )
      unreachable
    )
    local.get $numPairs
  )
)