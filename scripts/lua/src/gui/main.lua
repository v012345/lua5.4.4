local main = {
    counter = 1,
    is_working = false
}
function main:update()
    -- print(self.counter);
    self.counter = self.counter + 1
end

function main:add_action(action)
    print(action)
end

function update()
    main:update()
end

function add_action(action)
    main:add_action(action)
end
