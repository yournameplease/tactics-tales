--- @meta

--- /system/lib/undo.lua
--- @return __Undo
function create_undo_stack(save_state, load_state, pod_flags, item) end

--- @class __Undo
UNDO = {}

function UNDO:reset() end

function UNDO:undo() end

function UNDO:redo() end

function UNDO:checkpoint() end

function UNDO:new(save_state, load_state, pod_flags, item) end
