FLAVORS := mocha frappe macchiato latte
SCREENSHOTS_PNG := $(addprefix assets/,$(addsuffix .png,$(FLAVORS)))
SCREENSHOTS_WEBP := $(addprefix assets/,$(addsuffix .webp,$(FLAVORS)))

.PHONY: screenshots catwalk clean all

# Generate all flavor screenshots (png + webp)
screenshots: $(SCREENSHOTS_WEBP)

assets/%.png: tapes/%.tape tapes/config.tape
	vhs $<

assets/%.webp: assets/%.png
	cwebp -q 90 $< -o $@

# Generate catwalk composite from individual screenshots
catwalk: $(SCREENSHOTS_WEBP)
	catwalk assets/latte.webp assets/frappe.webp assets/macchiato.webp assets/mocha.webp \
		--ext webp --output assets/catwalk.webp

# Remove generated files
clean:
	rm -f $(SCREENSHOTS_PNG) $(SCREENSHOTS_WEBP) assets/catwalk.webp

# Convenience: regenerate everything
all: catwalk
