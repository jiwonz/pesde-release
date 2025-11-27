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
		-- assert(variant:is("table"), "OneOf variant must be a table type")
		local props: { [type]: { read: type, write: type } } = {}
		collectProps(variant, props)

		local tagType = types.singleton("tag")
		local tagProp = variant:readproperty(tagType)
		assert(tagProp, "OneOf variant requires 'tag' property")

		local tagKey: type?
		for key, _ in props do
			if key == types.singleton("tag") then -- 동등성 비교로 찾음
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
		-- inputVariant를 순회하며 정확한 키 개수 확인
		for k, _ in inputVariant:properties() do
			propCount += 1
			if k == types.singleton("value") then
				hasValue = true
			end
		end

		-- 언래핑 로직
		if propCount == 1 and hasValue then
			local valueProp = inputVariant:readproperty(types.singleton("value"))
			if valueProp then
				inputVariant = valueProp
			end
		end
		-- [수정] returnType 대신 variant(원본)를 그대로 사용
		fieldProps[tagProp] = {
			read = types.newfunction({ head = { inputVariant } }, { head = { variant } }),
			write = nil :: any,
		}
	end
	local fieldProps: { [type]: { read: type, write: type } } = {}
	if variants:is("union") then
		for _, variant in variants:components() do
			-- [수정] 교차 타입인지 확인하는 분기 제거 -> 그냥 pushField로 넘김
			-- pushField 내부의 collectProps가 알아서 처리함
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
		collectProps(value, props) -- 안전하게 합치기
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
