local base = require("./base")
local OptionalSchema = {}
local OptionalSchemaMetatable = { __index = OptionalSchema }
table.freeze(OptionalSchemaMetatable)

type OptionalSchema<T> = setmetatable<base.BaseSchemaFields<T?>, typeof(OptionalSchemaMetatable)>

local function constructOptionalSchema<T>(): OptionalSchema<T>
	return setmetatable({
		["_$t"] = nil :: any,
	}, OptionalSchemaMetatable)
end

return table.freeze({
	new = constructOptionalSchema,
})
