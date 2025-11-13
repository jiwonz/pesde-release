local Reasons = require("./Reasons")
local Result = {}
local ResultMt = { __index = Result }

type Reasons<T> = Reasons.Reasons<T>
type FailFormatter<T> = (reasons: Reasons<T>) -> string

local defaultFailFormatter: FailFormatter<any> = function(reasons: Reasons<any>): string
	return if #reasons.tail < 1 then `{reasons.head}` else `{reasons.head}: {table.concat(reasons.tail, "; ")}`
end

function Result.ok<T>(value: T): Ok<T>
	return setmetatable({
		ok = true :: true,
		fail = false :: false,
		value = value,
	}, ResultMt)
end

function Result.fail<T>(mainReason: T): Fail<T>
	return setmetatable({
		ok = false :: false,
		fail = true :: true,
		reasons = Reasons.new(mainReason, {}),
	}, ResultMt)
end

function Result.try<T, R, A...>(fn: (A...) -> R, ...: A...): (A...) -> Result<R>
	local ok, errOrValue = pcall(fn, ...)
	if ok then
		return Result.ok(errOrValue) :: any
	else
		return Result.fail(`Error occurred: {errOrValue}`) :: any
	end
end

function Result.unwrap<T, E>(self: Result<T, E>, failFormatter: FailFormatter<E>?): T
	if self.ok then
		return self.value
	else
		local formatter: FailFormatter<E> = failFormatter or defaultFailFormatter
		error(
			formatter(
				Result.fail("[Result::unwrap] Attempted to unwrap a failed Result")
					:withReason(formatter(self.reasons)).reasons
			)
		)
	end
end

function Result.errorIfFail<T, E>(self: Result<T, E>, failFormatter: FailFormatter<E>?)
	if self.fail then
		local formatter: FailFormatter<E> = failFormatter or defaultFailFormatter
		error(formatter(self.reasons))
	end
end

function Result.expectOk<T, E>(self: Result<T, E>, message: string, failFormatter: FailFormatter<E>?): T
	if self.ok then
		return self.value
	else
		local formatter: FailFormatter<E> = failFormatter or defaultFailFormatter
		error(
			formatter(
				Result.fail("[Result::expectOk] Expected ok but got fail")
					:withReason(message)
					:withReason(formatter(self.reasons)).reasons
			)
		)
	end
end

function Result.expectFail<T, E>(self: Result<T, E>, message: string, failFormatter: FailFormatter<E>?)
	if self.ok then
		local formatter: FailFormatter<E> = failFormatter or defaultFailFormatter
		error(formatter(Result.fail("[Result::expectFail] Expected fail but got ok"):withReason(message).reasons))
	end
end

function Result.withReason<T>(self: Fail<T>, reason: T): Fail<T>
	if self.ok then
		error("Cannot add reasons to an Ok result")
	end
	self.reasons:push(reason)
	return self
end

function Result.withReasons<T>(self: Fail<T>, reasons: { T } | Reasons<T>): Fail<T>
	if self.ok then
		error("Cannot add reasons to an Ok result")
	end
	self.reasons:merge(reasons)
	return self
end

function Result.format<T>(self: Fail<T>, failFormatter: FailFormatter<T>?): string
	if self.ok then
		error("Cannot format an Ok result")
	end
	local formatter: FailFormatter<T> = failFormatter or defaultFailFormatter
	return formatter(self.reasons)
end

type Ok<T> = setmetatable<{
	read ok: true,
	read fail: false,
	read value: T,
}, typeof(ResultMt)>

type Fail<T = string> = setmetatable<{
	read ok: false,
	read fail: true,
	read reasons: Reasons<T>,
}, typeof(ResultMt)>

export type Result<T, E = string> = Ok<T> | Fail<E>

return table.freeze(Result)
