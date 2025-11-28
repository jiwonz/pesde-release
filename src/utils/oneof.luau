export type function OneOf(variants: type): type
	local function collectProps(t: type, props: { [type]: { read: type, write: type } })
		if t:is("table") then
			for prop, val in t:properties() do
				-- selene: allow(shadowing)
				local val = val.read or val.write
				assert(val, "field value must be valid")
				props[prop] = { read = val, write = nil :: any }
			end
		elseif t:is("intersection") then
			for _, component in t:components() do
				collectProps(component, props)
			end
		end
	end

	local function pushField(fieldProps: { [type]: { read: type, write: type } }, variant: type)
		local props: { [type]: { read: type, write: type } } = {}
		collectProps(variant, props)

		local tagType = types.singleton("tag")
		local tagProp = variant:readproperty(tagType)
		assert(tagProp, "OneOf variant requires 'tag' property")

		local tagKey: type?
		for key, _ in props do
			if key == types.singleton("tag") then
				tagKey = key
				break
			end
		end
		if tagKey then
			props[tagKey] = nil
		end

		local inputVariant = types.newtable(props)
		local propCount = 0
		local hasValue = false
		for k, _ in inputVariant:properties() do
			propCount += 1
			if k == types.singleton("value") then
				hasValue = true
			end
		end

		if propCount == 1 and hasValue then
			local valueProp = inputVariant:readproperty(types.singleton("value"))
			if valueProp then
				inputVariant = valueProp
			end
		end
		fieldProps[tagProp] = {
			read = types.newfunction({ head = { inputVariant } }, { head = { variant } }),
			write = nil :: any,
		}
	end
	local fieldProps: { [type]: { read: type, write: type } } = {}
	if variants:is("union") then
		for _, variant in variants:components() do
			pushField(fieldProps, variant)
		end
	elseif variants:is("table") or variants:is("intersection") then
		pushField(fieldProps, variants)
	else
		error("OneOf requires a union, table, or intersection type")
	end
	return types.newtable(fieldProps)
end

export type function Variant(tag: type, value: type): type
	local function collectProps(t: type, props: { [type]: { read: type, write: type } })
		if t:is("table") then
			for prop, val in t:properties() do
				-- selene: allow(shadowing)
				local val = val.read or val.write
				assert(val, "field value must be valid")
				props[prop] = { read = val, write = nil :: any }
			end
		elseif t:is("intersection") then
			for _, component in t:components() do
				collectProps(component, props)
			end
		end
	end

	local props: { [type]: { read: type, write: type } } = {
		[types.singleton("tag")] = { read = tag, write = nil :: any },
	}

	local function hasTag(t: type): boolean
		if t:is("table") then
			return t:readproperty(types.singleton("tag")) ~= nil
		elseif t:is("intersection") then
			for _, c in t:components() do
				if hasTag(c) then
					return true
				end
			end
		end
		return false
	end

	if (value:is("table") or value:is("intersection")) and not hasTag(value) then
		collectProps(value, props)
	else
		props[types.singleton("value")] = { read = value, write = nil :: any }
	end

	return types.newtable(props)
end

export type TagOf<T> = index<T, "tag">

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

type OneOfInstance = setmetatable<{ [string]: Constructor }, typeof(createOneOfMetatable())>

do
	local singletonInstance: OneOfInstance?
	--[=[
		Creates a variant builder.
		- If called without arguments, returns a singleton instance.
		- If called with a metatable, returns a new variant builder with that metatable.

		@param metatable -- Metatable to set on created variants.
		@return OneOf -- A variant builder
	]=]
	local function oneof(metatable: {
		[any]: any,
	}?): {
		[string]: <T>(T) -> Variant<string, T>,
	} -- in the future: <T, MT>(metatable: MT?) -> OneOf<T, MT> so it would allow usage with oneof<<Variants>>() and oneof<<Class>>(metatable)
		-- ^actually im waiting a bug fix for explicit type instantiation before doing that
		local isSingleton = metatable == nil
		if isSingleton and singletonInstance then
			return singletonInstance :: any
		end
		local new = setmetatable({}, createOneOfMetatable(metatable))
		if isSingleton then
			singletonInstance = new :: OneOfInstance
		end
		return new :: any
	end

	return oneof :: (() -> { [string]: <T>(T) -> Variant<string, T> }) & (<MT>(metatable: MT) -> { [string]: <T>(T) -> setmetatable<Variant<string, T>, MT> })
end
