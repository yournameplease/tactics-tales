-- Define global 'pt' for Busted test environment
_G.pt = {
    flr = math.floor,
    cos = math.cos,
    sin = math.sin,
    abs = math.abs,
    -- A simple mock for rnd, which might be used indirectly or in future tests
    rnd = function(x: number): number return math.random() * x end 
}
