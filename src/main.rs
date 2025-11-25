#![no_std]
#![no_main]

use stark_os::{memory::mem::translate_addr, print, println};
use x86_64::{VirtAddr, structures::paging::PageTable};
use core::panic::PanicInfo;
use bootloader::{BootInfo, entry_point};

entry_point!(kernel_main);


#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    stark_os::hlt_loop();
}



fn kernel_main(boot_info: &'static BootInfo) -> ! {
    stark_os::init();
    println!("Hello World{}", "!");

    let phy_mem_offset = VirtAddr::new(boot_info.physical_memory_offset);

    let addresses = [
        0xb8000,
        0x201008,
        0x0100_0020_1a10,
        boot_info.physical_memory_offset
    ];

    for &address in &addresses {
        let virt = VirtAddr::new(address);
        let phys = unsafe {
            translate_addr(virt, phy_mem_offset)
        };
        println!("{:?} -> {:?}",virt,phys);
    }
   

    stark_os::hlt_loop();
}