<*
    This contains macros for working with arrays at compile time
*>
module regex::compiled::array { ValueT };
alias SliceT = ValueT[];

macro SliceT slice(SliceT $from, usz $start, usz $end = usz.max)
{
    $if $start >= $from.len:
        return (SliceT){};
    $else
        $if $end >= $from.len:
            return $from[$start..];
        $else
            return $from[$start..$end-1];
        $endif
    $endif
}


macro SliceT insert(SliceT $array, usz $position, ValueT $value)
{
    $if $position == $array.len:
        return $array +++ (SliceT){$value};
    $else
        $if $position == 0:
            return (SliceT){$value} +++ $array;
        $else
            return slice($array, 0, $position) +++ (SliceT){$value} +++ slice($array, $position);
        $endif
    $endif
}

macro SliceT remove(SliceT $array, usz $position)
{
    $if $position == $array.len - 1:
        return slice($array, 0, $array.len - 1);
    $else
        $if $position == 0:
            return slice($array, 1);
        $else
            return slice($array, 0, $position) +++ slice($array, $position + 1);
        $endif
    $endif
}

macro SliceT replace(SliceT $array, usz $position, ValueT $value)
{
    return insert(remove($array,$position),$position,$value);
}

macro SliceT push(SliceT $array, ValueT $value) => insert($array, $array.len, $value);

struct Pop
{
    ValueT value;
    SliceT next;
}
/* This one needs you to have defined a type for the return type */
macro Pop pop(SliceT $array)
{
    ValueT $value = $array[$array.len-1];
    return
    {
        $value,
        remove($array, $array.len-1)
    };
}