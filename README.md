NAO Project
=======

NAO (for "Not Actually an OS" ^^) is a project I start for fun with the goal to learn how to create a bootable USB key from scratch. I learn a lot about the boot process, storage and file systems (especially FATs)

Only the first stage of the boot loader is actually done. The project is in pause for now because of the difficulty to access storage once in protected mode (done by the second stage before launching the kernel). Drivers need to be created to access storage (IDE/SATA/USB...) which isn't easy.
