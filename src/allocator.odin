package main;

import "core:mem";


get_arena :: proc() -> mem.Arena
{
    arena := mem.Arena{};
    mem.arena_init(&arena,make([]u8,4*1024*1024));
    return arena;
}

free_arena :: proc(arena : ^mem.Arena)
{
    mem.arena_free_all(arena);
    delete(arena.data);
}


alloc_and_set :: proc($U:typeid,val : $T) -> ^U
{
    ret := new(U);
    ret^ = val;
    return ret;
}