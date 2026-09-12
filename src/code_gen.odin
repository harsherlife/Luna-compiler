package main;

import "core:strings";
import "core:fmt";

Generator :: struct
{
    idx,len : uint,
    tokens : Tokens,
    vars : map[string]int,
};


peek_generator :: proc(gen : ^Generator, offset : uint = 0) -> (Token,bool) #optional_ok
{
    if gen.idx+offset >= gen.len 
    {
        return {},false;
    }
    return gen.tokens[gen.idx+offset],true;
}


consume_generator :: proc(gen : ^Generator) -> Token
{
    ret := gen.tokens[gen.idx];
    gen.idx += 1;
    return ret;
}


try_consume_err :: proc(gen : ^Generator,type : TokenType,err_msg : string) -> Token
{
    if peek_generator(gen).type == type 
    {
        return consume_generator(gen);
    }
    errorf(err_msg);
    return {}; // will never be called hehe
}

try_consume :: proc(gen : ^Generator,type : TokenType) -> (Token,bool)
{
    if peek_generator(gen).type == type
    {
        return consume_generator(gen),true;
    }
    return {},false;
}


generate_decl :: proc(gen : ^ Generator,buff : ^strings.Builder) -> bool
{
    if peek_generator(gen).type == TokenType.auto || peek_generator(gen).type == TokenType.type
    {
        tok := consume_generator(gen);
        var := try_consume_err(gen,TokenType.ident,"expected identifier");
        gen.vars[var.ident] = len(gen.vars)+1;
        if tok.type == TokenType.auto
        {
            _ ,ok := try_consume(gen,TokenType.assignment);
            if ok
            {
                
                lit := try_consume_err(gen,TokenType.int_literal,"only support integer literals in assignment for now");
                fmt.sbprintf(buff,"    movl ${},-{},%%rax",lit.ident,gen.vars[var.ident]*4);
            }
            try_consume_err(gen,TokenType.semicolon,"Expected semicolon\n");
        }
        else if tok.ident == "i32"
        {
            errorf("TODO\n");
        }
        else
        {
            errorf("type {} not supported yet\n",tok.ident);
        }
    }
    return true;
}


generate_assign :: proc(gen : ^Generator,buff : ^strings.Builder) -> bool
{
    errorf("TODO : Assignments to declared variables\n");
    return false;
}

generate_stmt :: proc(gen : ^Generator,buff : ^strings.Builder)
{
    if generate_decl(gen,buff)
    {
        return;
    }
    else if  generate_assign(gen,buff)
    {
        return;
    }
    else 
    {
        errorf("can't parse this statement yet\n");
    }
}


generate_prologue_func :: proc(buff : ^strings.Builder)
{
    fmt.sbprintf(buff,"    push %%rbp\n");
    fmt.sbprintf(buff,"    mov %%rsp,%%rbp\n");
}

generate_epilogue_func :: proc(buff : ^strings.Builder)
{
    fmt.sbprintf(buff,"    pop %%rbp\n");
    fmt.sbprintf(buff,"    ret\n");
}


generate :: proc(tokens : Tokens) -> string
{
    buff := strings.Builder{};
    gen := Generator{tokens = tokens, idx = 0,len = len(tokens),vars = make(map[string](int))};
    defer delete(gen.vars);

    try_consume_err(&gen,TokenType.function,"expected function declaration\n");

    fmt.sbprintf(&buff,"{}:\n",consume_generator(&gen).ident);
    fmt.sbprintf(&buff,"    endbr64\n");
    try_consume_err(&gen,TokenType.open_paren,"expected (\n");
    try_consume_err(&gen,TokenType.close_paren,"expected )\n");
    try_consume_err(&gen,TokenType.open_brace,"expected {\n");
    generate_prologue_func(&buff);
    for
    {
        tok,ok := try_consume(&gen,TokenType.close_brace);
        if ok
        {
            break;
        }
        generate_stmt(&gen,&buff);
    }
    generate_epilogue_func(&buff);
    return strings.to_string(buff);
}