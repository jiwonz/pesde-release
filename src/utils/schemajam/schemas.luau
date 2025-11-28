local Result = require("../Result")
local oneof = require("../oneof")
local typeforge = require("../typeforge")
local util = require("./util")

-- TODO: is it necessary? should we move and expose them in init.luau?
local schemas = {}

type Infer<T> = index<index<T, "_$sj">, "output">
type Input<T> = index<index<T, "_$sj">, "input">
type Def<T> = index<T, "def">
type Partial<T> = typeforge.Partial<T>
type ReadOnly<T> = typeforge.ReadOnly<T>
type Without<T, K...> = util.Without<T, K...>
type NonNullable<T> = util.NonNullable<T>
type PublicOnly<T> = util.PublicOnly<T>
type OptionalDef<T> = Partial<PublicOnly<Def<T>>>?
type OptionalDefWithout<T, K...> = Without<Partial<PublicOnly<Def<T>>>, K...>?
type ReadWrite<T> = typeforge.ReadWrite<T>
type OptionalDefDefinition<T, D> = ReadWrite<Partial<NonNullable<index<Def<T>, D>>>>
type Result<T> = Result.Result<T, SchemaError>

-- #region SchemaError
type SchemaError =
	| oneof.Variant<"invalidType", { expected: string, actual: string }>
	| oneof.Variant<"custom", {}>

-- #endregion

-- #region BaseSchema

type BaseSchemaFields<O, D, I = O> = {
	read ["_$sj"]: {
		read input: I,
		read output: O,
	},
	read def: D,
	read sourceKey: string?,
	read customMessages: { [oneof.TagOf<SchemaError>]: string? }?,
}

local function createBaseSchemaFields<T>(def: T): BaseSchemaFields<any, T>
	assert(table.isfrozen(def), "Schema definition tables must be frozen")
	return {
		["_$sj"] = nil :: any,
		def = def,
	}
end

type BaseImpl<T> = {
	optional: (self: T) -> OptionalSchema<T>,
	at: (self: T, key: string) -> AtSchema<T>,
	refine: (self: T, func: (input: Input<T>) -> boolean) -> SchemaEffects<T>,
	transform: (self: T, func: (input: Input<T>) -> Infer<T>) -> SchemaEffects<T>,
	preprocess: (self: T, func: (input: unknown) -> Input<T>) -> SchemaEffects<T>,
	messages: (self: T, newCustomMessages: index<T, "customMessages">) -> T,
}

local defaultBaseImpl = {} :: BaseImpl<DefaultSchema>

type DefaultSchema = setmetatable<BaseSchemaFields<any, any>, typeof(defaultBaseImpl)>

function defaultBaseImpl.optional(self)
	return schemas.optional(self)
end

function defaultBaseImpl.at(self, key)
	return schemas.at(self, key)
end

function defaultBaseImpl.refine(self, func)
	error("Not implemented yet")
end

function defaultBaseImpl.transform(self, func)
	error("Not implemented yet")
end

function defaultBaseImpl.preprocess(self, func)
	error("Not implemented yet")
end

function defaultBaseImpl.messages(self, newCustomMessages)
	local new = util.mutCopy(self)
	new.customMessages = util.mergeTable(new.customMessages or {} :: index<DefaultSchema, "customMessages">, newCustomMessages)
	table.freeze(new)
	return new
end

table.freeze(defaultBaseImpl)

-- #endregion

-- #region NumberSchema

local NumberSchema = {}
local NumberSchemaMetatable = { __index = NumberSchema }
table.freeze(NumberSchemaMetatable)

type NumberSchema<I = number> = setmetatable<
	BaseSchemaFields<number, ReadOnly<{
		_coerce: boolean,
		int: boolean,
		range: ReadOnly<{
			min: number?,
			minMessage: string?,
			minInclusive: boolean,
			max: number?,
			maxMessage: string?,
			maxInclusive: boolean,
		}>?,
		nan: boolean,
	}>, I>,
	typeof(NumberSchemaMetatable)
>

local function constructNumberSchema(def: Def<NumberSchema>): NumberSchema
	assert(table.isfrozen(def :: any), "Schema definition tables must be frozen")
	return table.freeze(setmetatable(createBaseSchemaFields(def), NumberSchemaMetatable))
end

function NumberSchema.parse(self: NumberSchema, input: unknown): Result<number>
	error("Not implemented yet")
	-- error e.g. Result.err({ msgType = "expected_number", actual = typeof(input) })
end

do
	local interned: NumberSchema?
	do
		function schemas.number(def: OptionalDef<NumberSchema>): NumberSchema
			local internable = def == nil
			if internable and interned then
				return interned
			end
			local new: NumberSchema = constructNumberSchema(table.freeze({
				_coerce = false,
				int = def and def.int or false,
				range = def and def.range or nil,
				nan = def and def.nan or false,
			}))
			if internable then
				interned = new
			end
			return new
		end
	end

	do
		local internedOptional: OptionalSchema<NumberSchema>?
		function NumberSchema.optional(self: NumberSchema): OptionalSchema<NumberSchema>
			local internable = self == interned
			if internable and internedOptional then
				return internedOptional
			end
			local new = schemas.optional(self)
			if internable then
				internedOptional = new
			end
			return new
		end
	end

	do
		local internedInt: NumberSchema?
		function NumberSchema.int(self: NumberSchema): NumberSchema
			local internable = self == interned
			if internable and internedInt then
				return internedInt
			end
			local newDef = util.mutCopy(self.def)
			newDef.int = true
			local new: NumberSchema = constructNumberSchema(table.freeze(newDef))
			if internable then
				internedInt = new
			end
			return new
		end

		function schemas.int(def: OptionalDefWithout<NumberSchema, "int">): NumberSchema
			local internable = def == nil
			if internable and internedInt then
				return internedInt
			end
			local new: NumberSchema = setmetatable(createBaseSchemaFields(table.freeze({
				_coerce = false,
				int = true,
				range = def and def.range or nil,
				nan = def and def.nan or false,
			})), NumberSchemaMetatable)
			if internable then
				internedInt = new
			end
			return new
		end
	end
end

function NumberSchema.range(
	self: NumberSchema,
	range: OptionalDefDefinition<NumberSchema, "range">
): NumberSchema
	local newDef = util.mutCopy(self.def)
	newDef.range = {
		min = range and range.min or nil,
		minInclusive = range and range.minInclusive or false,
		max = range and range.max or nil,
		maxInclusive = range and range.maxInclusive or false,
	}
	return constructNumberSchema(table.freeze(newDef))
end

function NumberSchema.coerce(self: NumberSchema): NumberSchema<unknown>
	local newDef = util.mutCopy(self.def)
	newDef._coerce = true
	return constructNumberSchema(table.freeze(newDef))
end

function NumberSchema.nan(self: NumberSchema): NumberSchema
	local newDef = util.mutCopy(self.def)
	newDef.nan = true
	return constructNumberSchema(table.freeze(newDef))
end

function NumberSchema.positive(self: NumberSchema): NumberSchema
	local newDef = util.mutCopy(self.def)
	newDef.sign = 1
	return schemas.number(newDef)
end

NumberSchema.nonnegative = NumberSchema.positive

function NumberSchema.negative(self: NumberSchema): NumberSchema
	local newDef = util.mutCopy(self.def)
	newDef.sign = -1
	return schemas.number(newDef)
end

NumberSchema.nonpositive = NumberSchema.negative

do
	local baseImpl = defaultBaseImpl :: BaseImpl<NumberSchema>
	NumberSchema.at = baseImpl.at
	NumberSchema.refine = baseImpl.refine
	NumberSchema.transform = baseImpl.transform
	NumberSchema.preprocess = baseImpl.preprocess
end

-- #endregion

-- #region OptionalSchema

local OptionalSchema = {}
local OptionalSchemaMetatable = { __index = OptionalSchema }
table.freeze(OptionalSchemaMetatable)

type OptionalSchema<T> = setmetatable<
	BaseSchemaFields<Infer<T>?, {
		read inner: T,
	}>,
	typeof(OptionalSchemaMetatable)
>

function schemas.optional<T>(schema: T): OptionalSchema<T>
	return setmetatable(createBaseSchemaFields(table.freeze({
		inner = schema,
	})), OptionalSchemaMetatable)
end

do
	local baseImpl = defaultBaseImpl :: BaseImpl<OptionalSchema<any>>
	OptionalSchema.optional = baseImpl.optional
end

-- #endregion

-- #region AtSchema
local AtSchema = {}
local AtSchemaMetatable = { __index = AtSchema }
table.freeze(AtSchemaMetatable)

type AtSchema<T> = setmetatable<
	BaseSchemaFields<Infer<T>, {
		read inner: T,
		read sourceKey: string,
	}>,
	typeof(AtSchemaMetatable)
>

function schemas.at<T>(schema: T, sourceKey: string): AtSchema<T>
	return setmetatable(createBaseSchemaFields(table.freeze({
		inner = schema,
		sourceKey = sourceKey,
	})), AtSchemaMetatable)
end

do
	local baseImpl = defaultBaseImpl :: BaseImpl<AtSchema<any>>
	AtSchema.optional = baseImpl.optional
	AtSchema.at = baseImpl.at
	AtSchema.refine = baseImpl.refine
	AtSchema.transform = baseImpl.transform
	AtSchema.preprocess = baseImpl.preprocess
end

-- #endregion

-- #region SchemaEffects
local SchemaEffects = {}
local SchemaEffectsMetatable = { __index = SchemaEffects }
table.freeze(SchemaEffectsMetatable)

type SchemaEffects<T> = setmetatable<
	BaseSchemaFields<Infer<T>, {
		inner: T,
	}>,
	typeof(SchemaEffectsMetatable)
>

-- #endregion

return schemas
