# This comes from Gemini, beware.
# ==========================================
# Configuration & Path Definitions
# ==========================================
SHELL := /bin/bash
SRC_DIR := src
LIB_DIR := lib
TYPES_DIR := picotron_types
BUILD_DIR := build
TYPES_FILE := picotron.d.tl
PREBUILD_SCRIPT := ./prebuild.sh

# Recursively find files to ensure path safety
# This detects new files added to subdirectories automatically
SRC_FILES := $(wildcard $(SRC_DIR)/*.tl)
TYPES_FILES := $(wildcard $(TYPES_DIR)*.d.tl)

.PHONY: all check build clean

# Default target
all: build

# ==========================================
# Targets
# ==========================================

# 1. Clean
# Removes the build directory and the prebuild marker
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -f $(TYPES_FILE)

# 2. Prebuild Logic
# Logic: Run prebuild.sh only if lib/ files or types.d.tl have changed.
# We touch the marker file afterward to update the timestamp.
$(TYPES_FILE): $(TYPES_FILES)
	@echo "Dependencies changed. Running prebuild script..."
	chmod +x $(PREBUILD_SCRIPT)
	$(PREBUILD_SCRIPT)

# 3. Check
# Logic: Ensure prebuild runs first, then run cyan check.
# We use $(SRC_FILES) instead of raw globs to ensure shell compatibility.
check: $(TYPES_FILE)
	@echo "Running cyan check..."
	cyan check $(SRC_FILES)

# 4. Build
# Logic: Depends on the prebuild marker (handles lib changes) 
# AND src files (handles src changes).
build: $(TYPES_FILE) $(SRC_FILES)
	@echo "Building project..."
	cyan build
