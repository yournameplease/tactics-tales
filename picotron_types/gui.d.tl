-- --- @meta

-- --- @class __GUI_PROPS
-- --- @field height? integer
-- --- @field height_rel? integer
-- --- @field width? integer
-- --- @field width_rel? integer
-- --- @field x? integer
-- --- @field y? integer
-- --- @field z? integer
-- --- @field click? function
-- --- @field release? function
-- --- @field tap? function
-- --- @field update? function
-- --- @field draw? function
-- __GUI_PROPS = {}

-- --- @class __GUI: __GUI_PROPS
-- __GUI = {}

-- --- @class __GUI_ED_PROPS: __GUI_PROPS
-- --- @field bgcol? integer
-- --- @field fgcol? integer
-- __GUI_ED_PROPS = {}

-- --- @class __GUI_ED: __GUI_ED_PROPS
-- __GUI_ED = {}

-- --- @param head_el? __GUI_PROPS
-- --- @return __GUI
-- --- Create a GUI
-- global create_gui: function(head_el: any) 

-- --- @class __GUI
-- --- Draws all GUI elements
-- global __GUI: function:draw_all: any() 

-- --- @class __GUI
-- --- Updates all GUI elements
-- global __GUI: function:update_all: any() 

-- --- @class __GUI
-- --- @param focus boolean
-- --- Sets keyboard focus
-- global __GUI: function:set_keyboard_focus: any(focus) 

-- --- @class __GUI
-- --- @param head_el __GUI_PROPS
-- --- @return __GUI
-- global __GUI: function:attach: any(head_el) 

-- --- @class __GUI
-- --- @param head_el? __GUI_ED_PROPS
-- --- @return __GUI_ED
-- --- Attaches a text editor to the GUI
-- global __GUI: function:attach_text_editor: any(head_el) 

-- --- @class __GUI_ED
-- --- @param text string
-- --- Set the text editor's current text
-- global __GUI_ED: function:set_text: any(text) 

-- --- @class __GUI_ED
-- --- @param column integer
-- --- @param line integer
-- --- Set the text editor's cursor position
-- global __GUI_ED: function:set_cursor: any(column, line) 

-- --- @class __GUI_ED
-- --- @return string[]
-- --- Set the text editor's current text
-- global __GUI_ED: function:get_text: any() 
