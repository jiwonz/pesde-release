local Numeric = require("@self/Numeric")

local tuni = {}
tuni.value = table.freeze({}) :: unknown

function tuni.numeric(n: number?): Numeric.Numeric
	return Numeric.new(n)
end

type function NewTypeId(): type
	local function uuid(): string
		local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
		local s = string.gsub(template, "[xy]", function(c)
			local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
			return string.format("%x", v)
		end)
		return s
	end
	return types.singleton("_$tuni.Self@" .. uuid())
end

type function NewNumericBrand(): type
	local function uuid(): string
		local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
		local s = string.gsub(template, "[xy]", function(c)
			local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
			return string.format("%x", v)
		end)
		return s
	end
	return types.singleton("_$tuni.numeric.brand@" .. uuid())
end

export type SelfTypeId = NewTypeId<>

export type self = { [SelfTypeId]: true }

--[=[ idea:

local SchemaError = tuni.enum("tag" :: "tag", {
	numeric = tuni.numeric(1),
	arrayErrors = { index = tuni.value :: number, error = tuni.value :: tuni.self },
	arrayErrors = tuni.value :: { index: number, error: typeof(tuni.self) },
})

TODO: add runtime type checkers?
TODO: needs to think about how to separate tuni.value and table values (or you might just give up the table validation)

tuni means "tagged union"

]=]

type function EnumTypeFn(tag: type, t: type): type
	assert(tag:is("singleton"), "tuni.enum tag must be a singleton type")
	assert(t:is("table"), "tuni.enum argument must be a table")
	local enumItems: { type } = {}

end

function tuni.enum<T, E>(tag: T, enum: E): EnumTypeFn<T, E>
	if type(enum) ~= "table" then
		error("tuni.enum argument must be a table")
	end
	local lastNumeric = 0
	local numericSet: { [number]: true } = {}
	local enumItems: { [string]: ((unknown) -> { [T]: string, value: unknown } | ({ [T]: string } & { [string]: unknown })) | number } = {}
	for key, value in enum :: { [unknown]: unknown } do
		if type(key) ~= "string" then
			error("Enum keys must be strings")
		end
		if value == tuni.value then
			enumItems[key] = function(v: unknown)
				return { [tag] = tag, value = v }
			end
		elseif type(value) == "table" then
			local fieldKeys: { string } = {}
			for fieldKey, _ in value :: { [unknown]: unknown } do
				if type(fieldKey) ~= "string" then
					error("Enum field keys must be strings")
				end
				table.insert(fieldKeys, fieldKey)
			end
			enumItems[key] = function(tbl: unknown)
				if type(tbl) ~= "table" then
					error("Enum constructor '" .. key .. "' requires a table argument")
				end
				for _, fieldKey in fieldKeys do
					if (tbl :: { [unknown]: unknown })[fieldKey] == nil then
						error("Missing field '" .. fieldKey .. "' for enum constructor '" .. key .. "'")
					end
				end
				local result = { [tag] = key }
				for _, fieldKey in fieldKeys do
					result[fieldKey] = (tbl :: { [unknown]: unknown })[fieldKey] :: any
				end
				return result
			end
		elseif Numeric.is(value) then
			-- selene: allow(shadowing)
			local value = value :: Numeric.Numeric
			local n = value.n or lastNumeric + 1
			while numericSet[n] do
				n += 1
			end
			numericSet[n] = true
			lastNumeric = n
			enumItems[key] = n :: number
		else
			error(`Enum values must be tuni.value, tables, or Numeric. got {typeof(value)}`)
		end
	end
	return table.freeze(enumItems) :: any
end

return table.freeze(tuni)
