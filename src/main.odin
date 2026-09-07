package main;


import "core:fmt";
import "core:os";


main ::proc()
{
    compiler_options := parse_args(os.args);
    defer delete(compiler_options.parent_path);
    defer delete(compiler_options.file_name);
    src_code,ok := os.read_entire_file_from_path(compiler_options.file_name,context.allocator);
    defer delete(src_code);
    if ok != 0
    {
        errorf("error in reading file\n");
    }
    tokens := tokenize(src_code);
    defer delete(tokens);
    for token in tokens 
    {
        fmt.printf("{}\n",token);
    }

    for token in tokens 
    {
        delete(token.ident);
    }
}