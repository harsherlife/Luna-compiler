package main;



TermIdent :: struct
{
    ident : Token
};

TermLiteral :: struct
{
    lit : Token
};

TermFunCall :: struct
{
    func_name : Token,
    args : [dynamic]^Expr,
};

Term :: union
{
    TermIdent,
    TermLiteral,
    TermFunCall,
};

BinExprAssign :: struct
{
    lhs,rhs : ^Expr
};


BinExprAdd :: struct
{
    lhs,rhs : ^Expr
};

BinExprSub :: struct
{
    lhs,rhs : ^Expr
};

BinExprMult :: struct
{
    lhs,rhs : ^Expr
};

BinExprDiv :: struct
{
    lhs,rhs : ^Expr
};

BinExpr :: union
{
    ^BinExprAssign,
    ^BinExprAdd,
    ^BinExprSub,
    ^BinExprMult,
    ^BinExprDiv,
};

Expr :: union
{
    ^Term,
    ^BinExpr,
};

DeclStmt :: struct
{
    ident : Token,
    expr : ^Expr,
    type : string
};

AssignStmt :: struct
{
    ident : Token,
    expr : ^Expr,
};

Stmt :: union
{
    AssignStmt,
    DeclStmt,
    Expr,
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

try_peek_parser :: proc(parser : ^Parser,type : TokenType, offset : uint = 0) -> bool
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

try_consume_tok :: proc(parser: ^Parser,type : TokenType) -> bool
{
    if try_peek_parser(parser,type)
    {
        consume_parser(parser);
        return true;
    }
    return false;
}

try_consume :: proc(parser : ^Parser,type : TokenType) -> (Token,bool)
{
    if peek_parser(parser).type == type
    {
        return consume_parser(parser),true;
    }
    return {},false;
}


parse_term :: proc(parser : ^Parser) -> ^Term
{
    term : ^Term;
    if try_peek_parser(parser,TokenType.ident)
    {
        term = alloc_and_set(Term,TermIdent{consume_parser(parser)});
    }
    else if try_peek_parser(parser,TokenType.int_literal)
    {
        term = alloc_and_set(Term,TermLiteral{consume_parser(parser)});
    }
    else if try_peek_parser(parser,TokenType.function_call)
    {
        func := TermFunCall{func_name = consume_parser(parser)};
        try_consume_err(parser,TokenType.open_paren,"Expected (\n");
        for !try_consume_tok(parser,TokenType.close_paren)
        {
            append(&func.args,parse_expr(parser));
        }
        term = alloc_and_set(Term,func); 
    }
    else {}
    return term;
}


precedence :[][]TokenType = {{TokenType.assignment},{TokenType.plus,TokenType.minus},{TokenType.mult,TokenType.div}};

get_precedence :: proc (type : TokenType) -> i32
{
    idx : i32 = 0;
    for &slice in precedence
    {
        for &slice_type in slice
        {
            if type == slice_type
            {
                return idx;
            }
        }
        idx += 1;
    }
    return -1;

}


parse_expr :: proc(parser : ^Parser,prec : i32 = 0) -> ^Expr
{
    term := parse_term(parser);
    lhs_expr := alloc_and_set(Expr,term);
    for 
    {
        tok,ok := peek_parser(parser);
        curr_prec := get_precedence(tok.type);
        if ok && curr_prec != -1  && curr_prec >=  prec
        {
            op_type := consume_parser(parser).type;
            rhs_expr := parse_expr(parser,curr_prec + 1);
            bin_expr : ^BinExpr;
            if rhs_expr != nil
            {
                #partial switch op_type
                {
                    case TokenType.plus :
                    {
                        bin_expr_add := alloc_and_set(BinExprAdd,BinExprAdd{lhs = lhs_expr,rhs = rhs_expr});
                        bin_expr = alloc_and_set(BinExpr,bin_expr_add);
                    }
                    case TokenType.minus :
                    {
                        bin_expr_sub := alloc_and_set(BinExprSub,BinExprSub{lhs = lhs_expr,rhs = rhs_expr});
                        bin_expr = alloc_and_set(BinExpr,bin_expr_sub);
                    }
                    case TokenType.mult:
                    {
                        bin_expr_mult := alloc_and_set(BinExprMult,BinExprMult{lhs = lhs_expr,rhs = rhs_expr});
                        bin_expr = alloc_and_set(BinExpr,bin_expr_mult);
                    }
                    case TokenType.div:
                    {
                        bin_expr_div := alloc_and_set(BinExprDiv,BinExprDiv{lhs = lhs_expr,rhs = rhs_expr});
                        bin_expr = alloc_and_set(BinExpr,bin_expr_div);
                    }
                    case TokenType.assignment:
                    {
                        bin_expr_assign := alloc_and_set(BinExprAssign,BinExprAssign{lhs = lhs_expr,rhs = rhs_expr});
                        bin_expr = alloc_and_set(BinExpr,bin_expr_assign);                       
                    }
                    case :
                        errorf("Unreachable\n");
                }
                lhs_expr = alloc_and_set(Expr,bin_expr);
            }
            else
            {
                errorf("Expected expression\n");
            }
        }
        else 
        {
            break;
        }
    }
    return lhs_expr;
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
        append(&func.stmts,DeclStmt{ident = ident,expr = parse_expr(parser),type = type.ident});
        try_consume_err(parser,TokenType.semicolon,"expected semicolon\n");
        return true;
    }
    else 
    {
        errorf("type {} not supported yet ", type.ident);
    }
}


parse_stmt_expr :: proc(parser : ^Parser,func : ^Func) -> bool
{
    expr := parse_expr(parser);
    if expr != nil
    {
        append(&func.stmts,expr^);
        try_consume_err(parser,TokenType.semicolon,"Expected ;\n");
        return true;
    }
    return try_consume_tok(parser,TokenType.semicolon); // ; alone is a valid statement and not an expr so no need to add to stmts
}

parse_stmt :: proc(parser : ^Parser,func : ^Func)
{
    if parse_decl_stmt(parser,func)
    {
        return;
    }
    else if parse_stmt_expr(parser,func)
    {
        return;
    }
    errorf("Can't parse statement\n");
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


dump_term :: proc(term : ^Term) 
{
    switch t in term
    {
        case TermIdent :
        {
            fmt.printf("{}",t.ident.ident);
        }
        case TermLiteral : 
        {
            fmt.printf("{}",t.lit.ident);
        }
        case TermFunCall :
        {
            fmt.printf("Function Call {} (",t.func_name.ident);
            for expr in t.args
            {
                dump_expr(expr);
                fmt.printf(" ");
            }
            fmt.printf(")");
        }
    }
}

dump_bin_expr_assign :: proc(bin_expr : ^BinExprAssign)
{
    fmt.printf("(=, lhs = ")
    dump_expr(bin_expr.lhs);
    fmt.printf(" ,rhs = ");
    dump_expr(bin_expr.rhs);
    fmt.printf(")");
}

dump_bin_expr_add :: proc(bin_expr : ^BinExprAdd)
{
    fmt.printf("(+, lhs = ")
    dump_expr(bin_expr.lhs);
    fmt.printf(" ,rhs = ");
    dump_expr(bin_expr.rhs);
    fmt.printf(")");
}

dump_bin_expr_sub :: proc(bin_expr : ^BinExprSub)
{
    fmt.printf("(-, lhs = ")
    dump_expr(bin_expr.lhs);
    fmt.printf(" ,rhs = ");
    dump_expr(bin_expr.rhs);
    fmt.printf(")");
}

dump_bin_expr_mult :: proc(bin_expr : ^BinExprMult)
{
    fmt.printf("(*, lhs = ")
    dump_expr(bin_expr.lhs);
    fmt.printf(" ,rhs = ");
    dump_expr(bin_expr.rhs);
    fmt.printf(")");
}


dump_bin_expr_div :: proc(bin_expr : ^BinExprDiv)
{
    fmt.printf("(/, lhs = ")
    dump_expr(bin_expr.lhs);
    fmt.printf(" ,rhs = ");
    dump_expr(bin_expr.rhs);
    fmt.printf(")");
}

dump_bin_expr :: proc(bin_expr : ^BinExpr) 
{
    switch v in bin_expr
    {
        case ^BinExprAssign:
        {
            dump_bin_expr_assign(v);
        }
        case ^BinExprAdd:
        {
            dump_bin_expr_add(v);
        }
        case ^BinExprSub:
        {
            dump_bin_expr_sub(v);
        }
        case ^BinExprMult :
        {
            dump_bin_expr_mult(v);
        }
        case ^BinExprDiv:
        {
            dump_bin_expr_div(v);
        }
    }
}

dump_expr :: proc(expr : ^Expr)
{
    switch v in expr
    {
        case ^Term:
        {
            dump_term(v);
        }
        case ^BinExpr:
        {
            dump_bin_expr(v);
        }
    }
}

dump_stmt :: proc(stmt : ^Stmt)
{
    switch &st in stmt
    {
        case DeclStmt:
        {
            fmt.printf("{} {} = ",st.type,st.ident.ident);
            dump_expr(st.expr);
            fmt.printf("\n");
        }
        case AssignStmt:
        {
            fmt.printf("{} = ",st.ident.ident);
            dump_expr(st.expr);
            fmt.printf("\n");
        }
        case Expr :
        {
            dump_expr(&st);
            fmt.printf("\n");
        }
    }
}

dump_ast :: proc(ast : ^AST)
{
    for &func in ast.funcs
    {
        fmt.printf("function : {} {}\n",func.func_name,len(func.stmts));
        for &stmt in func.stmts
        {
            dump_stmt(&stmt);
        }
    }
}