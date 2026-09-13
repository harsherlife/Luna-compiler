package main;



TermIdent :: struct
{
    ident : Token
};

TermLiteral :: struct
{
    lit : Token
};

Term :: union
{
    TermIdent,
    TermLiteral,
};

DeclStmt :: struct
{
    ident : Token,
    expr : Term,
    type : string
}

AssignStmt :: struct
{
    ident : Token,
    expr : Term
};

Stmt :: union
{
    AssignStmt,
    DeclStmt
};

Stmts :: [dynamic]Stmt;

Func :: struct
{
    stmts: Stmts,
    func_name : string
};

Funcs :: [dynamic]Func;

AST :: struct 
{
    funcs : Funcs,
};


Parser :: struct
{
    idx,len : uint,
    tokens : Tokens,
};

try_peek_parser :: proc(parser : ^Parser,type : TokenType, offset :uint = 0) -> bool
{
    tok,ok := peek_parser(parser,offset);
    return ok && tok.type == type;
}

peek_parser :: proc(parser : ^Parser, offset : uint = 0) -> (Token,bool) #optional_ok
{
    if parser.idx+offset >= parser.len 
    {
        return {},false;
    }
    return parser.tokens[parser.idx+offset],true;
}


consume_parser :: proc(parser : ^Parser) -> Token
{
    ret := parser.tokens[parser.idx];
    parser.idx += 1;
    return ret;
}


try_consume_err :: proc(parser : ^Parser,type : TokenType,err_msg : string) -> Token
{
    if peek_parser(parser).type == type 
    {
        return consume_parser(parser);
    }
    errorf(err_msg);
}

try_consume :: proc(parser : ^Parser,type : TokenType) -> (Token,bool)
{
    if peek_parser(parser).type == type
    {
        return consume_parser(parser),true;
    }
    return {},false;
}


parse_term :: proc(parser : ^Parser) -> (Term,bool) #optional_ok
{
    if try_peek_parser(parser,TokenType.ident)
    {
        return TermIdent{consume_parser(parser)},true;
    }
    else if try_peek_parser(parser,TokenType.int_literal)
    {
        return TermLiteral{consume_parser(parser)},true;
    }
    else 
    {
        return {},false;
    }
}


parse_decl_stmt :: proc(parser : ^Parser,func : ^Func) -> bool 
{
    if try_peek_parser(parser,TokenType.type) == false
    {
        return false;
    }
    type := consume_parser(parser);
    if type.ident == "i32"
    {
        ident := try_consume_err(parser,TokenType.ident,"Expected identifier\n");
        try_consume_err(parser,TokenType.assignment,"Expected assignment\n");
        append(&func.stmts,DeclStmt{ident = ident,expr = parse_term(parser),type = type.ident});
        try_consume_err(parser,TokenType.semicolon,"expected semicolon\n");
        return true;
    }
    else 
    {
        errorf("type {} not supported yet ", type.ident);
    }
}


parse_assign_stmt :: proc(parser : ^Parser, func : ^Func) -> bool
{
    term,ok1 := parse_term(parser);
    if !ok1 || !try_peek_parser(parser,TokenType.assignment)
    {
        return false;
    }
    tok,ok := term.(TermLiteral);
    if ok
    {
        errorf("Can't assign to literal\n");
    }
    consume_parser(parser);
    append(&func.stmts,AssignStmt{ident = term.(TermIdent).ident, expr = parse_term(parser)});
    try_consume_err(parser,TokenType.semicolon,"Expected ;\n");
    return true;
}

parse_stmt :: proc(parser : ^Parser,func : ^Func)
{
    if parse_decl_stmt(parser,func)
    {
        return;
    }
    else if parse_assign_stmt(parser,func)
    {
        return;
    }
    else 
    {
        errorf("Can't parse statement\n");
    }
}

parse_function :: proc(parser : ^Parser) -> Func
{
    if try_peek_parser(parser,TokenType.function)
    {
        consume_parser(parser); // fn token
        func_name := consume_parser(parser);
        func := Func{func_name = func_name.ident};

        try_consume_err(parser,TokenType.open_paren,"expected (\n");
        try_consume_err(parser,TokenType.close_paren,"expected )\n");
        try_consume_err(parser,TokenType.open_brace,"expected {\n");
        for 
        {
            tok,ok := try_consume(parser,TokenType.close_brace);
            if ok
            {
                break;
            }
            parse_stmt(parser,&func);
        }
        return func;
    }
    else 
    {
        errorf("Expected function \n");
    }
}


parse_ast :: proc(tokens : Tokens) -> AST
{
    parser := Parser{tokens = tokens,len = len(tokens)};
    ast := AST{};
    for 
    {
        tok,ok := peek_parser(&parser);
        if !ok
        {
            break;
        }
        append(&ast.funcs,parse_function(&parser));
    }
    return ast;
}
import "core:fmt";
dump_ast :: proc(ast : ^AST)
{
    for func in ast.funcs
    {
        fmt.printf("function : {}\n",func.func_name);
        for stmt in func.stmts
        {
            fmt.printf("{}\n",stmt);
        }
    }
}