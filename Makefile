FLAVORS := mocha frappe macchiato latte
SCREENSHOTS_PNG := $(addprefix assets/,$(addsuffix .png,$(FLAVORS)))
SCREENSHOTS_WEBP := $(addprefix assets/,$(addsuffix .webp,$(FLAVORS)))

REQUIRED_TOOLS := vhs cwebp catwalk

.PHONY: screenshots catwalk clean all check-deps

check-deps:
	@missing=""; \
	for tool in $(REQUIRED_TOOLS); do \
		command -v $$tool >/dev/null 2>&1 || missing="$$missing $$tool"; \
	done; \
	if [ -n "$$missing" ]; then \
		echo "Error: missing required tools:$$missing" >&2; \
		echo "" >&2; \
		echo "Install them:" >&2; \
		echo "  vhs      — https://github.com/charmbracelet/vhs" >&2; \
		echo "  cwebp    — libwebp (pacman -S libwebp / brew install webp)" >&2; \
		echo "  catwalk  — https://github.com/catppuccin/catwalk" >&2; \
		exit 1; \
	fi

# Generate all flavor screenshots (png + webp), then clean up PNGs
screenshots: check-deps $(SCREENSHOTS_WEBP)
	rm -f $(SCREENSHOTS_PNG)

assets/%.png: tapes/%.tape tapes/config.tape
	vhs $<

assets/%.webp: assets/%.png
	cwebp -q 90 $< -o $@

# Generate catwalk composite from individual screenshots
catwalk: check-deps $(SCREENSHOTS_WEBP)
	catwalk assets/latte.webp assets/frappe.webp assets/macchiato.webp assets/mocha.webp \
		--ext webp --output assets/catwalk.webp
	rm -f $(SCREENSHOTS_PNG)

# Remove generated files
clean:
	rm -f $(SCREENSHOTS_PNG) $(SCREENSHOTS_WEBP) assets/catwalk.webp

# Convenience: regenerate everything
all: catwalk
