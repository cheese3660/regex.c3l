<*
    This module implements the concept of character groups in a regular expression
*>
module regex::runtime::character_class;

import std::io;

alias CharacterFn = fn bool(char);

import std::collections::bitset;


typedef CharacterClass = BitSet { 256 };

fn CharacterClass CharacterClass.with_character(self, char c) {
    self[(usz)c] = true;
    return self;
}

fn CharacterClass CharacterClass.with_fn(self, CharacterFn funct) {
    for (usz i = 0; i < 256; i++) {
        self[i] = self[i] || funct((char)i);
    }
    return self;
}

fn bool CharacterClass.get(self, usz i) @operator([]) @inline => ((BitSet {256})self)[i];
fn void CharacterClass.set(&self, usz i, bool b) @operator([]=) @inline => ((BitSet {256}*)self).set_bool(i,b);

fn bool CharacterClass.equals(&self, CharacterClass other) @operator(==) {
    BitSet {256} *bitset_self = (BitSet {256}*)self;
    BitSet {256} bitset_other = (BitSet {256})other;
    foreach (idx, val : bitset_self.data) {
        if (val != bitset_other.data[idx]) return false;
    }
    return true;
}

fn usz? CharacterClass.to_format(&self, Formatter* formatter) @dynamic
{
    usz n = 0;
    n += formatter.print("[")!;
    for (usz c = 0; c < 256; c++) {
        if (self.get(c)) {
            if (c < 32 || c >= 127) {
                n += formatter.printf("\\x%02x", c)!;
            } else if (c == '\"' || c == '[' || c == ']') {
                n += formatter.printf("\\%c", c)!;
            } else {
                n += formatter.printf("%c", c)!;
            }
        }
    }
    n += formatter.print("]")!;
    return n;
}

