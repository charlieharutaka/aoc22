(module
  (memory (import "js" "mem") 10)
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)
  (func $strchr (import "utils" "strchr") (param i32 i32) (result i32))
  (global $newline i32 (i32.const 0x0A))
  (global $lowerCaseOffset i32 (i32.const 96))
  (global $upperCaseOffset i32 (i32.const 38))
  (func $getPriority (param $char i32) (result i64)
    (local $r i64)
    i64.const 0
    local.set $r

    ;; uppercase
    ;; if (char >= 65 && char <= 90)
    (block
      i32.const 65
      local.get $char
      i32.gt_u
      br_if 0

      i32.const 90
      local.get $char
      i32.lt_u
      br_if 0

      local.get $char
      global.get $upperCaseOffset
      i32.sub
      i64.extend_i32_u
      local.set $r
    )
    ;; lowercase
    ;; if (char >= 97 && char <= 122)
    (block
      i32.const 97
      local.get $char
      i32.gt_u
      br_if 0

      i32.const 122
      local.get $char
      i32.lt_u
      br_if 0

      local.get $char
      global.get $lowerCaseOffset
      i32.sub
      i64.extend_i32_u
      local.set $r
    )
    local.get $r
  )
  (func $commonChar (param $array1 i32) (param $array1len i32) (param $array2 i32) (param $array2len i32) (result i32)
    (local $i i32)
    (local $j i32)
    (local $r i32)
    (local $c i32)

    i32.const 255
    local.set $r

    ;; for i = 0; i < array1len; i++
    i32.const 0
    local.set $i
    (block (loop
      local.get $i
      local.get $array1len
      i32.ge_s
      br_if 1

      ;; get array1[i]
      local.get $i
      local.get $array1
      i32.add
      i32.load8_u
      local.set $c
  
      ;; for j = 0; l < array2len; j++
      i32.const 0
      local.set $j
      (block (loop
        local.get $j
        local.get $array2len
        i32.ge_s
        br_if 1

        ;; get c
        local.get $c

        ;; get array2[i]
        local.get $j
        local.get $array2
        i32.add
        i32.load8_u

        ;; compare, if equal return
        i32.eq
        (if (then
          local.get $c
          local.set $r
          br 4
        ))

        i32.const 1
        local.get $j
        i32.add
        local.set $j
        br 0
      ) unreachable)

      i32.const 1
      local.get $i
      i32.add
      local.set $i
      br 0
    ) unreachable)
    local.get $r
  )
  (func $commonCharOf3
    (param $array1 i32)
    (param $array1len i32)
    (param $array2 i32)
    (param $array2len i32)
    (param $array3 i32)
    (param $array3len i32)
    (result i32)
    (local $i i32)
    (local $j i32)
    (local $k i32)
    (local $c i32)
    (local $d i32)
    (local $r i32)

    i32.const 255
    local.set $r
    
    ;; for i = 0; i < array1len; i++
    i32.const 0
    local.set $i
    (block (loop
      local.get $i
      local.get $array1len
      i32.ge_s
      br_if 1

      ;; get array1[i]
      local.get $i
      local.get $array1
      i32.add
      i32.load8_u
      local.set $c
  
      ;; for j = 0; l < array2len; j++
      i32.const 0
      local.set $j
      (block (loop
        local.get $j
        local.get $array2len
        i32.ge_s
        br_if 1

        ;; get array2[i]
        local.get $j
        local.get $array2
        i32.add
        i32.load8_u
        local.set $d

        (block 
          ;; if c != d we can skip this loop
          local.get $c
          local.get $d
          i32.ne
          br_if 0

          ;; precond: c == d
          ;; for k = 0; k < array2len; k++
          i32.const 0
          local.set $k
          (loop
            local.get $k
            local.get $array3len
            i32.ge_s
            br_if 1

            ;; get c
            local.get $c

            ;; get array3[k]
            local.get $k
            local.get $array3
            i32.add
            i32.load8_u

            ;; compare, if equal return
            i32.eq
            (if (then
              local.get $c
              local.set $r
              br 6
            ))

            i32.const 1
            local.get $k
            i32.add
            local.set $k
            br 0
          )
        )

        i32.const 1
        local.get $j
        i32.add
        local.set $j
        br 0
      ) unreachable)

      i32.const 1
      local.get $i
      i32.add
      local.set $i
      br 0
    ) unreachable)
    local.get $r
  )
  (func $string2bitset (param $array i32) (param $length i32) (result i64)
    ;; subtract 65 from each char. then each char becomes:
    ;; A = 0 -> Z = 25, garbage, a = 32 -> z = 57 
    ;; these can index bits in an i64
    (local $set i64)
    (local $i i32)
    (local $vector v128)
    (local $numElem i32)

    i32.const 0
    local.set $i
    i64.const 0
    local.set $set

    ;; use v128 to subtract 65 from each element
    (loop
      ;; load array1[i..i+16]
      local.get $i
      local.get $array
      i32.add
      v128.load
      i32.const 65
      i8x16.splat
      i8x16.sub
      local.set $vector

      ;; figure out where to stop grabbing garbage from the vector
      local.get $length
      local.get $i
      i32.sub
      local.set $numElem

      ;; insanity
      (block
        local.get $set
        i32.const 0
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 0
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 1
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 1
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 2
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 2
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 3
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 3
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 4
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 4
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 5
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 5
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 6
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 6
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 7
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 7
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 8
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 8
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 9
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 9
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 10
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 10
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 11
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 11
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 12
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 12
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 13
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 13
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 14
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 14
        i64.extend_i32_u
        i64.shl
        i64.or
        local.tee $set
        i32.const 15
        local.get $numElem
        i32.ge_u
        br_if 0
        i64.const 1
        local.get $vector
        i8x16.extract_lane_u 15
        i64.extend_i32_u
        i64.shl
        i64.or
        local.set $set
      )
      
      ;; add 16 to i
      i32.const 16
      local.get $i
      i32.add
      local.tee $i

      ;; loop if not out of bound
      local.get $length
      i32.lt_u
      br_if 0
    )
    
    local.get $set
  )
  (func $commonChar2 (param $array1 i32) (param $array1len i32) (param $array2 i32) (param $array2len i32) (result i64)
    ;; subtract 65 from each char. then each char becomes:
    ;; A = 0 -> Z = 25, garbage, a = 32 -> z = 57 
    ;; these can index bits in an i64
    (local $setA i64)
    (local $setB i64)
    (local $score i64)

    local.get $array1
    local.get $array1len
    call $string2bitset
    local.tee $setA
    local.get $array2
    local.get $array2len
    call $string2bitset
    local.tee $setB
    i64.and

    ;; get score using CTZ
    i64.ctz
    local.tee $score
    ;; if 0 < ctz < 32, add 27
    ;; else subtract 31
    i64.const 0
    i64.ge_u
    local.get $score
    i64.const 32
    i64.lt_u
    i32.and
    (if
      (then
        local.get $score
        i64.const 27
        i64.add
        local.set $score
      )
      (else
        local.get $score
        i64.const 31
        i64.sub
        local.set $score
      )
    )

    local.get $score
  )
  (func (export "part1") (result i64)
    (local $i i32)
    (local $lineStart i32)
    (local $lineLength i32)
    (local $lineHalfLength i32)
    (local $lineMidpoint i32)
    (local $ret i64)

    i64.const 0
    local.set $ret
    i32.const 0
    local.set $i

    block
      loop
        ;; break if EOF
        local.get $i
        global.get $inputLength
        i32.ge_s
        br_if 1

        ;; find current length of line
        local.get $i
        global.get $inputOffset
        i32.add
        local.tee $lineStart
        global.get $newline
        call $strchr
        local.tee $lineLength

        ;; find midpoint
        i32.const 2
        i32.div_u
        local.tee $lineHalfLength
        local.get $lineStart
        i32.add
        local.set $lineMidpoint

        ;; find common element
        local.get $lineStart
        local.get $lineHalfLength
        local.get $lineMidpoint
        local.get $lineHalfLength
        call $commonChar2
        ;; call $getPriority

        local.get $ret
        i64.add
        local.set $ret

        local.get $lineLength
        local.get $i
        i32.add
        i32.const 1
        i32.add
        local.set $i
        br 0
      end
    end
    
    local.get $ret
  )
  (func (export "part2") (result i64)
    (local $i i32)
    (local $line1start i32)
    (local $line1length i32)
    (local $line2start i32)
    (local $line2length i32)
    (local $line3start i32)
    (local $line3length i32)
    (local $ret i64)
    (local $tmp i32)

    i64.const 0
    local.set $ret
    i32.const 0
    local.set $i

    block
      loop
        ;; break if EOF
        local.get $i
        global.get $inputLength
        i32.ge_s
        br_if 1

        ;; find 1st line
        local.get $i
        global.get $inputOffset
        i32.add
        local.tee $line1start
        global.get $newline
        call $strchr
        local.tee $line1length

        ;; increment ptr and start again
        local.get $i
        i32.add
        i32.const 1
        i32.add
        local.set $i

        ;; find 2nd line
        local.get $i
        global.get $inputOffset
        i32.add
        local.tee $line2start
        global.get $newline
        call $strchr
        local.tee $line2length

        ;; increment ptr and start again
        local.get $i
        i32.add
        i32.const 1
        i32.add
        local.set $i

        ;; find 3rd line
        local.get $i
        global.get $inputOffset
        i32.add
        local.tee $line3start
        global.get $newline
        call $strchr
        local.tee $line3length

        ;; increment ptr and start again
        local.get $i
        i32.add
        i32.const 1
        i32.add
        local.set $i

        ;; find common char of all 3 lines
        local.get $line1start
        local.get $line1length
        local.get $line2start
        local.get $line2length
        local.get $line3start
        local.get $line3length
        call $commonCharOf3
        call $getPriority

        local.get $ret
        i64.add
        local.set $ret

        br 0
      end
    end
    
    local.get $ret
  )
)