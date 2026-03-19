FLAVORS := mocha frappe macchiato latte
SCREENSHOTS := $(addprefix assets/,$(addsuffix .png,$(FLAVORS)))

.PHONY: screenshots catwalk clean-screenshots all

# Generate all flavor screenshots
screenshots: $(SCREENSHOTS)

assets/%.png: tapes/%.tape tapes/config.tape
	vhs $<

# Generate catwalk composite from individual screenshots
catwalk: screenshots
	catwalk assets/latte.png assets/frappe.png assets/macchiato.png assets/mocha.png \
		--ext png --output assets/catwalk.webp

# Remove generated screenshots
clean-screenshots:
	rm -f $(SCREENSHOTS) assets/catwalk.webp

# Convenience: regenerate everything
all: catwalk
