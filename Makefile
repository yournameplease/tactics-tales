TL_SRC = $(shell find src/ -type f -name '*.tl')
LUA_BUILD = $(patsubst src/%.tl, build/%.lua, $(TL_SRC))

TL = tl
TLFLAGS = --quiet -I src
CYAN = cyan
CYANFLAGS =

BUILD_MARKER = build/.cyan_built

.PHONY: all check build clean


build/%.lua: src/%.tl
	$(CYAN) $(CYANFLAGS) build

tactics: $(BUILD_MARKER)

$(BUILD_MARKER): $(TL_SRC) $(LUA_BUILD)
	@touch $@

all: clean test

clean:
	rm -rf build
	
test: tactics
	busted build/

.PHONY: clean
