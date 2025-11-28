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

util.mutCopy = table.clone :: <T>(tbl: T) -> typeforge.ReadWrite<T>

type function MergeTable(pack: type): type
	assert(pack:is("function"), "must be a function with a type pack parameter type")
	local headParam = pack:parameters().head
	assert(headParam and #headParam > 0, "requires valid types more than one")
	local result = headParam[1]
	for i = 2, #headParam do
		local t = headParam[i]
		assert(t:is("table"), "types must be tables")
		for prop, val in t:properties() do
			-- selene: allow(shadowing)
			local val = val.read or val.write
			assert(val, "field value must be valid")
			result:setproperty(prop, val)
		end
	end
	return result
end

function util.mergeTable<Target, Other>(target: Target, ...: Other): MergeTable<(Target, ...Other) -> ()>
	local tbl = table.clone(target)
	for _, src in { ... } do
		for k, v in src :: { [unknown]: unknown } do
			(tbl :: { [unknown]: unknown })[k] = v
		end
	end
	return tbl
end

return util
