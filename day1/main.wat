(module
  (memory (import "js" "mem") 10)
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)
  (import "utils" "strtoll" (func $strtoll (param i32 i32) (result i64)))
  (import "utils" "strchr" (func $strchr  (param i32 i32) (result i32)))
  (data (i32.const 0) "\n")
  (func (export "part1")
    (result i64)
    (local $strlen i32)
    (local $ptr i32)
    (local $acc i64)
    (local $max i64)

    ;; init variables
    i32.const 0
    local.set $ptr
    i64.const 0
    local.set $max

    (block
      (loop
        ;; break if pointer >= length
        local.get $ptr
        global.get $inputLength
        i32.ge_s
        br_if 1

        ;; initialize accumulator
        i64.const 0
        local.set $acc

        ;; accumulate current set
        (block
          (loop
            ;; find the length of the current line
            local.get $ptr
            global.get $inputOffset
            i32.add
            i32.const 0
            i32.load8_u
            call $strchr
            local.tee $strlen
            i32.const 0
            i32.eq

            ;; exit the loop if length is 0
            br_if 1

            ;; parse next int and accumulate
            local.get $ptr
            global.get $inputOffset
            i32.add
            local.get $strlen
            call $strtoll

            local.get $acc
            i64.add
            local.set $acc

            ;; increment pointer + strlen + 1 => loop
            local.get $strlen
            local.get $ptr
            i32.const 1
            i32.add
            i32.add
            local.set $ptr
            br 0
          )
        )

        ;; === part 1 solution ===
        ;; max := max(max, acc)
        local.get $acc
        local.get $max
        local.get $acc
        local.get $max
        i64.gt_u
        select
        local.set $max

        ;; increment pointer + loop
        i32.const 1
        local.get $ptr
        i32.add
        local.set $ptr
        br 0
      )
    )

    ;; part 1
    local.get $max
  )
  (func (export "part2") 
    (result i64)
    (local $strlen i32)
    (local $ptr i32)
    (local $acc i64)
    (local $max i64)
    (local $max2 i64)
    (local $max3 i64)

    ;; init variables
    i32.const 0
    local.set $ptr
    i64.const 0
    local.tee $max
    local.tee $max2
    local.set $max3

    (block
      (loop
        ;; break if pointer >= length
        local.get $ptr
        global.get $inputLength
        i32.ge_s
        br_if 1

        ;; initialize accumulator
        i64.const 0
        local.set $acc

        ;; accumulate current set
        (block
          (loop
            ;; find the length of the current line
            local.get $ptr
            global.get $inputOffset
            i32.add
            i32.const 0
            i32.load8_u
            call $strchr
            local.tee $strlen
            i32.const 0
            i32.eq

            ;; exit the loop if length is 0
            br_if 1

            ;; parse next int and accumulate
            local.get $ptr
            global.get $inputOffset
            i32.add
            local.get $strlen
            call $strtoll

            local.get $acc
            i64.add
            local.set $acc

            ;; increment pointer + strlen + 1 => loop
            local.get $strlen
            local.get $ptr
            i32.const 1
            i32.add
            i32.add
            local.set $ptr
            br 0
          )
        )

        ;; === part 2 solution ===
        ;; if acc > max
        local.get $acc
        local.get $max
        i64.gt_u
        (if
          (then
            local.get $acc
            local.get $max
            local.get $max2
            local.set $max3
            local.set $max2
            local.set $max
          )
          (else
            ;; if acc > max2
            local.get $acc
            local.get $max2
            i64.gt_u
            (if
              (then
                local.get $acc
                local.get $max2
                local.set $max3
                local.set $max2
              )
              (else
                ;; if acc > max3
                local.get $acc
                local.get $max3
                i64.gt_u
                (if
                  (then
                    local.get $acc
                    local.set $max3
                  )
                )
              )
            )
          )
        )
        ;; === end ===

        ;; increment pointer + loop
        i32.const 1
        local.get $ptr
        i32.add
        local.set $ptr
        br 0
      )
    )

    ;; part 2
    local.get $max
    local.get $max2
    local.get $max3
    i64.add
    i64.add
  )
)
