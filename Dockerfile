# got this from gemini...  as will many things in this branch
# Use a lightweight Node image (Gemini CLI requires Node)
# We also need Lua, so we start with a base that supports both easily, or install Lua on Node.
FROM node:20-slim

# 1. Install System Deps (Lua, Git, Build Tools for Luarocks)
RUN apt-get update && apt-get install -y \
    lua5.4 \
    liblua5.4-dev \
    git \
    make \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. Install LuaRocks (The package manager)
WORKDIR /tmp
RUN curl -R -O https://luarocks.github.io/luarocks/releases/luarocks-3.13.0.tar.gz && \
    tar zxpf luarocks-3.13.0.tar.gz && \
    cd luarocks-3.13.0 && \
    ./configure && \
    make && \
    make install

# 3. Install Teal (tl) and Busted (Test Runner)
# We install 'busted' to run tests, and 'tl' to check types.
RUN luarocks install tl && \
    luarocks install busted

# 4. Install Google Gemini CLI globally
RUN npm install -g @google/gemini-cli

# 5. Set up the Agent Workspace
WORKDIR /app

# 6. Create a strict entrypoint
# This keeps the container running so you can attach to it, 
# or you can override this command to run a specific agent task.
# CMD ["echo hello-world"]
CMD ["/bin/bash"]
