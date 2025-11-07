local serde = require("@lune/serde")
local pathfs = require("../lune_packages/pathfs")
local FilePath = pathfs.FilePath
local pubclass = require("./utils/pubclass")
local typeforge = require("./utils/typeforge")

local Manifest = {}
local mt = { __index = Manifest }

function Manifest.new(pesde: PesdeManifest, release: ReleaseManifest): Self
	return setmetatable({
		_pesde = pesde,
		_release = release,
	}, mt) :: Self
end

function Manifest.default(): Self
	return Manifest.new({}, {})
end

function Manifest.parse(contents: string | buffer): Self

end

function Manifest.fromFile(filePath: pathfs.FilePath | pathfs.AsPath): Self
	if not FilePath.is(filePath) then
		filePath = FilePath.new(filePath :: any)
	end
end

function Manifest.pesde(self: Self): PesdeManifest
	return self._pesde
end

function Manifest.release(self: Self): ReleaseManifest
	return self._release
end

type PesdeManifest = typeforge.ReadOnly<{}>

type ReleaseManifest = typeforge.ReadOnly<{
	keepachangelog: boolean?,
	bundles: { string }?,
	publishes: { string }?,
	osTargets: { string }?,
	osTargetGlobal: string?,
	commitToken: string?,
}>

type Self = pubclass.Class<{
	_pesde: PesdeManifest,
	_release: ReleaseManifest,
}, typeof(mt)>

export type Manifest = pubclass.PublicInstance<Self>

return Manifest :: pubclass.PublicClass<Self>
