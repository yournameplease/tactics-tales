LUA_SRC = $(shell find src/ -type f -name '*.lua')

LLS = lua-language-server

.PHONY: all check ut it test

all: check test

check:
	$(LLS) --check=$(CURDIR)

ut:
	busted src/ mod_spec/ --exclude-tags='it'

it:
	busted src/ --tags='it'

test:
	busted src/ mod_spec/
