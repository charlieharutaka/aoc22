(module
  (memory (import "js" "mem") 10)
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)

  ;; binary representation of じゃんけん
  ;; use 32-bit integer, least significant 5 bits are our encoding
  ;; 5 bits for poor man's 3-bit rotation by 1 bit
  ;; rock    = 0b...0_100_1
  ;; scissor = 0b...1_001_0
  ;; paper   = 0b...0_010_0
  ;; using SHL we compare the middle 3 bits
  ;; e.g. if X = rock and Y = scissor:
  ;; 1. compare X and Y, if eq then tie
  ;; 2. compare X and Y >> 1, if eq then X win
  ;; 3. compare X >> 1 and Y, if eq then Y win

  (global $rock i32 (i32.const 9)) ;; 0b01001
  (global $paper i32 (i32.const 4)) ;; 0b00100
  (global $scissor i32 (i32.const 18)) ;; 0b10010
  (global $mask i32 (i32.const 14)) ;; 0b01110
  (data (i32.const 0) "ABCXYZ \n")
  ;; returns move binary representation
  (func $getMove (param $char i32) (result i32)
    (local $ret i32)
    i32.const -1
    local.set $ret
    block
      block
        i32.const 65 ;; A
        local.get $char
        i32.ne
        i32.const 88 ;; X
        local.get $char
        i32.ne
        i32.and
        br_if 0
        ;; set ret to rock
        global.get $rock
        local.set $ret
        br 1
      end
      block
        i32.const 66 ;; B
        local.get $char
        i32.ne
        i32.const 89 ;; Y
        local.get $char
        i32.ne
        i32.and
        br_if 0
        ;; set ret to paper
        global.get $paper
        local.set $ret
        br 1
      end
      block
        i32.const 67 ;; C
        local.get $char
        i32.ne
        i32.const 90 ;; Z
        local.get $char
        i32.ne
        i32.and
        br_if 0
        ;; set ret to scissor
        global.get $scissor
        local.set $ret
        br 1
      end
      unreachable
    end
    local.get $ret
  )
  ;; returns:
  ;; - 0 if move1 beat move2
  ;; - 3 if tie
  ;; - 6 if move2 beat move1
  ;; - 255 if undefined
  (func $compare (param $move1 i32) (param $move2 i32) (result i32)
    (local $ret i32)
    i32.const 0xFF
    local.set $ret
    block
      ;; check if tie
      block
        local.get $move1
        global.get $mask
        i32.and
        local.get $move2
        global.get $mask
        i32.and
        i32.ne
        br_if 0
        i32.const 3
        local.set $ret
        br 1
      end
      ;; check if 1 > 2
      block
        local.get $move1
        i32.const 1
        i32.shl
        global.get $mask
        i32.and
        local.get $move2
        global.get $mask
        i32.and
        i32.ne
        br_if 0
        i32.const 0
        local.set $ret
        br 1
      end
      block
        local.get $move1
        global.get $mask
        i32.and
        local.get $move2
        i32.const 1
        i32.shl
        global.get $mask
        i32.and
        i32.ne
        br_if 0
        i32.const 6
        local.set $ret
        br 1
      end
      unreachable
    end
    local.get $ret
  )
  ;; 1 for rock, 2 for paper, 3 for scissor, 0 otherwise
  (func $move2score (param $move i32) (result i32)
    (local $masked i32)
    (local $ret i32)
    i32.const 0
    local.set $ret
    local.get $move
    global.get $mask
    i32.and
    local.set $masked
    block
      ;; cmp and ret
      local.get $masked
      global.get $rock
      global.get $mask
      i32.and
      i32.eq
      if
        i32.const 1
        local.set $ret
        br 1
      end
      ;; cmp and ret
      local.get $masked
      global.get $paper
      global.get $mask
      i32.and
      i32.eq
      if
        i32.const 2
        local.set $ret
        br 1
      end
      ;; cmp and ret
      local.get $masked
      global.get $scissor
      global.get $mask
      i32.and
      i32.eq
      if
        i32.const 3
        local.set $ret
        br 1
      end
      unreachable
    end
    local.get $ret
  )
  (func $getScoreForResult (param $move1 i32) (param $resultChar i32) (result i32)
    (local $ret i32)
    i32.const 0
    local.set $ret
    ;; if win, Y = X >> 1
    ;; if tie, Y = X
    ;; if lose, Y = X << 1
    block
      local.get $resultChar
      i32.const 88 ;; X
      i32.eq
      if
        ;; lose, Y = X << 1
        local.get $move1
        i32.const 1
        i32.shl
        call $move2score
        local.set $ret
        br 1
      end
      local.get $resultChar
      i32.const 89 ;; Y
      i32.eq
      if
        ;; tie, Y = X
        local.get $move1
        call $move2score
        i32.const 3
        i32.add
        local.set $ret
        br 1
      end
      local.get $resultChar
      i32.const 90 ;; Z
      i32.eq
      if
        ;; win, Y = X >> 1
        local.get $move1
        i32.const 1
        i32.shr_u
        call $move2score
        i32.const 6
        i32.add
        local.set $ret
        br 1
      end
      unreachable
    end
    local.get $ret
  )
  (func (export "part1") (result i64)
    (local $i i32)
    (local $char1 i32)
    (local $char2 i32)
    (local $move2 i32)
    (local $score i64)
    (local $acc i32)

    ;; init i = 0, score = 0
    i32.const 0
    local.set $i
    i64.const 0
    local.set $score

    block
      loop
        ;; exit block if i >= inputLength
        local.get $i
        global.get $inputLength
        i32.ge_u
        br_if 1

        ;; load first char
        local.get $i
        global.get $inputOffset
        i32.add
        i32.load8_u
        local.set $char1

        ;; load second char
        local.get $i
        global.get $inputOffset
        i32.const 2
        i32.add
        i32.add
        i32.load8_u
        local.set $char2

        ;; win/loss
        local.get $char1
        call $getMove
        local.get $char2
        call $getMove
        local.tee $move2

        ;; outcome, 0 = loss, 3 = tie, 6 = win
        call $compare
        local.set $acc

        ;; get shape offset
        local.get $move2
        call $move2score
        local.get $acc
        i32.add

        ;; add acc to score
        i64.extend_i32_s
        local.get $score
        i64.add
        local.set $score

        ;; increment i to next line and loop
        i32.const 4
        local.get $i
        i32.add
        local.set $i
        br 0
      end
    end
    local.get $score
  )
  (func (export "part2") (result i64)
    (local $i i32)
    (local $score i64)

    ;; init i = 0, score = 0
    i32.const 0
    local.set $i
    i64.const 0
    local.set $score

    block
      loop
        ;; exit block if i >= inputLength
        local.get $i
        global.get $inputLength
        i32.ge_u
        br_if 1

        ;; load first char
        local.get $i
        global.get $inputOffset
        i32.add
        i32.load8_u

        ;; convert to move
        call $getMove

        ;; load second char
        local.get $i
        global.get $inputOffset
        i32.const 2
        i32.add
        i32.add
        i32.load8_u

        ;; get score
        call $getScoreForResult
        i64.extend_i32_u

        local.get $score
        i64.add
        local.set $score

        ;; increment i to next line and loop
        i32.const 4
        local.get $i
        i32.add
        local.set $i

        br 0
      end
    end
    local.get $score
  )
)
