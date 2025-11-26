export type function OneOf(variants: type): type
	local function pushField(fieldProps: { [type]: { read: type, write: type } }, variant: type)
		assert(variant:is("table"), "OneOf variant must be a table type")
		local tagProp = variant:readproperty(types.singleton("tag"))
		assert(tagProp, "OneOf variant requires 'tag' property")
		local props: { [type]: { read: type, write: type } } = {}
		local propCount = 0
		for prop, val in variant:properties() do
			if prop == types.singleton("tag") then
				continue
			end
			-- selene: allow(shadowing)
			local val = val.read or val.write
			assert(val, "field value must be valid")
			props[prop] = { read = val, write = nil :: any }
			propCount += 1
		end
		local inputVariant = types.newtable(props)
		if propCount == 1 then
			local valueProp = inputVariant:readproperty(types.singleton("value"))
			if valueProp then
				inputVariant = valueProp
			end
		end
		fieldProps[tagProp] =
			{ read = types.newfunction({ head = { inputVariant } }, { head = { variant } }), write = nil :: any }
	end
	local fieldProps: { [type]: { read: type, write: type } } = {}
	if variants:is("union") then
		for _, variant in variants:components() do
			pushField(fieldProps, variant)
		end
	elseif variants:is("table") then
		pushField(fieldProps, variants)
	else
		error("OneOf requires a union or table type")
	end
	return types.newtable(fieldProps)
end

export type function Variant(tag: type, value: type): type
	local props: { [type]: { read: type, write: type } } = {
		[types.singleton("tag")] = { read = tag, write = nil :: any },
	}
	if value:is("table") and not value:readproperty(types.singleton("tag")) then
		for prop, val in value:properties() do
			-- selene: allow(shadowing)
			local val = val.read or val.write
			assert(val, "field value must be valid")
			props[prop] = { read = val, write = nil :: any }
		end
	else
		props[types.singleton("value")] = { read = value, write = nil :: any }
	end
	return types.newtable(props)
end

type function Not(t: type): type
	return types.negationof(t)
end

type Constructor = (value: unknown) -> { read tag: string, [string & Not<"tag">]: unknown }

local function createOneOfMetatable(metatable: { [any]: any }?)
	local OneOfMetatable = {
		__index = function(self: OneOfInstance, tag: string): Constructor
			local newConstructor: Constructor = function(value)
				local constructed = { tag = tag }
				if type(value) == "table" and not value.tag then
					for key, val in value :: { [unknown]: unknown } do
						assert(key ~= "tag", "OneOf variant field cannot be named 'tag'")
						assert(type(key) == "string", "OneOf variant fields must have string keys")
						constructed[key] = val
					end
				else
					constructed.value = value
				end
				if metatable then
					setmetatable(constructed, metatable)
				end
				table.freeze(constructed)
				return constructed
			end
			self[tag] = newConstructor
			return newConstructor
		end,
	}
	table.freeze(OneOfMetatable)
	return OneOfMetatable
end

type OneOfInstance = setmetatable<{ [string]: Constructor }, typeof(createOneOfMetatable(nil))>

local singletonInstance: OneOfInstance?
return function(
		metatable: {
			[any]: any,
		}?
	): {
		[string]: <T>(T) -> Variant<string, T>,
	} -- in the future: oneof<<T>>()
		local isSingleton = metatable == nil
		if isSingleton and singletonInstance then
			return singletonInstance :: any
		end
		local new = setmetatable({}, createOneOfMetatable(metatable))
		if isSingleton then
			singletonInstance = new :: OneOfInstance
		end
		return new :: any
	end :: (() -> { [string]: <T>(T) -> Variant<string, T> }) & (<MT>(metatable: MT) -> { [string]: <T>(T) -> setmetatable<Variant<string, T>, MT> })
