LUA_SRC = $(shell find src/ -type f -name '*.lua')

LLS = lua-language-server

.PHONY: all check ut it test coverage format checkstyle

all: check test format

check:
	$(LLS) --check=$(CURDIR)

ut:
	busted src/ mod_spec/ --exclude-tags='it'

it:
	busted src/ --tags='it'

test:
	busted src/ mod_spec/

coverage:
	busted src/ mod_spec/ --helper=busted_coverage_setup.lua
	luacov

format:
	CodeFormat format -w . -d

checkstyle:
	CodeFormat check -w . -d
