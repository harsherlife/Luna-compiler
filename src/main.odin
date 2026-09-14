package main;


import "core:fmt";
import "core:os";
import "core:mem";
import "core:time";

TIMING :: #config(TIMING,false);


main ::proc()
{

    when ODIN_DEBUG {
		track := mem.Tracking_Allocator{};
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
    defer context.allocator = old_alloc;
    context.allocator = mem.arena_allocator(&arena);

    compiler_options := parse_args(os.args);
    src_code,ok := os.read_entire_file_from_path(compiler_options.file_name,context.allocator);

    if ok != 0
    {
        errorf("error in reading file\n");
    }
    when TIMING{
        clock := time.Stopwatch{};

        time.stopwatch_start(&clock);
        tokens := tokenize(src_code);
        time.stopwatch_stop(&clock);

        fmt.printf("tokens = {} microseconds\n",get_time_micros(clock));
        time.stopwatch_reset(&clock);

        time.stopwatch_start(&clock);
        ast := parse_ast(tokens);
        time.stopwatch_stop(&clock);


        fmt.printf("ast = {} microseconds\n",get_time_micros(clock));
        time.stopwatch_reset(&clock);
    }
    else
    {
        tokens := tokenize(src_code);

        ast := parse_ast(tokens);
    }
    dump_ast(&ast);   
}