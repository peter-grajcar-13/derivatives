program infix_to_postfix;

const STACK_SIZE = 1000;
      MAX_OPERATOR_LENGTH = 3;

type TOperator = string[MAX_OPERATOR_LENGTH];
     TOperatorType = (UNARY, BINARY);

var operatorStack : array[0..STACK_SIZE] of TOperator;
    operatorStackPointer : integer;
    operandStack : array[0..STACK_SIZE] of string;
    operandStackPointer : integer;

function pushOperator(op : TOperator) : boolean;
begin
    if operatorStackPointer <= STACK_SIZE then
    begin
        operatorStack[operatorStackPointer] := op;
        operatorStackPointer += 1;
        pushOperator := True;
    end
    else
        pushOperator := False;
end;
 
function popOperator(var op : TOperator) : boolean;
begin
    if operatorStackPointer > 0 then
    begin
        operatorStackPointer -= 1;
        op := operatorStack[operatorStackPointer];
        operatorStack[operatorStackPointer] := #0;
        popOperator := True;
    end
    else
        popOperator := False;
end;

function pushOperand(op : string) : boolean;
begin
    if operandStackPointer <= STACK_SIZE then
    begin
        operandStack[operandStackPointer] := op;
        operandStackPointer += 1;
        pushOperand := True;
    end
    else
        pushOperand := False;
end;
 
function popOperand(var op : string) : boolean;
begin
    if operandStackPointer > 0 then
    begin
        operandStackPointer -= 1;
        op := operandStack[operandStackPointer];
        operandStack[operandStackPointer] := #0;
        popOperand := True;
    end
    else
        popOperand := False;
end;

function precedence(op : TOperator) : integer;
begin
    precedence := 10;
    case op of
        'ln': precedence := 5;
        '^': precedence := 4;
        '*': precedence := 3;
        '/': precedence := 3;
        '+': precedence := 2;
        '-': precedence := 2;
        '(': precedence := 1;
        ')': precedence := 1;
    end;
end;

function isOperator(op : TOperator) : boolean;
begin
    isOperator := False;
    case op of
        'ln': isOperator := True;
        '^': isOperator := True;
        '*': isOperator := True;
        '/': isOperator := True;
        '+': isOperator := True;
        '-': isOperator := True;
        '(': isOperator := True;
        ')': isOperator := True;
    end;
end;

function operatorType(op : TOperator) : TOperatorType;
begin
    operatorType := UNARY;
    case op of
        'ln': operatorType := UNARY;
        '^': operatorType := BINARY;
        '*': operatorType := BINARY;
        '/': operatorType := BINARY;
        '+': operatorType := BINARY;
        '-': operatorType := BINARY;
        '(': operatorType := BINARY;
        ')': operatorType := BINARY;
    end;
end;

function postfix(infix : string) : string;
var i, j : integer;
    c, top : TOperator;
    out : string;
begin
    out := '';
    i := 1;
    while i <= length(infix) do
    begin
        c := infix[i];

        if (c >= 'A') and (c <= 'Z') then
            out += c + ' '
        else 
        begin
            while not isOperator(c) do
            begin
                i += 1;
                c += infix[i];
            end;

            if c = '(' then
                pushOperator(c)
            else if c = ')' then
                begin
                    popOperator(top);
                    while top <> '(' do
                    begin
                        out += top + ' ';
                        popOperator(top);
                    end;
                end
            else
                begin
                    while (operatorStackPointer > 0) and (precedence(operatorStack[operatorStackPointer-1]) >= precedence(c)) do
                    begin
                        popOperator(top);
                        out += top + ' ';
                    end;
                    pushOperator(c);
                end;
        end;

        i += 1;
    end;

    while (operatorStackPointer > 0) do
    begin
        popOperator(top);
        out += top + ' ';
    end;

    postfix := out;
end;

procedure evalPostfix(postfix : string);
var i : integer;
    c : TOperator;
    operand1, operand2 : string;
begin
    i := 1;
    while i <= length(postfix) do
    begin
        c := postfix[i];
        if (c >= 'A') and (c <= 'Z') then
            pushOperand(c)
        else if c <> ' ' then
        begin
            while not isOperator(c) do
            begin
                i += 1;
                c += postfix[i];
            end;

            if operatorType(c) = BINARY then
            begin
                popOperand(operand2);
                popOperand(operand1);
                writeln('(' + operand1 + c + operand2 + ')');
                pushOperand('(' + operand1 + c + operand2 + ')');
            end
            else
            begin
                popOperand(operand1);
                writeln('(' + c + operand1 + ')');
                pushOperand('(' + c + operand1 + ')');
            end;

        end;

        i += 1;
    end;
    popOperand(operand1);
    writeln(operand1);
end;

{procedure reverseExpr(var expr : string);
var str : string;
    i : integer;
begin
    str := '';
    for i := 1 to length(expr) do
    begin
        if expr[i] = '(' then
            str := ')' + str
        else if expr[i] = ')' then
            str := '(' + str
        else
            str := expr[i] + str;
    end;
    expr := str;
end;}

var expr : string;
    post : string;
begin
    write('infix: ');
    readln(expr);

    writeln('------------------------');
    write('postfix: ');
    post := postfix(expr);
    writeln(post);
    evalPostfix(post);
end.