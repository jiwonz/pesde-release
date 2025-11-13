local Reasons = {}
local ReasonsMt = { __index = Reasons }

function Reasons.new<T>(head: T, tail: { T }): Reasons<T>
	return setmetatable({
		head = head,
		tail = tail,
	}, ReasonsMt)
end

function Reasons.collect<T>(self: Reasons<T>): { T }
	local tail = self.tail
	local allocSize = #tail + 1
	local collected: { T } = table.create(allocSize)
	collected[1] = self.head
	for i = 2, allocSize do
		collected[i] = tail[i - 1]
	end
	return collected
end

function Reasons.push<T>(self: Reasons<T>, reason: T)
	table.insert(self.tail, reason)
end

function Reasons.merge<T>(self: Reasons<T>, reasons: { T } | Reasons<T>)
	if Reasons.is(reasons) then
		for _, reason in (reasons :: Reasons<T>):collect() do
			table.insert(self.tail, reason)
		end
	else
		for _, reason in reasons do
			self:push(reason)
		end
	end
end

function Reasons.is(value: any): boolean
	return type(value) == "table" and getmetatable(value) == ReasonsMt
end

export type Reasons<T> = setmetatable<{
	read head: T,
	read tail: { T },
}, typeof(ReasonsMt)>

return table.freeze(Reasons)
