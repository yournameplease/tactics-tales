--- @meta

--- personal global helpers, not part of picotron

function todo(message)
	error("Function is not implemented!"..(message and " "..message or ""))
end

function unexpected(state)
	error("Received an unexpected state: "..(state and state or "nil"))
end
