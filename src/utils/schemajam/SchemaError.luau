local SchemaError = {}
local SchemaErrorMetatable = {  __index = SchemaError }
table.freeze(SchemaErrorMetatable)

type ErrorItem<T, E> = setmetatable<{ code: T, message: string } & E, typeof(SchemaErrorMetatable)>
export type SchemaError = ErrorItem<"invalidType", { expected: string, actual: string }>
	| ErrorItem<"custom", {}>

local function join<T0, T1>(tbl: T0, extra: T1): T0 & T1
	for k, v in extra :: { [unknown]: unknown } do
		(tbl :: { [unknown]: unknown })[k] = v
	end
	return tbl :: any
end

local function constructSchemaError<T, E>(code: T, message: string, extra: E): ErrorItem<T, E>
	return setmetatable(join({ code = code, message = message }, extra), SchemaErrorMetatable) :: any
end

type function ErrorItemOfTypeFn(t: type, union: type): type
	assert(union:is("union"), "SchemaError can only be constructed from a union type")
	for _, component in union:components() do
		assert(component:is("table"), "SchemaError union components must be table types")
		local codeType = component:readproperty(types.singleton("code"))
		if codeType == t then
			return component
		end
	end
	error("Type not found in SchemaError union")
end

type ErrorItemOf<T> = ErrorItemOfTypeFn<T, SchemaError>

return table.freeze({
	invalidType = function(): ErrorItemOf<"invalidType">
		return constructSchemaError("invalidType" :: "invalidType", "", { expected = "", actual = "" })
	end
})
