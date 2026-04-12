LUA_SRC = $(shell find src/ -type f -name '*.lua')

LLS = lua-language-server

BUILD_MARKER = build/.cyan_built

.PHONY: all check ut it test

all: check test

check:
	$(LLS) --check=$(CURDIR)

ut:
	busted build/ --exclude-tags='it'

it:
	busted build/ --tags='it'

test:
	busted build/
