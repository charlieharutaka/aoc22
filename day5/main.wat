(module
  (memory (import "js" "mem") 10)
  (import "js" "putchar" (func $putchar (param i32)))
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)
  (import "utils" "strtol" (func $strtol (param i32 i32) (result i32)))
  (import "utils" "strchr" (func $strchr (param i32 i32) (result i32)))
  (global $stackSize i32 (i32.const 128)) ;; each stack is 128 bytes long
  (global $stackStartPtr i32 (i32.const 0x10000)) ;; start data heap on second page
  (global $garbageStack i32 (i32.const 16)) ;; stack 16 is tmp garbage

  ;; heap layout
  ;; 0x10000 | 0x10080 ... 0x10000 + n * 0x80
  ;; stack 0 | stack 1 ... stack n
  ;; stack layout
  ;; first 4 bytes are i32 describing top of stack
  ;; 0x00 0x01 0x02 0x03 0x04 0x05 ... 0xnElem - 4  0xnElem - 3 ... 0x80
  ;; <--- i32 nElem ---> s0   s1   ... s(nElem - 4) 0x00        ... 0x00

  ;; BOUNDS CHECKING IS FOR NERDS

  ;; pushes a byte to the top of the specified stack
  (func $stackPush (param $idx i32) (param $char i32)
    (local $offset i32)
    (local $nElem i32)

    ;; where does the stack start in the heap
    global.get $stackStartPtr
    global.get $stackSize
    local.get $idx
    i32.mul
    i32.add
    local.tee $offset

    ;; load i32 residing at that address, that is the stack size
    i32.load
    local.tee $nElem

    ;; offset + 4 + nElem is top of stack
    i32.const 4
    i32.add
    local.get $offset
    i32.add

    ;; set value of top
    local.get $char
    i32.store8

    ;; increment nElem and set it
    local.get $offset
    local.get $nElem
    i32.const 1
    i32.add
    i32.store
  )
  ;; pops a byte from the top of the specified stack
  (func $stackPop (param $idx i32) (result i32)
    (local $offset i32)
    (local $nElem i32)

    ;; where does the stack start in the heap
    global.get $stackStartPtr
    global.get $stackSize
    local.get $idx
    i32.mul
    i32.add
    local.tee $offset

    ;; load i32 residing at that address, that is the stack size
    i32.load
    local.tee $nElem

    ;; offset + 3 + nElem is top of stack
    i32.const 3
    i32.add
    local.get $offset
    i32.add

    ;; load value of byte
    i32.load8_u

    ;; decrement nElem and set it
    local.get $offset
    local.get $nElem
    i32.const 1
    i32.sub
    i32.store
  )
  ;; clears specified stack
  (func $stackClear (param $idx i32)
    ;; where does the stack start in the heap
    global.get $stackStartPtr
    global.get $stackSize
    local.get $idx
    i32.mul
    i32.add
    
    ;; set the i32 at that address to 0
    i32.const 0
    i32.store
  )
  ;; initializes a slice of the stacks by parsing the input data
  (func $initStackSlice
    (param $startPtr i32) ;; pointer to start of data to parse
    (param $numStacks i32) ;; number of stacks to expect before stopping parsing
    (local $i i32)
    (local $char i32)

    i32.const 0
    local.set $i

    ;; for each stack value, grab the byte and push it to the respective stack
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
        local.set $char

        (block
          ;; if it is SPACE (0x20) then no value to initialize
          local.get $char
          i32.const 0x20
          i32.eq
          br_if 0

          ;; take byte and push it to stack
          local.get $i
          local.get $char
          call $stackPush
        )

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
    drop
  )
  ;; initializes all the stacks in memory and returns the number of stacks
  (func $parseAndInitStacks (result i32)
    (local $numStacks i32)
    (local $lineLength i32)
    (local $i i32)
    ;; determine number of stacks
    global.get $inputOffset
    i32.const 0x0A ;; \n
    call $strchr
    i32.const 1
    i32.add
    local.tee $lineLength ;; length of a line INCLUDING newline
    i32.const 4
    i32.div_u
    local.set $numStacks

    ;; read until we see "1" (0x31)
    global.get $inputOffset
    i32.const 0x31
    call $strchr
    
    ;; subtract 1 and divide by lineLength
    i32.const 1
    i32.sub
    local.get $lineLength
    i32.div_u
    
    ;; initialize stacks BACKWARDS
    i32.const 1
    i32.sub
    local.set $i
    (block
      (loop
        ;; lt 0 then break
        local.get $i
        i32.const 0
        i32.lt_s
        br_if 1

        ;; stack offset is inputOffset + (lineLength * i)
        global.get $inputOffset
        local.get $lineLength
        local.get $i
        i32.mul
        i32.add
        local.get $numStacks
        call $initStackSlice

        ;; decrement i and loop
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br 0
      )
      unreachable
    )

    local.get $numStacks
  )
  ;; frees all stacks by setting their sizes to 0 (data still there)
  (func $freeStacks (param $numStacks i32)
    (local $i i32)

    i32.const 0
    local.set $i

    (block
      (loop
        ;; br if i >= numStacks
        local.get $i
        local.get $numStacks
        i32.ge_u
        br_if 1

        local.get $i
        call $stackClear

        ;; increment and loop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )
  )
  (func $doMove (param $n i32) (param $srcIdx i32) (param $tgtIdx i32)
    (local $i i32)
    ;; moves n elements from stack src to stack tgt
    ;; for i = 0; i < n; i++
    i32.const 0
    local.set $i
    (block
      (loop
        ;; break if ge n
        local.get $i
        local.get $n
        i32.ge_u
        br_if 1

        local.get $tgtIdx

        ;; pop from src
        local.get $srcIdx
        call $stackPop

        ;; push to tgt
        call $stackPush

        ;; inc i and loop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )
  )
  (func $doMoves
    (local $ptr i32)
    (local $len i32)
    (local $n i32) ;; move n...
    (local $src i32) ;; ... from src ...
    (local $tgt i32) ;; ... to tgt

    global.get $inputOffset
    local.set $ptr

    (block
      (loop
        ;; if ptr exceeds length of input then we die
        local.get $ptr
        global.get $inputLength
        global.get $inputOffset
        i32.add
        i32.ge_u
        br_if 1

        local.get $ptr
        ;; iterate until we find 'm'
        i32.const 0x6D ;; 'm'
        call $strchr
        local.get $ptr
        i32.add
        local.tee $ptr

        ;; now iterate until we find ' '
        i32.const 0x20 ;; ' '
        call $strchr

        ;; add 1 and set ptr
        i32.const 1
        i32.add
        local.get $ptr
        i32.add
        local.tee $ptr

        ;; ;; find where the current number ends
        local.get $ptr
        i32.const 0x20
        call $strchr
        local.tee $len

        ;; parse int mon
        call $strtol
        local.set $n

        ;; skip past current space
        local.get $len
        local.get $ptr
        i32.add
        i32.const 1
        i32.add
        local.tee $ptr

        ;; read until the next space
        i32.const 0x20
        call $strchr
        local.get $ptr
        i32.add
        i32.const 1
        i32.add
        local.tee $ptr

        ;; find where the current number ends
        local.get $ptr
        i32.const 0x20
        call $strchr
        local.tee $len

        ;; parse it
        call $strtol
        local.set $src

        ;; skip past current space
        local.get $len
        local.get $ptr
        i32.add
        i32.const 1
        i32.add
        local.tee $ptr

        ;; read until the next space
        i32.const 0x20
        call $strchr
        local.get $ptr
        i32.add
        i32.const 1
        i32.add
        local.tee $ptr

        ;; find where the current number ends
        local.get $ptr
        i32.const 0x0A ;; \n
        call $strchr
        local.tee $len

        ;; parse it
        call $strtol
        local.set $tgt

        local.get $n
        local.get $src
        i32.const 1
        i32.sub
        local.get $tgt
        i32.const 1
        i32.sub
        call $doMove

        ;; increment ptr and loop
        local.get $ptr
        i32.const 1
        i32.add
        local.set $ptr
        br 0
      )
      unreachable
    )
  )
  (func (export "part1") (result i32)
    (local $numStacks i32)
    (local $i i32)
    call $parseAndInitStacks
    local.set $numStacks

    call $doMoves

    ;; each stack, pop the top
    i32.const 0
    local.set $i
    (loop
      local.get $i
      call $stackPop
      call $putchar
      local.get $i
      i32.const 1
      i32.add
      local.tee $i
      local.get $numStacks
      i32.lt_u
      br_if 0
    )

    i32.const 0x0A
    call $putchar

    ;; free stacks
    local.get $numStacks
    call $freeStacks
    i32.const 0
  )
  (func $doMove2 (param $n i32) (param $srcIdx i32) (param $tgtIdx i32)
    (local $i i32)
    ;; moves n elements from stack src to stack tgt
    ;; for i = 0; i < n; i++
    i32.const 0
    local.set $i
    (block
      (loop
        ;; break if ge n
        local.get $i
        local.get $n
        i32.ge_u
        br_if 1

        global.get $garbageStack

        ;; pop from src
        local.get $srcIdx
        call $stackPop

        ;; push to garbage stack
        call $stackPush

        ;; inc i and loop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )
    ;; for i = 0; i < n; i++
    i32.const 0
    local.set $i
    (block
      (loop
        ;; break if ge n
        local.get $i
        local.get $n
        i32.ge_u
        br_if 1

        local.get $tgtIdx

        ;; pop from garbage
        global.get $garbageStack
        call $stackPop

        ;; push to target
        call $stackPush

        ;; inc i and loop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )
  )
  (func $doMoves2
    (local $ptr i32)
    (local $len i32)
    (local $n i32) ;; move n...
    (local $src i32) ;; ... from src ...
    (local $tgt i32) ;; ... to tgt

    global.get $inputOffset
    local.set $ptr

    (block
      (loop
        ;; if ptr exceeds length of input then we die
        local.get $ptr
        global.get $inputLength
        global.get $inputOffset
        i32.add
        i32.ge_u
        br_if 1

        local.get $ptr
        ;; iterate until we find 'm'
        i32.const 0x6D ;; 'm'
        call $strchr
        local.get $ptr
        i32.add
        local.tee $ptr

        ;; now iterate until we find ' '
        i32.const 0x20 ;; ' '
        call $strchr

        ;; add 1 and set ptr
        i32.const 1
        i32.add
        local.get $ptr
        i32.add
        local.tee $ptr

        ;; ;; find where the current number ends
        local.get $ptr
        i32.const 0x20
        call $strchr
        local.tee $len

        ;; parse int mon
        call $strtol
        local.set $n

        ;; skip past current space
        local.get $len
        local.get $ptr
        i32.add
        i32.const 1
        i32.add
        local.tee $ptr

        ;; read until the next space
        i32.const 0x20
        call $strchr
        local.get $ptr
        i32.add
        i32.const 1
        i32.add
        local.tee $ptr

        ;; find where the current number ends
        local.get $ptr
        i32.const 0x20
        call $strchr
        local.tee $len

        ;; parse it
        call $strtol
        local.set $src

        ;; skip past current space
        local.get $len
        local.get $ptr
        i32.add
        i32.const 1
        i32.add
        local.tee $ptr

        ;; read until the next space
        i32.const 0x20
        call $strchr
        local.get $ptr
        i32.add
        i32.const 1
        i32.add
        local.tee $ptr

        ;; find where the current number ends
        local.get $ptr
        i32.const 0x0A ;; \n
        call $strchr
        local.tee $len

        ;; parse it
        call $strtol
        local.set $tgt

        local.get $n
        local.get $src
        i32.const 1
        i32.sub
        local.get $tgt
        i32.const 1
        i32.sub
        call $doMove2

        ;; increment ptr and loop
        local.get $ptr
        i32.const 1
        i32.add
        local.set $ptr
        br 0
      )
      unreachable
    )
  )
  (func (export "part2") (result i32)
    (local $numStacks i32)
    (local $i i32)
    call $parseAndInitStacks
    local.set $numStacks

    call $doMoves2

    ;; each stack, pop the top
    i32.const 0
    local.set $i
    (loop
      local.get $i
      call $stackPop
      call $putchar
      local.get $i
      i32.const 1
      i32.add
      local.tee $i
      local.get $numStacks
      i32.lt_u
      br_if 0
    )

    i32.const 0x0A
    call $putchar

    ;; free stacks
    local.get $numStacks
    call $freeStacks
    i32.const 0
  )
)