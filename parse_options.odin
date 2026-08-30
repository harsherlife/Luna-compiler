package main;


import "core:fmt";
import "core:path/filepath";
import "core:path/slashpath";
import "core:os";
import "core:strings";

errorf :: proc(format_str : string,format_args : ..any)
{
    fmt.printf(format_str,..format_args);
    os.exit(1);
}

Arch :: enum 
{
    Linux_X86_64,
    Windows_X86_64,
};

Compiler_Options :: struct
{
    file_name : string,
    parent_path : string,
    target_arch : Arch,
};
parse_args :: proc(args : []string) -> Compiler_Options
{
    if(len(args) < 2) {
        errorf("Not enough arguments provided \n");
    }
    options : Compiler_Options = {file_name = strings.clone(args[1])};
    full_path,_ := filepath.abs(args[1]);
    options.parent_path = os.dir(full_path);
    return options;
}