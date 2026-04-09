TL_SRC  = $(shell find src/ -type f -name '*.tl')
LUA_SRC = $(shell find src/ -type f -name '*.lua')

CYAN = cyan
CYANFLAGS =
LLS = lua-language-server

BUILD_MARKER = build/.cyan_built

.PHONY: all check tactics clean ut it test

tactics: $(BUILD_MARKER)

# Compile .tl files first, then copy all .lua files on top.
# Migrated .lua files overwrite their cyan-compiled counterparts so tests
# always run against the migrated Lua code.
$(BUILD_MARKER): $(TL_SRC) $(LUA_SRC)
	$(CYAN) $(CYANFLAGS) build
	@for f in $(LUA_SRC); do \
		dest="build/$${f#src/}"; \
		mkdir -p "$$(dirname $$dest)"; \
		cp "$$f" "$$dest"; \
	done
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
