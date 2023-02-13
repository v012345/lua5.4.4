local main = {
    counter = 1,
}
function main:update()
    print(self.counter);
    self.counter = self.counter + 1
end

function update()
    main:update()
end
