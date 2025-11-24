export type BaseSchemaFields<T> = {
	read ["_$t"]: T,
}

export type BaseImpl<T> = {
	optional: (self: T) -> T,
}

local defaultImpl = {} :: BaseImpl<DefaultSchema>

type DefaultSchema = setmetatable<BaseSchemaFields<any>, typeof(defaultImpl)>

function defaultImpl.optional(_self)
	error("Not implemented yet")
end

table.freeze(defaultImpl)

return table.freeze({
	defaultImpl = defaultImpl,
})
