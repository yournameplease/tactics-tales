local interface GameContext
end
local interface MenuStepDefinition<GC>
	type: string
end

global record MultipleOptionsMenuDefinition<GC>
    is MenuStepDefinition<GC>
    where self.type == "CURSOR_MULTIPLE_OPTIONS"
end

global record MultipleOptionsMenuDefinition<GC>
    is MenuStepDefinition<GC>
    where self.type == "CURSOR_LIST"
end

global record Foo
end
global record Foo
end

