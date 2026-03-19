FLAVORS := mocha frappe macchiato latte
SCREENSHOTS := $(addprefix assets/,$(addsuffix .webp,$(FLAVORS)))

.PHONY: screenshots catwalk clean-screenshots all

# Generate all flavor screenshots
screenshots: $(SCREENSHOTS)

assets/%.webp: tapes/%.tape tapes/config.tape
	vhs $<

# Generate catwalk composite from individual screenshots
catwalk: screenshots
	catwalk assets/latte.webp assets/frappe.webp assets/macchiato.webp assets/mocha.webp \
		--output assets/catwalk.webp

# Remove generated screenshots
clean-screenshots:
	rm -f $(SCREENSHOTS) assets/catwalk.webp

# Convenience: regenerate everything
all: catwalk
