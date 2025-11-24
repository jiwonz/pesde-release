local base = require("./base")

local NumberSchema = {}
local NumberSchemaMetatable = { __index = NumberSchema }
table.freeze(NumberSchemaMetatable)

type NumberSchema = setmetatable<base.BaseSchemaFields<number>, typeof(NumberSchemaMetatable)>

local defaultImpl = base.defaultImpl :: base.BaseImpl<NumberSchema>
NumberSchema.optional = defaultImpl.optional

local function constructNumberSchema(): NumberSchema
	return setmetatable({
		["_$t"] = nil :: any,
	}, NumberSchemaMetatable)
end

function NumberSchema.int(_self: NumberSchema): NumberSchema
	error("Not implemented yet")
end

local a = constructNumberSchema()
local g = a:int()
local x = g:optional()

return table.freeze({
	new = constructNumberSchema,
})
