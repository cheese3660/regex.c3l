# C3 Regex Library

This is a regex (regular expression) library for C3 using a custom NFA engine at it's core.

It supports UTF8 regexen, but does not provide character classes for characters above 0x7F at the moment.

The syntax is based off of this but there are few changes https://cplusplus.com/reference/regex/ECMAScript/

- The escape sequence introducer has been changed from `\` to `%` to make writing regexen in string literals easier (this may change)
- `[.classname.]` and `[=classname=]` do not exist
- Each of the `[:classname:]` classes has a shorthand form
    * `[:alnum:]`  <-> `[:w:]`
    * `[:alpha:]`  <-> `[:a:]`
    * `[:blank:]`  <-> `[:b:]`
    * `[:cntrl:]`  <-> `[:c:]`
    * `[:digit:]`  <-> `[:d:]`
    * `[:graph:]`  <-> `[:g:]`
    * `[:lower:]`  <-> `[:l:]`
    * `[:print:]`  <-> `[:p:]`
    * `[:punct:]`  <-> `[:.:]`
    * `[:space:]`  <-> `[:s:]`
    * `[:upper:]`  <-> `[:u:]`
    * `[:xdigit:]` <-> `[:x:]`

## Example Usage

```c3
import regex;

/* Making a regex (called runtime regex due to future plans for compiled regexen) */
RuntimeRegex rr = regex::make_runtime_regex("ident(%d{3,5})", Options.IGNORE_CASE, tmem)!; // It returns an optional that contains error information
Regex r = &rr; // Get the regex interface implementation

/* Iterating over matches */
MatchIterator iter = r.iter_matches("ident123 idEnt12345 ident2 notanident123456");

while (try match = iter.next()) // Note this allocates on the temp allocator but can be passed one
{
    // Print the match
    io::printn(match);
    // Get the match begin and end

    usz begin = match.begin_offset();
    usz end = match.end_offset(); // Note, this is an *exclusive* offset, so when slicing you have to use end-1 as C3 slices are inclusive

    io::printfn("[%d, %d)", begin, end);

    // Get the first capture group (note capture groups are always the first occurence of a match)
    Capture cap = match[1]; // Capture groups are 1 indexed, the 0th group is always the entire match
    io::printn(cap.captured);
}

/* Check if an entire string matches a regex */
io::printn(r.matches("ident123456")); // should print false
io::printn(r.matches("iDeNt321")); // should print true
```