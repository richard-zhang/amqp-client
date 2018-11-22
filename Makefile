.PHONY: all build clean test install update-version update-spec doc commit-doc
all: build

build:
	dune build @install

clean:
	dune clean
	rm -f test/jbuild

test:
	dune runtest

install: build
	dune install

uninstall:
	dune uninstall

# Run tests.
tests/%.exe: tests/%.ml
	dune build $@

integration: build
	dune build -j 10 @integration

examples: build
	dune build @examples

update-version: VERSION=$(shell head -n 1 Changelog | sed 's/:.*//')
update-version:
	@echo "Set version to: $(VERSION)"
	@sed -i 's/version = ".*"/version = "$(VERSION)"/' async/src/connection.ml
	@sed -i 's/^version: ".*"/version: "$(VERSION)"/' amqp-client*.opam
	@sed -i "s/\(.*\"amqp-client\" {[ ]*= \"\).*\(\" }\)/\1${VERSION}\2/" amqp-client-*.opam

update-spec:
	@echo "Retrieving AMQP spec from RabbitMQ servers"
	curl --fail https://www.rabbitmq.com/resources/specs/amqp0-9-1.extended.xml > spec/amqp0-9-1.extended.xml

doc:
	dune build @doc

gh-pages: doc
	git clone `git config --get remote.origin.url` .gh-pages --reference .
	git -C .gh-pages checkout --orphan gh-pages
	git -C .gh-pages reset
	git -C .gh-pages clean -dxf
	cp  -r _build/default/_doc/_html/* .gh-pages
	git -C .gh-pages add .
	git -C .gh-pages config user.email 'docs@amqp-client'
	git -C .gh-pages commit -m "Update documentation"
	git -C .gh-pages push origin gh-pages -f
	rm -rf .gh-pages

release:
	opam publish
