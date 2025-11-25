use x86_64::{PhysAddr, VirtAddr, registers::control::Cr3, structures::paging::{PageTable, frame, page_table::FrameError}};




pub unsafe fn translate_addr(addr: VirtAddr, physical_memory_offset: VirtAddr) -> Option<PhysAddr> {
    translate_addr_inner(addr,physical_memory_offset)
}

fn translate_addr_inner(addr: VirtAddr,physical_memory_offset: VirtAddr) -> Option<PhysAddr> {
    let (level_4_page_table_frame,_) = Cr3::read();
    let table_indexes = [
        addr.p4_index(),addr.p3_index(),addr.p2_index(),addr.p1_index()
    ];
    let mut frame = level_4_page_table_frame;

    for &index in &table_indexes {
        let virt = physical_memory_offset + frame.start_address().as_u64();
        let table_ptr: *const PageTable = virt.as_ptr();
        let table = unsafe {
            &*table_ptr
        };
        let entry = &table[index];
        frame = match entry.frame() {
            Ok(frame) => frame,
            Err(FrameError::FrameNotPresent) => return None,
            Err(FrameError::HugeFrame) => panic!("Huge pages not supported yet!"),
        };
    }
    Some(frame.start_address()+ u64::from(addr.page_offset()))
}