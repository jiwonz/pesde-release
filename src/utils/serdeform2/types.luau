local result = require("./result")

type Type<T> = {
	["@output"]: T,
	matches: (input: unknown) -> result.Result<T>,
}

local number: Type<number> = {
	matches = function(input)
		return result.success(2)
	end,
} :: any

export type function Infer(t: type): type
	assert(t:is("table"), "type must be a table")
	local prop = t:readproperty(types.singleton("@output"))
	assert(prop, "@output is not found")
	return prop
end

type function Struct(t: type): type
	assert(t:is("table"))
	local props = {}
	for prop, val in t:properties() do
		-- selene: allow(shadowing)
		local val = val.read or val.write
		assert(val, "")
		props[prop] = Infer(val)
	end
	return types.newtable(props)
end

type function Extends(t: type, extend: type): type
	assert(t:is("table") and extend:is("table"), "")
	local tProps = {}
	for prop, val in t:properties() do
		-- selene: allow(shadowing)
		local val = val.read or val.write
		assert(val, "")
		tProps[prop] = val
	end
	for prop, val in extend:properties() do
		-- selene: allow(shadowing)
		local val = val.read or val.write
		assert(val, "")
		tProps[prop] = val
	end
	return types.newtable(tProps)
end

local struct = function<T>(shape: T): Extends<Type<Struct<T>>, { fromToml: () -> Struct<T> }>
	return {
		matches = function(input)
			return result.success(nil :: any)
		end,
	} :: any
end

local s = struct {
	a = number,
	b = struct {
		b = number,
	}
}

return {
	number = number,
	struct = struct,
}
