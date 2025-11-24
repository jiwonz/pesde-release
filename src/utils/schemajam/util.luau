local typeforge = require("../typeforge")

export type function WithoutTypeFn(t: type, excludedKeyPack: type): type
	assert(excludedKeyPack:is("function"), "must be a function with a type pack")
	local excludedKeys = excludedKeyPack:parameters().head
	assert(excludedKeys, "excluded keys must be valid")
	for _, excludedKey in excludedKeys do
		t:setproperty(excludedKey, nil)
	end
	return t
end

export type Without<T, K...> = WithoutTypeFn<T, (K...) -> ()>

export type function PublicOnly(t: type): type
	assert(t:is("table"), "must be a table type")
	for prop, _ in t:properties() do
		if type(prop:value()) == "string" then
			local propName = prop:value() :: string
			if propName:sub(1, 1) == "_" then
				t:setproperty(prop, nil)
			end
		end
	end
	return t
end

export type function NonNullable(t: type): type
	assert(t:is("union"), "must be a union type")
	for _, component in t:components() do
		if not component:is("nil") then
			return component
		end
	end
	error("no non-nil component found")
end

local util = {}

util.copyUnfrozen = table.clone :: <T>(tbl: T) -> typeforge.ReadWrite<T>

return util
