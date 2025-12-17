SRC = \
	$(wildcard src/tactics/*.tl) \
	$(wildcard src/tactics/*/*.tl) \
	$(wildcard src/spec/*.tl) \
	$(wildcard src/spec/*/*.tl) \
	
LUA = $(SRC:src/%.tl=build/%.lua)

TL = tl
TLFLAGS = --quiet -I src
CYAN = cyan
CYANFLAGS =

BUILD_MARKER = build/.cyan_built

.PHONY: all check build clean


build/%.lua: src/%.tl
	$(CYAN) $(CYANFLAGS) build
	# $(TL) $(TLFLAGS) gen --check $< -o $@


# tactics: $(LUA)
tactics: $(BUILD_MARKER)

$(BUILD_MARKER): $(LUA)
	# $(CYAN) $(CYANFLAGS) build
	@touch $@

all: clean test

# build_directories:
# 	mkdir -p \
# 		build/tactics/ui/{panels,components,decoration,layout} \
# 		build/tactics/{story,character,data,corpora,systems,types,util,game} \
# 		build/tactics/battle/{combat,map,tactics}
		# build/spec/{}

clean:
	rm -rf build
	
test: tactics
	busted build/

.PHONY: clean
