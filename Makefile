TL_SRC    = $(shell find src/ -type f -name '*.tl')
LUA_SRC   = $(shell find src/ -type f -name '*.lua')
TL_BUILD  = $(patsubst src/%.tl,  build/%.lua, $(TL_SRC))
LUA_BUILD = $(patsubst src/%.lua, build/%.lua, $(LUA_SRC))

TL = tl
TLFLAGS = --quiet -I src
CYAN = cyan
CYANFLAGS =
LLS = lua-language-server

BUILD_MARKER = build/.cyan_built

.PHONY: all check tactics clean ut it test


# Compile Teal sources → build/
build/%.lua: src/%.tl
	$(CYAN) $(CYANFLAGS) build

# Copy migrated Lua sources → build/
build/%.lua: src/%.lua
	@mkdir -p $(dir $@)
	cp $< $@

tactics: $(BUILD_MARKER)

$(BUILD_MARKER): $(TL_SRC) $(LUA_SRC) $(TL_BUILD) $(LUA_BUILD)
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
