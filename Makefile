TL_SRC = $(shell find src/ -type f -name '*.tl')
LUA_BUILD = $(patsubst src/%.tl, build/%.lua, $(TL_SRC))

TL = tl
TLFLAGS = --quiet -I src
CYAN = cyan
CYANFLAGS =

BUILD_MARKER = build/.cyan_built

LLS = lua-language-server

.PHONY: all check build clean


build/%.lua: src/%.tl
	$(CYAN) $(CYANFLAGS) build

tactics: $(BUILD_MARKER)

$(BUILD_MARKER): $(TL_SRC) $(LUA_BUILD)
	@touch $@

all: clean check test

check:
	$(LLS) --check=$(CURDIR) --configpath=$(CURDIR)/.luarc.json --check_format=pretty

clean:
	rm -rf build
	
ut: tactics
	busted build/ --exclude-tags='it'
	
it: tactics
	busted build/ --tags='it'

test: tactics
	busted build/

.PHONY: clean
