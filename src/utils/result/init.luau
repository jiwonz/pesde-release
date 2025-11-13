local Result = require("@self/Result")

export type Result<T, E = string> = Result.Result<T, E>

local result = {}
result.Result = Result

return table.freeze(result)
