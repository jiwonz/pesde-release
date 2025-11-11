type ResultSuccess<T> = {
	success: true,
	data: T,
}

type ResultFail = {
	success: false,
	reason: string,
}

export type Result<T> = ResultSuccess<T> | ResultFail

local result = {}

function result.success<T>(data: T): ResultSuccess<T>
	return {
		success = true,
		data = data,
	}
end

function result.fail(reason: string): ResultFail
	return {
		success = false,
		reason = reason,
	}
end

return result
