package main;

import "core:c/libc";
import "core:strings";
import "core:fmt";

TokenType :: enum 
{
    open_paren,
    close_paren,
    open_brace,
    close_brace,
    ident,
    int_literal,
    string_literal,
    float_literal,
    double_literal,
}

Loc :: struct
{
    row_number,offset : uint
}

Token :: struct
{
    type : TokenType,
    ident : string,
    loc : Loc,
}

Tokens :: [dynamic]Token;

Tokenizer :: struct
{
    idx,len : uint,
    row,start_of_row : uint,
    source_code : []u8
}

get_loc :: proc(tokenizer : ^Tokenizer,buff_len : uint) -> Loc
{
    return {tokenizer.row+1,tokenizer.idx-tokenizer.start_of_row-buff_len+1};
}

peek :: proc(tokenizer : ^Tokenizer,offset : uint = 0) -> u8
{
    if tokenizer.idx+offset >= tokenizer.len 
    {
        return 0;
    }
    return tokenizer.source_code[tokenizer.idx+offset];
}

consume :: proc(tokenizer : ^Tokenizer) -> u8
{
    ret := tokenizer.source_code[tokenizer.idx];
    tokenizer.idx += 1;
    return ret;
}

tokenize :: proc(source_code : []u8) -> Tokens
{
    tokens := Tokens{};
    tokenizer := Tokenizer{len = len(source_code),source_code = source_code};
    buff := strings.Builder{};
    for peek(&tokenizer) != 0 
    {
        if libc.isalpha(cast(i32)peek(&tokenizer)) != 0
        {
            strings.write_byte(&buff,consume(&tokenizer));
            for libc.isalpha(cast(i32)peek(&tokenizer)) != 0
            {
                strings.write_byte(&buff,consume(&tokenizer));
            }
            str := strings.to_string(buff);
            append(&tokens,Token{type = TokenType.ident, ident = str, loc = get_loc(&tokenizer,len(str))})
        }
        else if libc.isdigit(cast(i32)peek(&tokenizer)) != 0
        {
            strings.write_byte(&buff,consume(&tokenizer));
            for libc.isdigit(cast(i32)peek(&tokenizer)) != 0
            {
                strings.write_byte(&buff,consume(&tokenizer));
            }
            if peek(&tokenizer) == '.'
            {   
                strings.write_byte(&buff,consume(&tokenizer));
                for libc.isdigit(cast(i32)peek(&tokenizer)) != 0
                {
                    strings.write_byte(&buff,consume(&tokenizer));
                }
                str := strings.to_string(buff);
                append(&tokens,Token{type=TokenType.double_literal, ident = str , loc = get_loc(&tokenizer,len(str))});
                if peek(&tokenizer) == 'f'
                {
                    tokens[len(tokens)-1].type = TokenType.float_literal;
                    consume(&tokenizer);
                }
            }
            else 
            {
                str := strings.to_string(buff);
                append(&tokens,Token{type=TokenType.int_literal, ident = str , loc = get_loc(&tokenizer,len(str))});
            }
        }
        else if peek(&tokenizer) == '\n'
        {
            consume(&tokenizer);
            tokenizer.row += 1;
            tokenizer.start_of_row = tokenizer.idx;
        }
        else 
        {
            consume(&tokenizer);
        }
        buff = {};
    }
    return tokens;
}