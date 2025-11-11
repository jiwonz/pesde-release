-- 클래스 상속 방식 (근데 struct에서 너무 지저분해짐)

local result = require("@self/result")

local Type = {}
local TypeMt = { __index = Type }

function Type.new<T>(baseType: string?): Type<T>
	return setmetatable({ baseType = baseType, _T = nil :: T }, TypeMt)
end

function Type.parse<T>(self: Type<T>, input: unknown): result.Result<T>
	if not self.baseType then
		error("baseType is not defined")
	end
	local t = typeof(input)
	if t == self.baseType then
		return result.success(input)
	else
		return result.fail(`expected {self.baseType}, got {t}`)
	end
end

function Type.buildParser<T>(self: Type<T>): (input: unknown) -> result.Result<T>
	return function(input: unknown): result.Result<T>
		return self:parse(input)
	end
end

type Type<T = any> = setmetatable<{ baseType: string?, _T: T }, typeof(TypeMt)>

local NumberType = setmetatable({}, TypeMt)
local NumberTypeMt = { __index = NumberType }

function NumberType.new(): NumberType
	return setmetatable(Type.new("number") :: Type<number>, NumberTypeMt) :: any
end

type NumberType = setmetatable<Type<number>, typeof(NumberTypeMt)> & Type<number>

local StringType = setmetatable({}, TypeMt)
local StringTypeMt = { __index = StringType }

function StringType.new(): StringType
	return setmetatable(Type.new("string") :: Type<string>, StringTypeMt) :: any
end

type StringType = setmetatable<Type<string>, typeof(StringTypeMt)> & Type<string>

local StructType = setmetatable({}, TypeMt)
local StructTypeMt = { __index = StructType }

type StructTypeFields = Type<{ [string]: any }> & { num: number }

function StructType.new(shape: { [string]: Type<any> }): StructType
	local new = Type.new("table") :: StructTypeFields
	new.num = 42
	return setmetatable(new, StructTypeMt) :: any
end

function StructType.test(self: StructType)
	print(self.baseType)
end

type StructType = setmetatable<StructTypeFields, typeof(StructTypeMt)> & Type<{ [string]: any }>

local st = StringType.new()
st:buildParser()
