MANPAGES += man1/runic.1
MANPAGES += man1/runic-compile.1
MANPAGES += man1/runic-documentation.1
MANPAGES += man1/runic-interactive.1

.PHONY: clean

all: $(MANPAGES)

man1/%.1: %.1.txt
	@mkdir -p man1
	asciidoctor -b manpage -o $@ $<

clean:
	rm -rf man1
