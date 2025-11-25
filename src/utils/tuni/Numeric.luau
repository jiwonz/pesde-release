local Numeric = {}
local NumericMetatable = { __index = Numeric }
table.freeze(NumericMetatable)

type function NewTypeId(): type
	local function uuid(): string
		local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
		local s = string.gsub(template, "[xy]", function(c)
			local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
			return string.format("%x", v)
		end)
		return s
	end
	return types.singleton("_$tuni.Numeric@" .. uuid())
end

export type SelfTypeId = NewTypeId<>

export type Numeric = setmetatable<{ [SelfTypeId]: true, n: number? }, typeof(NumericMetatable)>

local singletonInstance: Numeric?
local function constructNumeric(n: number?): Numeric
	local isSingleton = n == nil
	if isSingleton and singletonInstance then
		return singletonInstance
	end
	local new = setmetatable({ n = n }, NumericMetatable)
	if isSingleton then
		singletonInstance = new
	end
	return new
end

local function isNumeric(value: unknown): boolean
	return type(value) == "table" and getmetatable(value) == NumericMetatable
end

table.freeze(Numeric)

return table.freeze({
	new = constructNumeric,
	is = isNumeric,
})
