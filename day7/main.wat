(module
  (memory (import "js" "mem") 10)
  (import "js" "putchar" (func $putchar (param i32)))
  (import "js" "printint" (func $printint (param i32)))
  (global $inputOffset (import "global" "inputOffset") i32)
  (global $inputLength (import "global" "inputLength") i32)
  (global $tableOffset i32 (i32.const 0x10000)) ;; start directory table at 0x10000
  (global $tableEntrySize i32 (i32.const 0x20)) ;; the size of a directory entry
  ;; each directory entry is 32 bytes long:
  ;; 0x00..0x0D | 0x0E..0x1B  | 0x1C...0x1F
  ;; dir name   | parent name | dir size i32
  (global $tableNEntries (mut i32) (i32.const 0)) ;; mutable number of entries
  (func $addDirectory
    (param $dirName i32)        ;; directory name pointer
    (param $dirNameLen i32)     ;; directory name length
    (param $parentName i32)     ;; parent name pointer, NULL for root
    (param $parentNameLen i32)  ;; parent name length, 0 for root
    (result i32)                ;; returns the index of the table entry
  )
)