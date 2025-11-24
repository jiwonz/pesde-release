local Result = require("../Result")
local typeforge = require("../typeforge")
local util = require("./util")
local schemas = {}

-- #region BaseSchema

-- TODO: WIP! idk with this structure. needs to think about it more. or maybe do like zod's issues method
type SchemaError = {
	read parse: string,
	read required: string,
}

type BaseSchemaFields<I, O, D> = {
	read ["_$sj"]: {
		read input: I,
		read output: O,
	},
	read def: D,
	read schemaError: SchemaError,
}

type GetPhantom<T> = index<T, "_$sj">
type Infer<T> = index<GetPhantom<T>, "output">
type Input<T> = index<GetPhantom<T>, "input">
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
type Result<T> = Result.Result<T>

local function withDefaultBaseSchemaFields<T>(def: T, schemaError: SchemaError): {
	["_$sj"]: {
		input: any,
		output: any,
	},
	def: T,
	sourceKey: string?,
	schemaError: SchemaError,
}
	return {
		["_$sj"] = nil :: any,
		def = table.freeze(def :: any),
		schemaError = schemaError,
	}
end

type BaseImpl<T> = {
	optional: (self: T) -> OptionalSchema<T>,
	at: (self: T, key: string) -> PointerSchema<T>,
	refine: (self: T, func: (input: Input<T>) -> boolean) -> T,
	transform: (self: T, func: (input: Input<T>) -> Infer<T>) -> T,
	preprocess: (self: T, func: (input: unknown) -> Input<T>) -> T,
}

local defaultBaseImpl = {} :: BaseImpl<DefaultSchema>

type DefaultSchema = setmetatable<BaseSchemaFields<any, any, any>, typeof(defaultBaseImpl)>

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

table.freeze(defaultBaseImpl)

-- #endregion

-- #region NumberSchema

local NumberSchema = {}
local NumberSchemaMetatable = { __index = NumberSchema }
table.freeze(NumberSchemaMetatable)

type NumberSchema<I = number> = setmetatable<
	BaseSchemaFields<I, number, ReadOnly<{
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
		allowNaN: boolean,
	}>>,
	typeof(NumberSchemaMetatable)
>

function NumberSchema.parse(self: NumberSchema, input: unknown): Result<number>
	error("Not implemented yet")
end

do
	local interned: NumberSchema?
	function schemas.number(def: OptionalDef<NumberSchema>): NumberSchema
		local internable = def == nil
		if internable and interned then
			return interned
		end
		local new: NumberSchema = setmetatable(withDefaultBaseSchemaFields({
			_coerce = false,
			int = def and def.int or false,
			range = def and def.range or nil,
			allowNaN = def and def.allowNaN or false,
		}), NumberSchemaMetatable)
		table.freeze(new)
		if internable then
			interned = new
		end
		return new
	end

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

	local internedInt: NumberSchema?
	function NumberSchema.int(self: NumberSchema): NumberSchema
		local internable = self == interned
		if internable and internedInt then
			return internedInt
		end
		local newDef = util.copyUnfrozen(self.def)
		newDef.int = true
		local new = schemas.number(newDef)
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
		local new: NumberSchema = setmetatable(withDefaultBaseSchemaFields({
			_coerce = false,
			int = true,
			range = def and def.range or nil,
			allowNaN = def and def.allowNaN or false,
		}), NumberSchemaMetatable)
		table.freeze(new)
		if internable then
			internedInt = new
		end
		return new
	end
end

function NumberSchema.range(
	self: NumberSchema,
	range: OptionalDefDefinition<NumberSchema, "range">
): NumberSchema
	local newDef = util.copyUnfrozen(self.def)
	newDef.range = {
		min = range and range.min or nil,
		minInclusive = range and range.minInclusive or false,
		max = range and range.max or nil,
		maxInclusive = range and range.maxInclusive or false,
	}
	return schemas.number(newDef)
end

function NumberSchema.coerce(self: NumberSchema): NumberSchema<unknown>
	local newDef = util.copyUnfrozen(self.def)
	newDef._coerce = true
	return schemas.number(newDef)
end

function NumberSchema.allowNaN(self: NumberSchema): NumberSchema
	local newDef = util.copyUnfrozen(self.def)
	newDef.allowNaN = true
	return schemas.number(newDef)
end

function NumberSchema.positive(self: NumberSchema): NumberSchema
	local newDef = util.copyUnfrozen(self.def)
	newDef.sign = 1
	return schemas.number(newDef)
end

NumberSchema.nonnegative = NumberSchema.positive

function NumberSchema.negative(self: NumberSchema): NumberSchema
	local newDef = util.copyUnfrozen(self.def)
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

-- #region StringSchema

local StringSchema = {}
local StringSchemaMetatable = { __index = StringSchema }
table.freeze(StringSchemaMetatable)

type StringSchema = setmetatable<BaseSchemaFields<string, string, {}>, typeof(StringSchemaMetatable)>

function schemas.string(): StringSchema
	return setmetatable(withDefaultBaseSchemaFields({}), StringSchemaMetatable)
end

function StringSchema.maxLength(_self: StringSchema, _length: number): StringSchema
	error("Not implemented yet")
end

do
	local baseImpl = defaultBaseImpl :: BaseImpl<StringSchema>
	StringSchema.optional = baseImpl.optional
	StringSchema.at = baseImpl.at
	StringSchema.refine = baseImpl.refine
	StringSchema.transform = baseImpl.transform
	StringSchema.preprocess = baseImpl.preprocess
end

-- #endregion

-- #region OptionalSchema

local OptionalSchema = {}
local OptionalSchemaMetatable = { __index = OptionalSchema }
table.freeze(OptionalSchemaMetatable)

type OptionalSchema<T> = setmetatable<
	BaseSchemaFields<Infer<T>?, Infer<T>?, {
		innerSchema: T,
	}>,
	typeof(OptionalSchemaMetatable)
>

function schemas.optional<T>(innerSchema: T): OptionalSchema<T>
	return setmetatable(withDefaultBaseSchemaFields({
		innerSchema = innerSchema,
	}), OptionalSchemaMetatable)
end

do
	local baseImpl = defaultBaseImpl :: BaseImpl<OptionalSchema<any>>
	OptionalSchema.optional = baseImpl.optional
end

-- #endregion

-- #region PointerSchema
local PointerSchema = {}
local PointerSchemaMetatable = { __index = PointerSchema }
table.freeze(PointerSchemaMetatable)

type PointerSchema<T> = setmetatable<
	BaseSchemaFields<Input<T>, Infer<T>, {
		innerSchema: T,
		sourceKey: string,
	}>,
	typeof(PointerSchemaMetatable)
>

function schemas.at<T>(innerSchema: T, sourceKey: string): PointerSchema<T>
	return setmetatable(withDefaultBaseSchemaFields({
		innerSchema = innerSchema,
		sourceKey = sourceKey,
	}), PointerSchemaMetatable)
end

do
	local baseImpl = defaultBaseImpl :: BaseImpl<PointerSchema<any>>
	PointerSchema.optional = baseImpl.optional
	PointerSchema.at = baseImpl.at
	PointerSchema.refine = baseImpl.refine
	PointerSchema.transform = baseImpl.transform
	PointerSchema.preprocess = baseImpl.preprocess
end

-- #endregion

-- #region SchemaEffects
local SchemaEffects = {}
local SchemaEffectsMetatable = { __index = SchemaEffects }
table.freeze(SchemaEffectsMetatable)

type SchemaEffects<T> = setmetatable<
	BaseSchemaFields<Infer<T>, Infer<T>, {
		innerSchema: T,
	}>,
	typeof(SchemaEffectsMetatable)
>
