local todebugstring = require("../todebugstring")
local commonTypes = require("./commonTypes")

type Reason = commonTypes.Reason

local Error = {}
local ErrorMetatable = {
	__index = Error,
	__tostring = function(self: Error): string
		return self:toString()
	end
}
table.freeze(ErrorMetatable)

export type Error = setmetatable<{
	read reason: Reason,
	read source: Error?
}, typeof(ErrorMetatable)>

--- Checks if a value is an Error
local function isError(value: unknown): boolean
	return type(value) == "table" and getmetatable(value) == ErrorMetatable
end

--- Constructs a new Error
local function constructError(reason: Error | Reason, source: (Error | Reason)?): Error
	local processedSource: Error? = nil
	if source then
		-- If source is already a Error, use it as-is. Otherwise wrap it.
		if isError(source) then
			processedSource = source :: Error
		else
			processedSource = constructError(source)
		end
	end

	return setmetatable({
		reason = reason,
		source = processedSource,
	}, ErrorMetatable)
end

--- Converts the Error to a string representation
function Error.toString(self: Error): string
	if not self.source then
		return todebugstring(self.reason)
	end
	return `{todebugstring(self:rootCause().reason)}: {todebugstring(self.reason)}`
end

--- Converts the Error to a detailed debug string representation
function Error.toDebugString(self: Error): string
	local lines: { string } = {}
	table.insert(lines, "Error: " .. todebugstring(self:rootCause().reason))

	if not self.source then
		return lines[1]
	end

	table.insert(lines, "\nCaused by:")
	local current: Error? = self
	local root = self:rootCause()

	-- Collect contexts from self to root (excluding root)
	local contexts: { string } = {}
	while current and current ~= root do
		table.insert(contexts, todebugstring(current.reason))
		current = current.source
	end

	-- Print in reverse order (oldest context first)
	for i = #contexts, 1, -1 do
		table.insert(lines, "\t" .. contexts[i])
	end

	return table.concat(lines, "\n")
end

--- Returns the chain of Errors from this Error to the root cause
function Error.chain(self: Error): { Error }
	local chain: { Error } = {}
	local current: Error? = self
	while current do
		table.insert(chain, current)
		current = current.source
	end
	return chain
end

--- Returns the root cause Error in the chain
function Error.rootCause(self: Error): Error
	local current: Error = self
	while current.source do
		current = current.source
	end
	return current
end

--- Error Class
return table.freeze({
	is = isError,
	new = constructError,
})
