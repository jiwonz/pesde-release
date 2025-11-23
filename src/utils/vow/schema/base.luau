local BaseSchema = {}
local BaseSchemaMetatable = table.freeze({ __index = BaseSchema })

export type BaseSchema<T> = setmetatable<{
	read ["_$t"]: T,
	read customErrors: {
		parse: string?,
		required: string?,
	},
	read sourceKey: string?,
	read customSerDes: {
		encode: ((value: T) -> string)?,
		decode: ((encoded: string) -> T)?,
	},
}, typeof(BaseSchemaMetatable)>

local function constructBaseSchema(): BaseSchema<unknown>
	return setmetatable({
		["_$t"] = nil :: any,
		customErrors = {
			parse = nil :: string?,
			required = nil :: string?,
		},
		sourceKey = nil :: string?,
		customSerDes = {
			encode = nil :: ((value: any) -> string)?,
			decode = nil :: ((encoded: string) -> any)?,
		},
	}, BaseSchemaMetatable)
end

table.freeze(BaseSchema)

return table.freeze({
	new = constructBaseSchema,
})
