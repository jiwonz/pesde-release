local Manifest = {}
Manifest.__index = Manifest

function Manifest.new(): Manifest
	return setmetatable({
		field = 2,
	}, Manifest)
end

function Manifest.is(value: unknown): boolean
	return type(value) == "table" and getmetatable(value :: any) == Manifest
end

export type Manifest = setmetatable<{
	field: number,
}, typeof(Manifest)>
