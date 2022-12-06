(module
  (memory (import "js" "mem") 10)
  (func $strtoll (export "strtoll")
    (param $strptr i32)
    (param $strlen i32)
    (result i64)
    (local $i i32)
    (local $r i64)

    ;; init to 0
    i64.const 0
    local.set $r

    (block
      (loop
        ;; branch if i >= strlen
        local.get $i
        local.get $strlen
        i32.ge_s
        br_if 1

        ;; multiply r by 10
        local.get $r
        i64.const 10
        i64.mul

        ;; get the ascii byte at position i
        local.get $strptr
        local.get $i
        i32.add
        i64.load8_u

        ;; convert to single int by subtracting str[i] - 0x30
        i64.const 0x30
        i64.sub

        ;; add to r
        i64.add
        local.set $r

        ;; increment i
        i32.const 1
        local.get $i
        i32.add
        local.set $i
        br 0
      )
    )

    local.get $r
  )
  (func $strtol (export "strtol")
    (param $strptr i32)
    (param $strlen i32)
    (result i32)
    (local $i i32)
    (local $r i32)

    ;; init to 0
    i32.const 0
    local.set $r

    (block
      (loop
        ;; branch if i >= strlen
        local.get $i
        local.get $strlen
        i32.ge_s
        br_if 1

        ;; multiply r by 10
        local.get $r
        i32.const 10
        i32.mul

        ;; get the ascii byte at position i
        local.get $strptr
        local.get $i
        i32.add
        i32.load8_u

        ;; convert to single int by subtracting str[i] - 0x30
        i32.const 0x30
        i32.sub

        ;; add to r
        i32.add
        local.set $r

        ;; increment i
        i32.const 1
        local.get $i
        i32.add
        local.set $i
        br 0
      )
    )

    local.get $r
  )
  (func $strchr (export "strchr")
    (param $str i32)
    (param $char i32)
    (result i32)
    (local $i i32)
    (local $c i32)

    i32.const 0
    local.set $i

    (block
      (loop
        ;; load *(start + i)
        local.get $str
        local.get $i
        i32.add
        i32.load8_u
        local.tee $c
        ;; check if equal to char & break if equal
        local.get $char
        i32.eq
        br_if 1
        ;; if we find 0x00 (sentinel) then we've fucked up
        i32.const 0
        local.get $c
        i32.eq
        br_if 1
        ;; increment i and loop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
    )

    local.get $i
  )
)
