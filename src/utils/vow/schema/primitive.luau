local Result = require("../../Result")
local BaseSchema = require("./Base")
local PrimitiveSchema = {}
local PrimitiveSchemaMetatable = table.freeze({ __index = PrimitiveSchema })

type Result<T> = Result.Result<T>
type BaseSchema<T> = BaseSchema.BaseSchema<T>

type function TypeToString(type: type): type
	return types.singleton(type.tag)
end

type PrimitiveSchemaFrom<T, E = {}> = setmetatable<{
	read base: BaseSchema.BaseSchema<T>,
	read primitiveType: TypeToString<T>,
} & E, typeof(PrimitiveSchemaMetatable)>
type NumberSchema = PrimitiveSchemaFrom<number, {
	read coerce: boolean,
}>
type StringSchema = PrimitiveSchemaFrom<string, {
	read coerce: boolean,
}>
type BooleanSchema = PrimitiveSchemaFrom<boolean, {
	read coerce: boolean,
}>
type TableSchema = PrimitiveSchemaFrom<{ [any]: any }>
type NoneSchema = PrimitiveSchemaFrom<nil>
export type PrimitiveSchema = NumberSchema
	| StringSchema
	| BooleanSchema
	| TableSchema
	| NoneSchema

-- local primitiveSchemaBuilder = {}
-- do
-- 	type function MakeBuilder(primitiveTypeType: type): type
-- 		assert(primitiveTypeType:is("union"))
-- 		local intersections: { type } = {}
-- 		for _, component in primitiveTypeType:components() do
-- 			local primitiveType = component:readproperty(types.singleton("primitiveType"))
-- 			assert(primitiveType, "component does not have property 'primitiveType'")
-- 			table.insert(intersections, types.newfunction({
-- 				head = { primitiveType }
-- 			}, {
-- 				head = { component }
-- 			}))
-- 		end
-- 		return types.intersectionof(table.unpack(intersections))
-- 	end

-- 	local function build(primitiveType: string): PrimitiveSchema
-- 		return setmetatable({
-- 			["_$t"] = nil :: any,
-- 			primitiveType = primitiveType,
-- 		}, PrimitiveTypeMetatable) :: any
-- 	end

-- 	primitiveSchemaBuilder.build = build :: MakeBuilder<PrimitiveSchema>
-- end

-- TODO
local numberErrors = {
	parse = "Expected number",
	required = "Number is required",
}

function PrimitiveSchema.number(options: { coerce: boolean }?): NumberSchema
	return table.freeze(setmetatable({
		base = BaseSchema.new() :: BaseSchema<number>,
		primitiveType = "number" :: "number",
		coerce = options and options.coerce or false,
	}, PrimitiveSchemaMetatable))
end

function PrimitiveSchema.string(options: { coerce: boolean }?): StringSchema
	return table.freeze(setmetatable({
		base = BaseSchema.new() :: BaseSchema<string>,
		primitiveType = "string" :: "string",
		coerce = options and options.coerce or false,
	}, PrimitiveSchemaMetatable))
end

function PrimitiveSchema.boolean(options: { coerce: boolean }?): BooleanSchema
	return table.freeze(setmetatable({
		base = BaseSchema.new() :: BaseSchema<boolean>,
		primitiveType = "boolean" :: "boolean",
		coerce = options and options.coerce or false,
	}, PrimitiveSchemaMetatable))
end

function PrimitiveSchema.table(): TableSchema
	return table.freeze(setmetatable({
		base = BaseSchema.new() :: BaseSchema<{ [any]: any }>,
		primitiveType = "table" :: "table",
	}, PrimitiveSchemaMetatable))
end

function PrimitiveSchema.none(): NoneSchema
	return table.freeze(setmetatable({
		base = BaseSchema.new() :: BaseSchema<nil>,
		primitiveType = "nil" :: "nil",
	}, PrimitiveSchemaMetatable))
end

do
	type OverloadParse<T> = (self: T, input: unknown) -> Result<index<index<T, "base">, "_$t">>

	local function parse(self: PrimitiveSchema, input: unknown): Result<any>
		if self.primitiveType == "number" then
			if type(input) == "number" then
				return Result.ok(input)
			end
			return Result.err(`Expected number, got {tostring(input)}`) -- TODO: use custom error object
		elseif self.primitiveType == "string" then
			if type(input) == "string" then
				return Result.ok(input)
			end
			return Result.err(`Expected string, got {tostring(input)}`) -- TODO: use custom error object
		elseif self.primitiveType == "boolean" then
			if type(input) == "boolean" then
				return Result.ok(input)
			end
			return Result.err(`Expected boolean, got {tostring(input)}`) -- TODO: use custom error object
		elseif self.primitiveType == "table" then
			if type(input) == "table" then
				return Result.ok(input)
			end
			return Result.err(`Expected table, got {tostring(input)}`) -- TODO: use custom error object
		elseif self.primitiveType == "nil" then
			if input == nil then
				return Result.ok(input)
			end
			return Result.err(`Expected nil, got {tostring(input)}`) -- TODO: use custom error object
		end
		error("unreachable")
	end
	PrimitiveSchema.parse = parse :: OverloadParse<NumberSchema>
		& OverloadParse<StringSchema>
		& OverloadParse<BooleanSchema>
end

table.freeze(PrimitiveSchema)

return PrimitiveSchema
