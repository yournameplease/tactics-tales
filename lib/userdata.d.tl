--- @meta

--- @class userdata
--- @field x number
--- @field y number
--- @field z number
--- @operator add(userdata|number):userdata
--- @operator sub(userdata|number):userdata
--- @operator mul(userdata|number):userdata
--- @operator div(userdata|number):userdata
global record Userdata
	x: number
	y: number
	z: number
end


global enum userdata_type
	"u8"
	"i16"
	"i32"
	"i64"
	"f64"
end

--- Creates a userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata)
--- @param data_type userdata_type The primitive type of the userdata's numbers
--- @param width integer
--- @param height integer
--- @param data? string string of hex values encoding the data or comma separated list of floats
--- @return userdata
--- @overload fun(data_type: userdata_type, width: integer, data: string?): userdata
--- @overload fun(data: string): userdata
global userdata: function(data_type: userdata_type, width: integer, height: integer, data: string): Userdata 

--- Creates a vector (f64, 1d userdata)
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#vec)
--- @return userdata
--- @param ... number
global vec: function(...: number) : Userdata 

--- @class userdata
--- @return number
--- Get the magnitude of the vector
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Vector_methods)
-- global userdata: function:magnitude: any() 

--- @class userdata
--- @param v userdata
--- @return number
--- Get the distance to another vector
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Vector_methods)
-- global userdata: function:distance: any(v) 

--- @class userdata
--- @param v userdata
--- @return number
--- Get the dot product of another vector
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Vector_methods)
-- global userdata: function:dot: any(v) 

--- @class userdata
--- @param v userdata
--- @param v_out userdata | boolean
--- @return userdata
--- Get the cross product of another vector
--- If v_out is provided, the output will be stored in v_out, or in self if true
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Vector_methods)
-- global userdata: function:cross: any(v, v_out) 

--- @class userdata
--- @return integer
--- Gets the width of the userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_width)
-- global userdata: function:width: any() 

--- @class userdata
--- @return integer | nil
--- Gets the height of the userdata
--- Returns nil for a 1d userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_height)
-- global userdata: function:height: any() 

--- @class userdata
--- @return integer width
--- @return integer height
--- @return string type
--- @return integer dimensionality
--- Returns the attributes of the userdata
--- If the userdata is 1d, height will be 1
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_attribs)
-- global userdata: function:attribs: any() 

--- Gets values from a userdata as a multiple value return. If no index and no count are specified,
--- it will return all values in flat-indexed order.
--- If only an index is specified, it will return the value at that index. If the starting index
--- is out of range, it will return a single 0. If not, any additional values that are not in range will each be returned as 0.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
--- @param u userdata
--- @param x integer The x index to start from
--- @param y integer The y index to start from
--- @param n integer The number of flat-indexed values to get
--- @return number ... Each value from the starting index in flat-indexed order
--- @overload fun(u: userdata, x: integer, n: integer): number ...
--- @overload fun(u: userdata, x: integer, y: integer): number
--- @overload fun(u: userdata, x: integer): number
--- @overload fun(u: userdata): number ...
-- global get: function(u: any, x: any, y: any, n: any) 

-- userdata.get = get

--- @class userdata
--- @param x integer
--- @param ... number
--- Set one or more values starting at x
--- Out of range values have no effect
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
-- global userdata: function:set: any(x, ...) 

--- @class userdata
--- @param x integer
--- @param y integer
--- @param ... number
--- Set one or more values starting at x, y
--- Out of range values have no effect
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
-- global userdata: function:set: any(x, y, ...) 

--- Set one or more values starting at x
--- Out of range values have no effect
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
--- @param u userdata
--- @param x integer
--- @param ... number
-- global set: function(u: any, x: any, ...: any) 

--- Set one or more values starting at x, y
--- Out of range values have no effect
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
--- @param u userdata
--- @param x integer
--- @param y integer
--- @param ... number
-- global set: function(u: any, x: any, y: any, ...: any) 

--- Copy a region of one userdata to another
--- Both src and dest must be the same type.
--- src and dest default to the current draw target.
--- width and height default to the src width and height.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#blit)
--- @param src? userdata
--- @param dest? userdata
--- @param src_x? integer
--- @param src_y? integer
--- @param dest_x? integer
--- @param dest_y? integer
--- @param width? integer
--- @param height? integer
-- global blit: function(src: any, dest: any, src_x: any, src_y: any, dest_x: any, dest_y: any, width: any, height: any) 

--- Get a row of a 2d userdata
--- Rows are 0-indexed
--- Returns nil if out of range
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_row)
--- @class userdata
--- @param i integer
--- @return userdata | nil
-- global userdata: function:row: any(i) 

--- Get a column of a 2d userdata
--- Columns are 0-indexed
--- Returns nil if out of range
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_row)
--- @class userdata
--- @param i integer
--- @return userdata | nil
-- global userdata: function:column: any(i) 

-- TODO userdata op functions
-- function userdata_op(u0, u1, u2, offset1, offset2, len, stride1, stride2, spans) end

--- @class userdata
--- @param m userdata
--- @param m_out? userdata | boolean
--- @return userdata | nil
--- Multiply two matrices together
--- If m_out is provided, the output will be stored in m_out, or in self if true
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#matmul)
-- global userdata: function:matmul: any(m, m_out) 

-- This function is included in the manual, but is not real
-- --- Multiply two matrices together
-- --- If m_out is provided, the output will be stored in m_out, or in self if true
-- --- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#matmul)
-- --- @param m0 userdata
-- --- @param m1 userdata
-- --- @param m_out? userdata | boolean
-- --- @return userdata | nil
-- function matmul(m0, m1, m_out) end

--- @class userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Matrix_methods)
-- global userdata: function:matmul2d: any(m, m_out) 

--- Multiply 3d 4x4 transformation matrices
--- If m_out is provided, the output will be stored in m_out, or in self if true
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#matmul3d)
--- @param m userdata
--- @param m_out? userdata | boolean
-- global userdata: function:matmul3d: any(m, m_out) 

-- This function is included in the manual, but is not real
-- --- Multiply 3d 4x4 transformation matrices
-- --- If m_out is provided, the output will be stored in m_out, or in self if true
-- --- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#matmul3d)
-- --- @param m0 userdata
-- --- @param m1 userdata
-- --- @param m_out? userdata | boolean
-- --- @class userdata
-- function matmul3d(m0, m1, m_out) end

--- @class userdata
--- @param m_out? userdata | boolean
--- @return userdata
--- Transpose the matrix
--- If m_out is provided, the output will be stored in m_out, or in self if true
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Matrix_methods)
-- global userdata: function:transpose: any(m_out) 

--- Map the contents of an integer-type userdata to RAM
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#memmap)
--- @param ud userdata
--- @param addr integer
-- global memmap: function(ud: any, addr: any) 

--- Unmap userdata from RAM
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#unmap)
--- @param ud userdata
--- @param addr? integer
-- global unmap: function(ud: any, addr: any) 

--- @class userdata
--- @param addr integer Address to read from
--- @param offset? integer Offset into userdata
--- @param elements? integer Number of elements to peek
--- @return integer ...
--- Read from RAM into an integer typed userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_peek)
-- global userdata: function:peek: any(addr, offset, elements) 

--- @class userdata
--- @param addr integer Address to write to
--- @param offset? integer Offset into userdata
--- @param elements? integer Number of elements to poke
--- Write to RAM from an integer typed userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_poke)
-- global userdata: function:poke: any(addr, offset, elements) 

--- Copy a region of one userdata to another
--- Both src and dest must be the same type.
--- dest defaults to the current draw target.
--- width and height default to the src width and height.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_blit)
--- @param dest? userdata
--- @param src_x? integer
--- @param src_y? integer
--- @param dest_x? integer
--- @param dest_y? integer
--- @param width? integer
--- @param height? integer
-- global userdata: function:blit: any(dest, src_x, src_y, dest_x, dest_y, width, height) 

--- Change the type or size of a userdata. Only integer types can be used.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_mutate)
--- @param data_type string u8, i16, i32, i64
--- @param width? integer
--- @param height? integer
-- global userdata: function:mutate: any(data_type, width, height) 

--- Linearly interpolate between two elements of a userdata
--- offset is the flat index to start from
--- len is the length (x1 - x0) of the lerp including the end (but not the start) element
--- el_stride is the distance between the elements
--- Multiple lerps can be performed at once using num_lerps and lerp_stride
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_lerp)
--- @param offset? integer
--- @param len? integer
--- @param el_stride? integer
--- @param num_lerps? integer
--- @param lerp_stride? integer
-- global userdata: function:lerp: any(offset, len, el_stride, num_lerps, lerp_stride) 

--- Return a copy of userdata cast as a different type.
--- When converting to ints, f64 values are floored and out of range values overflow
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_convert)
--- @param data_type string u8, i16, i32, i64, f64
--- @param dest? userdata
--- @return userdata
-- global userdata: function:convert: any(data_type, dest) 

-- global userdata: function:pow: any() 

-- global userdata: function:sgn: any() 

-- global userdata: function:sgn0: any() 

-- global userdata: function:abs: any() 

--- Sort a 2d userdata of any type by the value found at the index column (0 by default)
--- When descending is true, sort from largest to smallest
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_sort)
--- @param index? integer
--- @param descending? boolean
-- global userdata: function:sort: any(index, descending) 

-- === Userdata Operations ===

--- Applies add to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:add: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies sub to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:sub: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies mul to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:mul: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies div to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:div: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies integer division to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:idiv: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies mod to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:mod: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies band to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:band: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies bor to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:bor: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies bxor to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:bxor: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Shifts the bits of each element to the left by n bits
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:shl: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Shifts the bits of each element to the right by n bits
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:shr: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Copy the userdata
--- When :copy is given a table as the first argument (after self), it is taken to be a
--- lookup table into that userdata for the start of each span.
--- ** this form will be deprecated in 0.1.2 -- use :take instead with the same parameters.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_copy)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:copy: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Take values from the userdata at locations specified by idx.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_take)
--- @param idx userdata
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param idx_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:take: any(idx, dest, src_offset, dest_offset, len, idx_stride, dest_stride, spans) 

--- Returns the largest of each element or scalar
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#UserData_Operations)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:max: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Returns the smallest of each element or scalar
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#UserData_Operations)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:min: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 
