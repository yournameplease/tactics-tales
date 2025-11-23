
Debug = {}

-- why no work?
function Debug.log(...)
    local str = ""
    for i=1,arg.n-1 do
        str = str .. arg[i] .. " , "
    end
    str = str .. arg[arg.n]
    printh("LOG: " .. str)
end

return Debug