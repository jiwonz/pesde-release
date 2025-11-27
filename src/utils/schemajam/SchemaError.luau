local oneof = require("../oneof")

local SchemaError = {}
local SchemaErrorMetatable = {
	__index = SchemaError,
	__tostring = function(self: SchemaError): string
		return self:toString()
	end
}
table.freeze(SchemaErrorMetatable)

type BaseError = { message: string }
export type SchemaError = setmetatable<
	oneof.Variant<"invalidType", { message: string, expected: string, actual: string }>
	| oneof.Variant<"custom", {} & BaseError>,
typeof(SchemaErrorMetatable)>

function SchemaError.toString(self: SchemaError): string
	if self.tag == "invalidType" then
		return string.format(self.message, self.expected, self.actual)
	end
	return ""
end

return oneof(SchemaErrorMetatable) :: oneof.OneOf<SchemaError>
