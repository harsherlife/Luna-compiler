package main;


import "core:fmt";
import "core:os";
import "core:mem";


main ::proc()
{

    when ODIN_DEBUG {
		track: mem.Tracking_Allocator;
		mem.tracking_allocator_init(&track, context.allocator);
		context.allocator = mem.tracking_allocator(&track);

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map));
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location);
				}
			}
			mem.tracking_allocator_destroy(&track);
		}
	}
    
    arena := get_arena();
    defer free_arena(&arena);
    old_alloc := context.allocator;
    context.allocator = mem.arena_allocator(&arena);

    compiler_options := parse_args(os.args);
    src_code,ok := os.read_entire_file_from_path(compiler_options.file_name,context.allocator);

    if ok != 0
    {
        errorf("error in reading file\n");
    }
    tokens := tokenize(src_code);

    ast := parse_ast(tokens);

    dump_ast(&ast);
    context.allocator = old_alloc;
}