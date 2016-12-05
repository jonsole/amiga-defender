TOOLDIR=..\bin
ASM=$(TOOLDIR)\vasmm68k_mot_win32
ASMFLAGS=-m68000 -Fhunk -Iinclude -quiet -ldots -spaces
BMPTORAW=$(TOOLDIR)\bmptoraw
LINK=$(TOOLDIR)\vlink 

OUTDIR ?= output

ASM_FILES = main.s startup.s dos.s graphics.s objects.s player.s laser.s p6112_play.s
OBJ_FILES ?= $(foreach ASM,$(ASM_FILES),$(OUTDIR)/$(basename $(notdir $(ASM))).o)

win_path = $(subst /,\,$1)
make_dir = @if not exist "$(call win_path,$1)" mkdir $(call win_path,$1)
rm_dir = @if exist "$(call win_path,$1)" rmdir /Q /S $(call win_path,$1)

all:	$(OUTDIR)/main

main.s : output/alien1.raw output/alien1.spr  output/alien2.raw output/alien2.spr output/alien1flash.raw output/alien1flash.spr
player.s : output/shipl.raw output/shipr.raw
laser.s : output/laserl.raw output/laserr.raw

$(OUTDIR)/main : $(OBJ_FILES)
	@echo Linking $^ to $@
	@$(LINK) $^ -o $@

$(OUTDIR)/%.o : %.s
	$(call make_dir,$(OUTDIR))
	@echo Assembling $(notdir $<)
	@$(ASM) $(ASMFLAGS) $< -o $@ -L $(basename $@).lst

$(OUTDIR)/alien1.raw : assets/alien1.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 16 16 4 MASK >$(call win_path,$@)

$(OUTDIR)/alien1.spr : assets/alien1.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 16 16 4 SPRITE >$(call win_path,$@)

$(OUTDIR)/alien1flash.raw : assets/alien1flash.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 16 16 4 MASK >$(call win_path,$@)

$(OUTDIR)/alien1flash.spr : assets/alien1flash.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 16 16 4 SPRITE >$(call win_path,$@)

$(OUTDIR)/alien2.raw : assets/alien2.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 16 16 4 MASK >$(call win_path,$@)

$(OUTDIR)/alien2.spr : assets/alien2.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 16 16 4 SPRITE >$(call win_path,$@)

$(OUTDIR)/shipl.raw : assets/shipl.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 32 10 4 MASK >$(call win_path,$@)

$(OUTDIR)/shipr.raw : assets/shipr.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 32 10 4 MASK >$(call win_path,$@)

$(OUTDIR)/laserl.raw : assets/laserl.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 16 16 4 MASK >$(call win_path,$@)

$(OUTDIR)/laserr.raw : assets/laserr.bmp
	$(call make_dir,$(OUTDIR))
	@echo Converting $(notdir $<)
	@$(BMPTORAW) $(call win_path,$<) 16 16 4 MASK >$(call win_path,$@)

#$(OUTDIR)/%.bin : %.bin
#	$(call make_dir,$(OUTDIR))
#	@echo Checksuming $(notdir $@)
#	@$(CHKSUM) $< $@

#$(OUTDIR)/%.bin : $(OUTDIR)/%.out
#	$(call make_dir,$(OUTDIR))
#	@echo Checksuming $(notdir $@)
#	@$(CHKSUM) $< $@

#$(OUTDIR)/toyotune/%.bin : $(OUTDIR)/%.bin
#	$(call make_dir,$(OUTDIR))
#	$(call make_dir,$(OUTDIR)/toyotune)
#	@echo Resizing $(notdir $@) to 32K
#	@$(SCRAMBLE) $(call win_path,$<) 0 - $(call win_path,$@) 8000 FF 00 01234567
	
#$(OUTDIR)/techtom/%.bin : $(OUTDIR)/%.bin
#	$(call make_dir,$(OUTDIR)/techtom)
#	@echo Scrambling $(notdir $@) with code $(XOR),$(CODE)
#	@$(SCRAMBLE) $(call win_path,$<) 0 4000 $(call win_path,$@) 8000 FF $(XOR) $(CODE)
	
all : $(OUTDIR)/main

clean:
	$(call rm_dir,$(OUTDIR))
	