local result = require("./serdeform2/result")

local Type = {}
local TypeMt = { __index = Type }

type Parser<T> = (input: unknown) -> result.Result<T>

function Type.new<T>(parser: Parser<T>): Type<T>
	return setmetatable({ _parser = parser, _t = nil }, TypeMt)
end

function Type.parse<T>(self: Type<T>, input: unknown): result.Result<T>
	return self._parser(input)
end

function Type.parser<T>(self: Type<T>): Parser<T>
	return self._parser
end

function Type.optional<T>(self: Type<T>): Type<T?>
	local parser: Parser<T?> = function(input: unknown): result.Result<T?>
		if input == nil then
			return result.success(nil)
		else
			return self:parse(input)
		end
	end
	return Type.new(parser)
end

type Type<T> = setmetatable<{ read _parser: Parser<T>, read _t: T }, typeof(TypeMt)>

-- WIP: Struct type
