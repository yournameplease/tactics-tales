SRC = \
	$(wildcard src/tactics/*.tl) \
	$(wildcard src/tactics/*/*.tl) \
	
LUA = $(SRC:src/%.tl=build/%.lua)

TL = tl
TLFLAGS = --quiet -I src
CYAN = cyan
CYANFLAGS = 

.PHONY: all check build clean


# build/%.lua: src/%.tl
# 	$(TL) $(TLFLAGS) gen --check $< -o $@

default: tactics
# tactics: $(LUA)
tactics:
	$(CYAN) $(CYANFLAGS) build

all: clean test

# build_directories:
# 	mkdir -p \
# 		build/tactics/ui/{panels,components,decoration,layout} \
# 		build/tactics/{story,character,data,corpora,systems,types,util,game} \
# 		build/tactics/battle/{combat,map,tactics}
		# build/spec/{}

clean:
	rm -rf build
	
test: default
	busted build/

.PHONY: clean
