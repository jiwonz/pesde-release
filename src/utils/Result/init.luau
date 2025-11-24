local Error = require("@self/Error")
local commonTypes = require("@self/commonTypes")

export type Error = Error.Error
export type Reason = commonTypes.Reason

local Result = {}
local ResultMetatable = { __index = Result }
table.freeze(ResultMetatable)

type Ok<T> = setmetatable<{
	read isOk: true,
	read isErr: false,
	read value: T,
	read err: nil,
}, typeof(ResultMetatable)>
type Err<E> = setmetatable<{
	read isOk: false,
	read isErr: true,
	read value: nil,
	read err: E,
}, typeof(ResultMetatable)>
export type Result<T, E = Error> = Ok<T> | Err<E>

--- Constructs an Ok result
local function constructOkResult<T>(value: T): Ok<T>
	return setmetatable({
		isOk = true :: true,
		isErr = false :: false,
		value = value,
		err = nil,
	}, ResultMetatable)
end

--- Constructs an Err result
local function constructErrResult<E>(reason: Reason | Error): Err<E>
	local fail = if Error.is(reason) then reason :: Error else Error.new(reason)

	return setmetatable({
		isOk = false :: false,
		isErr = true :: true,
		value = nil,
		err = fail,
	}, ResultMetatable)
end

--- Constructs a Result from a function that may error
local function constructResultFromTry<T, E>(fn: () -> T): Result<T, E>
	local ok, err = pcall(fn)
	if err then
		return constructErrResult(err)
	end
	return constructOkResult(ok)
end

--- Adds context to an Err result
Result.context = function(self: Result<any, any>, context: Reason): Result<any, any>
	if self.err then
		return constructErrResult(Error.new(context, self.err))
	end
	return self
end :: (<T>(self: Ok<T>, context: Reason) -> Ok<T>)
& (<E>(self: Err<E>, context: Reason) -> Err<E>)
& (<T, E>(self: Ok<T> | Err<E>, context: Reason) -> Ok<T> | Err<E>)

--- Unwraps the value or errors with optional message
function Result.unwrapOrError<T>(self: Result<T>, errorMsg: Reason?): T
	if self.value then
		return self.value
	end
	error(
		if errorMsg
			then Error.new(self.err, errorMsg):toString()
			else `called "Result.unwrapOrError" on err: {self.err}`
	)
end

--- Unwraps the error or errors if the result is ok
function Result.unwrapErr<T>(self: Result<T>): Error
	if self.err then
		return self.err
	end
	error("called 'Result.unwrapErr' on ok result")
end

function Result.toAssertion<T>(self: Result<T>): (boolean, string?)
	if self.value then
		return true, nil
	else
		return false, self.err:toString()
	end
end

--- Result Class
return table.freeze({
	ok = constructOkResult,
	err = constructErrResult,
	try = constructResultFromTry,
})
