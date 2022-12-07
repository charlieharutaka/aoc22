(module
  (memory (import "js" "mem") 10)
  (import "js" "putchar" (func $putchar (param i32)))
  (import "js" "printint" (func $printint (param i32)))
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)
  (global $tableOffset i32 (i32.const 0x10000)) ;; start directory table at 0x10000
  (global $tableEntrySize i32 (i32.const 0x20)) ;; the size of a directory entry
  ;; each directory entry is 48 bytes long:
  ;; 0x00..0x0F | 0x10..0x1F  | 0x20..0x23   | 0x24.. 0x30
  ;; dir name   | parent name | dir size i32 | padding for alignment
  (global $tableNEntries (mut i32) (i32.const 0)) ;; mutable number of entries
  ;; add a directory to the table with 0 size
  (data (i32.const 0) "test")
  (data (i32.const 4) "abcd")
  (func $addDirectory
    (param $dirName i32)        ;; directory name pointer
    (param $dirNameLen i32)     ;; directory name length
    (param $parentName i32)     ;; parent name pointer, NULL for root
    (param $parentNameLen i32)  ;; parent name length, 0 for root
    (result i32)                ;; returns the index of the table entry
    (local $i i32)
    (local $limit i32)
    (local $offset i32)
    
    ;; first determine our offset
    global.get $tableOffset
    global.get $tableEntrySize
    global.get $tableNEntries
    i32.mul
    i32.add
    local.set $offset

    ;; then copy over our directory name
    ;; first determine the loop limit, lim = min(dirNameLen, 0x10)
    local.get $dirNameLen
    i32.const 0x10
    local.get $dirNameLen
    i32.const 0x10
    i32.lt_s
    select
    local.set $limit
    
    i32.const 0
    local.set $i

    ;; then loop to copy
    (block
      (loop
        ;; break
        local.get $i
        local.get $limit
        i32.ge_u
        br_if 1

        ;; prepare destination address
        local.get $offset
        local.get $i
        i32.add

        ;; load char
        local.get $dirName
        local.get $i
        i32.add
        i32.load8_u

        ;; store it
        i32.store8

        ;; loop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )

    ;; then copy over our parent name
    ;; first determine the loop limit, lim = min(parentNameLen, 0x10)
    local.get $parentNameLen
    i32.const 0x10
    local.get $parentNameLen
    i32.const 0x10
    i32.lt_s
    select
    local.set $limit
    
    i32.const 0
    local.set $i

    ;; then loop to copy
    (block
      (loop
        ;; break
        local.get $i
        local.get $limit
        i32.ge_u
        br_if 1

        ;; prepare destination address
        local.get $offset
    i32.const 0x10
        local.get $i
        i32.add
        i32.add

        ;; load char
        local.get $parentName
        local.get $i
        i32.add
        i32.load8_u

        ;; store it
        i32.store8

        ;; loop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br 0
      )
      unreachable
    )

    ;; make sure 0x20-0x24 are 0
    i32.const 0x20
    local.get $offset
    i32.add
    i32.const 0
    i32.store

    ;; table index is nEntries
    global.get $tableNEntries

    ;; increment nEntries
    global.get $tableNEntries
    i32.const 1
    i32.add
    global.set $tableNEntries
  )
  (func (export "part1") (result i32)
    i32.const 0
    i32.const 4
    i32.const 4
    i32.const 4
    call $addDirectory

    i32.const 0
    global.set $tableNEntries
  )
  (func (export "part2") (result i32)
    i32.const 0
  )
)