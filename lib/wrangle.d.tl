--- @meta

--- Manage working with a file
--- save_state is a function that returns the content and metadata of the file to save. Called when the "save_file" event is fired
--- load_state is a function that takes the content and metadata of the file as parameters. Called when the "open_file" event is fired
--- untitled filename is the file name to use by default
--- get_hlocation is a function that gets the location in the file
--- set_hlocation is a function that sets the location in the file
--- View implementation in /system/lib/wrangle.lua
--- @param save_state? function
--- @param load_state? function
--- @param untitled_filename? string
--- @param get_hlocation? function
--- @param set_hlocation? function
global wrangle_working_file: function(save_state: any, load_state: any, untitled_filename: string, get_hlocation: any, set_hlocation: any) 

--- Gets the present working file. Used with wrangle_working_file
--- View implementation in /system/lib/wrangle.lua
--- @return string | nil
global pwf: function() : string | nil 
