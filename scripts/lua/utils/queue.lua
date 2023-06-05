return function(queue)
    local mt = {}
    setmetatable(queue, mt)
    return queue
end
