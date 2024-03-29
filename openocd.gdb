
# print demangled symbols
set print asm-demangle on

# set backtrace limit to not have infinite backtrace loops
set backtrace limit 32

# # send captured ITM to the file itm.fifo
# # (the microcontroller SWO pin must be connected to the programmer SWO pin)
# # 8000000 must match the core clock frequency
# monitor tpiu config internal itm.txt uart off 8000000

# # OR: make the microcontroller SWO pin output compatible with UART (8N1)
# # 8000000 must match the core clock frequency
# # 2000000 is the frequency of the SWO pin
# monitor tpiu config external uart off 8000000 2000000

# # enable ITM port 0
# monitor itm port 0 on

define reload
    # reload symbols
    python gdb.execute("file " + gdb.current_progspace().filename)
    # clear cache
    directory

    # flash
    load
    # start
    monitor reset halt
    stepi
end
document reload
Reloads the firmware into the remote target.
end

define reset
    monitor reset halt
end
document reload
Resets the remote target.
end

set architecture arm_any
target extended-remote :3333
# monitor arm semihosting enable

set mem inaccessible-by-default off
