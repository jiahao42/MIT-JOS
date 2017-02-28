* First of all, I would like to add this line in ~/.gdbinit :
    * set disassembly-flavor intel

* In gdb, after push the 3 parameters, it will call readseg() at 0x7d1b
    * pushing 0x0(at 0x7d0f), 0x1000(at 0x7d11) and 0x10000(at 0x7d16) in a sequence means push the parameters of readseg() onto stack
    * ```push ebp && mov ebp esp``` means to start a new frame


* At what point does the processor start executing 32-bit code? What exactly causes the switch from 16- to 32-bit mode?

    * after a jmp or ljmp
    * jmp )x8:0xfd157

* What is the *last* instruction of the boot loader executed, and what is the first instruction of the kernel it just loaded?



* *Where* is the first instruction of the kernel?



* How does the boot loader decide how many sectors it must read in order to fetch the entire kernel from disk? Where does it find this information?
