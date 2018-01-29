PROJ = bootloader
PIN_DEF = constraints/up5k.pcf
DEVICE = up5k

SOURCES = edge_detect.v Boot_UP5K.v \
				 usb_fs_in_arb.v usb_fs_in_pe.v \
				 usb_fs_mux.v usb_fs_out_arb.v usb_fs_out_pe.v \
				 usb_fs_pe.v usb_fs_rx.v usb_fs_tx.v \
				 usb_fs_tx_mux.v usb_serial_ctrl_ep.v usb_spi_bridge_ep.v

ARACHNE = arachne-pnr
ARACHNE_ARGS =
ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

all: $(PROJ).bin

%.blif: $(patsubst %, verilog/%, $(SOURCES))
	yosys -q -p 'synth_ice40 -top TinyFPGA_B -blif $@' $^

%.asc: $(PIN_DEF) %.blif
	$(ARACHNE) $(ARACHNE_ARGS) -P sg48 -d $(subst up,,$(subst hx,,$(subst lp,,$(DEVICE)))) -o $@ -p $^

%.bin: %.asc
	$(ICEPACK) $< $@

%.rpt: %.asc
	$(ICETIME) -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	$(ICEPROG) -S $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo $(ICEPROG) -S $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
