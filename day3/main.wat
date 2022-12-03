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
        call $commonChar
        call $getPriority

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