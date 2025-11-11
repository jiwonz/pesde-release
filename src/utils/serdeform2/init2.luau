local result = require("./result")
-- 러스트 trait 방식

type Type<T = any> = {
	parse: (self: any, input: unknown) -> result.Result<T>,
}

type function ImplTrait(t: type, trait: type): type
	assert(t:is("table") and trait:is("table"), "type and trait must be tables")
	local tProps = {}
	for prop, val in trait:properties() do
		-- selene: allow(shadowing)
		local val = val.read or val.write
		assert(val, "")
		tProps[prop] = val
	end
	return types.newtable(tProps)
end

local NumberType = {}

--[=[

local AnimalTrait = trait<<{
	noise: () -> string,
}>>()

type Dog = Struct<{
	name: string,
}>
local Dog = struct<<Dog>>()

local DogImpl = {}

function DogImpl.new(name: string): Dog
	return {
		name = name,
	}
end

Dog:impl(DogImpl)

function DogImpl.name(self: )
	return "Fido"
end

AnimalTrait:impl(Dog, {
	noise = function(self)
		return "bark"
	end,
})

]=]

--[=[

-- this is struct and impl equivalent in rust

local Dog = {}
local DogMt = { __index = Dog }

function Dog.new(name: string) -- impl
	return setmetatable({ name = name }, DogMt)
end

type Dog = setmetatable<{ name: string }, typeof(DogMt)> -- struct

]=]

--[=[

-- so how can we apply trait like behavior?

local Animal = trait<<{
	noise: () -> string,
}>>()

local Dog = {}
local DogMt = { __index = Dog }

function Dog.new(name: string)
	return setmetatable({ name = name }, DogMt)
end

type Dog = setmetatable<{ name: string }, typeof(DogMt)>

Animal:impl(Dog, {
	noise = function(self)
		return "bark"
	end,
})

]=]

--[=[

-- another attempt for more type-safe way

local DogImpl = {}
local Dog: Impl<typeof(DogImpl), trait> = {}
local DogMt = { __index = Dog }

function DogImpl.new(name: string)
	return setmetatable({ name = name }, DogMt)
end

type Dog = setmetatable<{ name: string }, typeof(DogMt)>

]=]

function NumberType.parse(self: typeof(NumberType), input: unknown): result.Result<number>
	if type(input) == "number" then
		return result.success(input)
	else
		return result.fail("expected number")
	end

end

local function number()
	local mt: ImplTrait<typeof(NumberType), Type<number>> = NumberType
	return setmetatable({}, mt)
end
