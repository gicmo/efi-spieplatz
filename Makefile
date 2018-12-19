CC       ?= gcc
LD       ?= ld
OBJCOPY  ?= objcopy
CFLAGS   += -Wall

EFI_ARCH = x64
EFI_SSYS = 10

EFI_INCBASE = /usr/include/efi/
EFI_INCDIRS = -I$(EFI_INCBASE) -I$(EFI_INCBASE)/$(EFI_ARCH)/ -I$(EFI_INCBASE)/protocols/
EFI_CFLAGS  = -DEFI_FUNCTION_WRAPPER -DHAVE_USE_MS_ABI $(EFI_INCDIRS) -fno-stack-protector -fpic -fshort-wchar -mno-red-zone
EFI_LIBBASE = /usr/lib64
EFI_LIBDIR  = $(EFI_LIBBASE)/gnuefi
EFI_LIBS    = $(EFI_LIBBASE)/libefi.a $(EFI_LIBBASE)/libgnuefi.a $(EFI_LIBDIR)/crt0-efi-$(EFI_ARCH).o
EFI_LDFLAGS = -nostdlib -Bsymbolic -shared -znocombreloc -e efi_main -T $(EFI_LIBDIR)/elf_$(EFI_ARCH)_efi.lds

all: hw.efi

hw.efi: hw.c

%.o: %.c
	@echo  [ CC ]  $(notdir $@)
	@$(CC) $(CFLAGS) $(EFI_CFLAGS) -c $<

%.so: %.o
	@echo [ LD ] $(notdir $@)
	@$(LD) $(EFI_LDFLAGS) $^ -o $@ $(EFI_LIBS)

%.efi: %.so
	@echo [ OC ] $(notdir $@)
	@$(OBJCOPY) -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel \
		    -j .rela -j .rel.* -j .rela.* -j .rel* -j .rela* \
		    -j .reloc --target=efi-app-x86_64 $*.so $@

%.img: hw.efi
	@echo [ DD ] $(notdir $@)
	@dd if=/dev/zero of=$@ bs=1k count=1440 2> /dev/null
	@echo [ MF ] $(notdir $@)
	@mformat -i $@ -f 1440 ::
	@echo [ MD ] $(notdir $@) ::/EFI
	@mmd -i $@ ::/EFI
	@echo [ MD ] $(notdir $@) ::/EFI/BOOT
	@mmd -i $@ ::/EFI/BOOT
	@echo [ CP ] $< $(notdir $@) ::/EFI/BOOT
	@mcopy -i $@ $^ ::/EFI/BOOT
