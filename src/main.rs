// A contrived program with different kinds of statics, each given a
// uniquely searchable name so you can grep for it in the section dumps.
//
//  .rodata -> read-only constants & string literals
//  .data   -> initialized writable statics (non-zero)
//  .bss    -> zero-initialized writable statics

// String literal -> lives in .rodata
const FIRST_CONST: &str = "FIRST_CONST_STRING_LITERAL_MARKER";

// Integer const -> usually inlined / .rodata
const SECOND: u64 = 0xCAFEBABE;

// Initialized, non-zero, mutable static -> .data
static mut THIRD_DATA: u64 = 0xDEADBEEF;

// Zero-initialized mutable static -> .bss
static mut FOURTH_BSS: [u64; 64] = [0; 64];

// Initialized non-zero array -> .data
static FIFTH_DATA_ARRAY: [u8; 8] = [1, 2, 3, 4, 5, 6, 7, 8];

fn main() {
    println!("{}", FIRST_CONST);
    println!("SECOND = {:#x}", SECOND);

    // SAFETY: single-threaded demo, just touching the statics so the
    // optimizer/linker keeps them in the binary.
    unsafe {
        THIRD_DATA = THIRD_DATA.wrapping_add(1);
        FOURTH_BSS[0] = THIRD_DATA;
        println!("THIRD_DATA = {:#x}", THIRD_DATA);
        println!("FOURTH_BSS[0] = {:#x}", FOURTH_BSS[0]);
    }

    println!("FIFTH_DATA_ARRAY = {:?}", FIFTH_DATA_ARRAY);
}
