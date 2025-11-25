#![no_std]
#![feature(abi_x86_interrupt)]



pub mod graphics {
    pub mod vga_driver;
}

mod interrupts {
    pub mod gdt;
    pub mod idt;
}

pub mod memory {
    pub mod mem;
}

pub fn init() {
    interrupts::gdt::init_gdt();
    interrupts::idt::init_idt();
    unsafe {
        interrupts::idt::PICS.lock().initialize();
    };
    x86_64::instructions::interrupts::enable();
}

pub fn hlt_loop() -> ! {
    loop {
        x86_64::instructions::hlt();
    }
}