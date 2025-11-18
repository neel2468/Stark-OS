#![no_std]
#![no_main]

use stark_os::{print, println};



use core::panic::PanicInfo;



#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    stark_os::hlt_loop();
}



#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    stark_os::init();
    println!("Hello World{}", "!");
    stark_os::hlt_loop();
}