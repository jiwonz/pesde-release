local convertCase = require("./convertCase")

local serdeform = {}

type Check<T = any> = (value: T) -> (boolean, string?)

type function FromForm(schema: type): type
	assert(schema:is("table"), "schema must be a table type")
	local props = {}
	for prop, val in schema:properties() do
		-- selene: allow(shadowing)
		local val = val.read or val.write
		if not val then
			continue
		end
		assert(val:is("function"), "form properties must be function(Check)s")
		local params = val:parameters().head
		assert(params and params[1], "form property functions must have exactly one parameter")
		props[prop] = params[1]
	end
	return types.newtable(props, nil, nil)
end

-- TODO: Support strict schema checking (e.g. no extra properties allowed)
local Form = {}
local mt = {
	__index = Form,
	__call = function<T>(self: Form<T>, data: FromForm<T>): FromForm<T>
		return self:construct(data)
	end
}

local function createForm<T>(schema: T): Form<T>
	return setmetatable({
		schema = schema,
	}, mt)
end

local function isForm<T>(value: any): boolean
	return type(value) == "table" and getmetatable(value) == mt
end

function Form.check<T>(self: Form<T>, data: any): (boolean, string?)
	do
		local ok, err = serdeform.table(data)
		if not ok then
			return false, err
		end
	end
	for prop, check in self.schema :: Schema do
		local value = (data :: { [string]: any })[prop]
		local ok, err
		if isForm(check) then
			ok, err = (check :: Form<any>):check(value)
		else
			ok, err = (check :: Check)(value)
		end
		if not ok then
			return false, string.format("Form validation failed for property '%s':\n\t%s", prop, err :: string)
		end
	end
	return true, nil
end

function Form.construct<T>(self: Form<T>, data: FromForm<T>): FromForm<T>
	do
		local ok, err = serdeform.table(data)
		if not ok then
			error(err :: string)
		end
	end
	local result: { [string]: any } = {}
	for prop, check in self.schema :: Schema do
		local value = (data :: { [string]: any })[prop]
		if isForm(check) then
			value = (check :: Form<any>):construct(value)
		else
			local ok, err = (check :: Check)(value)
			if not ok then
				error(string.format("Form validation failed for property '%s':\n\t%s", prop, err :: string))
			end
		end
		result[prop] = value
	end
	return result :: FromForm<T>
end

function Form.fromTable<T>(self: Form<T>, tbl: { [string]: any }): FromForm<T>
	do
		local ok, err = serdeform.table(tbl)
		if not ok then
			error(err :: string)
		end
	end
	local camelCaseTbl: { [string]: any } = {}
	for key, value in tbl do
		camelCaseTbl[convertCase.toCamel(key)] = value
	end
	local result: { [string]: any } = {}
	for prop, check in self.schema :: Schema do
		local value = (camelCaseTbl :: { [string]: any })[prop]
		if isForm(check) then
			value = (check :: Form<any>):fromTable(value)
		else
			local ok, err = (check :: Check)(value)
			if not ok then
				error(string.format("Form validation failed for property '%s':\n\t%s", prop, err :: string))
			end
		end
		result[prop] = value
	end
	return result :: FromForm<T>
end

local encodeDecodeFormats = {
	toml = true,
	json = true,
	yaml = true,
	jsonc = true,
}

type Form<T> = setmetatable<{ schema: T }, typeof(mt)> --& (data: any) -> (boolean, string?)
type Schema = { [string]: Check | Form<any> }

local function createCheckByType(typeName: string): Check
	return function(value: any): (boolean, string?)
		local valueType = type(value)
		if valueType == typeName then
			return true, nil
		else
			return false, string.format("%s expected, got %s", typeName, valueType)
		end
	end
end

serdeform.number = createCheckByType("number") :: Check<number>
serdeform.string = createCheckByType("string") :: Check<string>
serdeform.boolean = createCheckByType("boolean") :: Check<boolean>
serdeform.table = createCheckByType("table") :: Check<{}>

return setmetatable(serdeform, {
	__call = function<T>(_self, schema: T): Form<T>
		return createForm(schema)
	end,
})
