program tokenize;
uses math, sysutils;

const
    TOKEN_MAX_SIZE = 255;
    OPERATOR_COUNT = 9;
    STACK_MAX_SIZE = 1000;
    EMPTY_TOKEN = '';
    OPERATOR_MAX_PRECEDENCE = 255;
type 
    TToken = string[TOKEN_MAX_SIZE];
    TTokenType = (TOKEN_TYPE_NONE, TOKEN_TYPE_OPERATOR, TOKEN_TYPE_VALUE);
    TTokenStack = array[0..STACK_MAX_SIZE] of TToken;

    TCalcFunction = function(op, operand1, operand2 : TToken) : TToken;

    TOperatorType = (OPERATOR_TYPE_UNKNOWN, OPERATOR_TYPE_UNARY, OPERATOR_TYPE_BINARY);
    TOperator = record
        value : TToken;           {string representing the operator}
        alias : TToken;           {alternative string representing the operator, which will be used in the output}
        operands : TOperatorType; {number of operands}
        precedence : integer;     {precedence}
    end;

var operators : array[0..OPERATOR_COUNT-1] of TOperator;
    operatorStack : TTokenStack;
    operatorStackPointer : integer = 0;
    operandStack : TTokenStack;
    operandStackPointer : integer = 0;
    derivativeStack : TTokenStack;
    derivativeStackPointer : integer = 0;

{Misc Utilities}
function doubleToToken(num : double) : TToken;
begin
    doubleToToken := FloatToStr(num);
end;

function tokenToDouble(token : TToken) : double;
begin
    tokenToDouble := StrToFloat(token);
end;

function isNumber(token : TToken) : boolean;
var i : integer;
begin
    isNumber := True;
    for i := 1 to length(token) do
        if not ( ((token[i] >= '0') and (token[i] <= '9')) or (token[i] = '.') ) then
            isNumber := False;
end;
{===============================}


{Stack Functions}
function pushStack(var stack : TTokenStack; var sp : integer; token : TToken) : boolean;
begin
    if sp < STACK_MAX_SIZE then
    begin
        stack[sp] := token;
        sp += 1;
        pushStack := True;
    end
    else
        pushStack := False;
end;

function popStack(var stack : TTokenStack; var sp : integer; var token : TToken) : boolean;
begin
    if sp > 0 then
    begin
        sp -= 1;
        token := stack[sp];
        stack[sp] := EMPTY_TOKEN;
        popStack := True;
    end
    else
        popStack := False;
end;

procedure clearStack(var stack : TTokenStack; var sp : integer);
var i : integer;
begin
    for i := sp downto 0 do
        stack[sp] := EMPTY_TOKEN;
    sp := 0;
end;
{===============================}


{ Token Functions }
procedure initOperators();
    procedure initOperator( var op : TOperator; 
                            value : TToken;
                            operands : TOperatorType; 
                            precedence : integer );
    begin
        op.value := value;
        op.operands := operands;
        op.precedence := precedence;
    end;
begin
    initOperator(operators[0], '(', OPERATOR_TYPE_UNARY, 1);
    initOperator(operators[1], ')', OPERATOR_TYPE_UNARY, 1);
    initOperator(operators[2], '+', OPERATOR_TYPE_BINARY, 2);
    initOperator(operators[3], '-', OPERATOR_TYPE_BINARY, 2);
    initOperator(operators[4], '*', OPERATOR_TYPE_BINARY, 3);
    initOperator(operators[5], '/', OPERATOR_TYPE_BINARY, 3);
    initOperator(operators[6], '^', OPERATOR_TYPE_BINARY, 4);
    initOperator(operators[7], 'ln', OPERATOR_TYPE_UNARY, 5);
    initOperator(operators[8], 'neg', OPERATOR_TYPE_UNARY, 6);
    
    operators[8].alias := '-';
end;  

function getPrecedence(token : TToken) : integer;
var i : integer;
begin
    getPrecedence := OPERATOR_MAX_PRECEDENCE;
    for i := 0 to OPERATOR_COUNT-1 do
        if operators[i].value = token then
        begin
            getPrecedence := operators[i].precedence;
            break;
        end;
end;

function getOperandType(token : TToken) : TOperatorType;
var i : integer;
begin
    getOperandType := OPERATOR_TYPE_UNKNOWN;
    for i := 0 to OPERATOR_COUNT-1 do
        if operators[i].value = token then
        begin
            getOperandType := operators[i].operands;
            break;
        end;
end;

function isOperator(token : TToken) : boolean;
var i : integer;
begin
    isOperator := False;
    for i := 0 to OPERATOR_COUNT-1 do
         if operators[i].value = token then
         begin
            isOperator := True;
            break;
        end;
end;

function getOperatorAlias(token : TToken) : TToken;
var i : integer;
begin
    getOperatorAlias := EMPTY_TOKEN;
    for i := 0 to OPERATOR_COUNT-1 do
         if operators[i].value = token then
         begin
            if operators[i].alias = EMPTY_TOKEN then
                getOperatorAlias := token
            else
                getOperatorAlias := operators[i].alias;
            break;
        end;
end;

{TODO: pridať argument var token : TToken, a nedovoliť niektoré veci}
function isValidValueChar(c : char) : boolean;
begin
    isValidValueChar := False;
    if (c >= '0') and (c <= '9') then
        isValidValueChar := True
    else if c = '.' then
        isValidValueChar := True
    else if c = 'x' then
        isValidValueChar := True;
end;

{TODO: opraviť pre dlhšie operátory!}
function getTokenPriority(token : TToken) : integer;
var i, p, min : integer;
    parenthesis : integer;
begin
    parenthesis := 0;
    min := OPERATOR_MAX_PRECEDENCE;

    for i := 0 to length(token) do
    begin
        if isOperator(token[i]) then
        begin
            if token[i] = '(' then
                parenthesis += 1
            else if token[i] = ')' then
                parenthesis -= 1
            else if parenthesis = 0 then
                begin
                    p := getPrecedence(token[i]);
                    if p < min then
                        min := p;
                end;
        end;
    end;

    getTokenPriority := min;
end;
{===============================}


{ Expression Functions}
{global variables!}
var expr : string;
    next : integer = 1;

procedure setExpression(e : string);
begin
    next := 1;
    expr := e;
end;

function nextToken() : TToken;
var token : TToken; 
    current_type : TTokenType;
begin
    token := EMPTY_TOKEN;
    current_type := TOKEN_TYPE_NONE;

    if next > length(expr) then
    begin
        nextToken := token;
        exit;
    end;

    while next <= length(expr)+1 do
    begin
        {set type of the new token}
        if token = EMPTY_TOKEN then
        begin
            if isValidValueChar(expr[next]) then
                current_type := TOKEN_TYPE_VALUE
            else if expr[next] <> ' ' then
                current_type := TOKEN_TYPE_OPERATOR
            else
                current_type := TOKEN_TYPE_NONE;
        end;

        {value token}
        if current_type = TOKEN_TYPE_VALUE then
        begin
            if isValidValueChar(expr[next]) then
                token += expr[next]
            else
            begin
                nextToken := token;
                exit; { do not increment i}
            end;
        end;

        {operator token}
        if current_type = TOKEN_TYPE_OPERATOR then
        begin
            if not isOperator(token) then
                token += expr[next]
            else
            begin
                nextToken := token;
                exit; { do not increment i}
            end;
        end;

        next += 1;
    end;

    nextToken := EMPTY_TOKEN;
end;
{===============================}


{Postfix Functions}
function postfix(infix : string) : string;
var token, top : TToken;
begin
    postfix := '';
    setExpression(infix);
    clearStack(operatorStack, operatorStackPointer);

    token := nextToken();
    while token <> '' do
    begin
        
        if not isOperator(token) then
            postfix += token + ' '
        else
        begin
            if token = '(' then
                pushStack(operatorStack, operatorStackPointer, token)
            else if token = ')' then
                begin
                    popStack(operatorStack, operatorStackPointer, top);
                    while top <> '(' do
                    begin
                        postfix += top + ' ';
                        popStack(operatorStack, operatorStackPointer, top);
                    end;
                end
            else
                begin
                    while (operatorStackPointer > 0) and
                          (getPrecedence(operatorStack[operatorStackPointer-1]) >= getPrecedence(token)) do
                    begin
                        popStack(operatorStack, operatorStackPointer, top);
                        postfix += top + ' ';
                    end;
                    pushStack(operatorStack, operatorStackPointer, token);
                end;
        end;

        token := nextToken();
    end;

    while operatorStackPointer > 0 do
    begin
        popStack(operatorStack, operatorStackPointer, top);
        postfix += top + ' ';
    end;
end;

function evalPostfix(postfix : string; calc : TCalcFunction) : TToken;
var token, operand1, operand2, result : TToken;
    typ : TOperatorType;
begin
    setExpression(postfix);
    clearStack(operandStack, operandStackPointer);

    token := nextToken();
    while token <> '' do
    begin
        if not isOperator(token) then
            pushStack(operandStack, operandStackPointer, token)
        else
        begin
            typ := getOperandType(token);

            if typ = OPERATOR_TYPE_UNARY then
                begin
                    popStack(operandStack, operandStackPointer, operand1);
                    
                    if calc <> NIL then
                        result := calc(token, operand1, EMPTY_TOKEN)
                    else
                        result := '(' + token + operand1 + ')';
                    writeln(token + operand1, ' = ', result);

                    pushStack(operandStack, operandStackPointer, result);
                end
            else if typ = OPERATOR_TYPE_BINARY then
                begin
                    popStack(operandStack, operandStackPointer, operand2);
                    popStack(operandStack, operandStackPointer, operand1);

                    if calc <> NIL then
                        result := calc(token, operand1, operand2)
                    else
                        result := '(' + operand1 + token + operand2 + ')';
                    writeln(operand1 + token + operand2, ' = ', result);

                    pushStack(operandStack, operandStackPointer, result);
                end;
        end;
        token := nextToken();
    end;
    popStack(operandStack, operandStackPointer, token);

    writeln('--------------');
    writeln(token);

    evalPostfix := token;
end;

function compute(op, operand1 : TToken; operand2 : TToken) : TToken; { TCalcFunction }
var result : TToken;
begin
    result := '0';
    case op of
        '+':
            result := doubleToToken( tokenToDouble(operand1) + tokenToDouble(operand2) );
        '-':
            result := doubleToToken( tokenToDouble(operand1) - tokenToDouble(operand2) );
        '*':
            result := doubleToToken( tokenToDouble(operand1) * tokenToDouble(operand2) );
        '/':
            result := doubleToToken( tokenToDouble(operand1) / tokenToDouble(operand2) );
        '^':
            result := doubleToToken( tokenToDouble(operand1) ** tokenToDouble(operand2) );
        'ln':
            result := doubleToToken( ln(tokenToDouble(operand1)) );
        'neg':
            result := doubleToToken( -tokenToDouble(operand1) );
    end;
    compute := result;
end;
{===============================}


{ Derivatives }
{put spaces around operator with thisprecedence value}
var spacing : integer = 2; 

function simplify(op, operand1, operand2 : TToken) : TToken;
var opSymbol : TToken;
begin
    {check if paranthesis are necessary for each operand}
    if getTokenPriority(operand1) < getPrecedence(op) then
        operand1 := '(' + operand1 + ')';
    if getTokenPriority(operand2) < getPrecedence(op) then
        operand2 := '(' + operand2 + ')';

    opSymbol := getOperatorAlias(op);
    
    if getOperandType(op) = OPERATOR_TYPE_BINARY then
        if getPrecedence(op) <= spacing then
            simplify := operand1 + ' ' + opSymbol + ' ' + operand2
        else
            simplify := operand1 + opSymbol + operand2
    else
        if getPrecedence(op) <= spacing then
            simplify := opSymbol + ' ' + operand1
        else
            simplify := opSymbol + operand1;

    {rewrite rules}
    if isNumber(operand1) and isNumber(operand2) then
        begin
            {evaluate}
            simplify := compute(op, operand1, operand2);
        end
    else if op = '*' then
        begin
            if operand1 = '1' then
                simplify := operand2;
            if operand2 = '1' then
                simplify := operand1;
            if (operand1 = '0') or (operand2 = '0') then
                simplify := '0';
            if (operand1 = 'x') and (operand2 = 'x') then
                simplify := 'x^2';
        end
    else if op = '+' then
    begin
        if operand1 = '0' then
            simplify := operand2;
        if operand2 = '0' then
            simplify := operand1;
        if (operand1 = 'x') and (operand2 = 'x') then
                simplify := '2*x';
    end
    else if op = '/' then
    begin
        if operand2 = '1' then
            simplify := operand1;
    end
    else if op = '^' then
    begin
        if operand2 = '1' then
           simplify := operand1; 
        if operand2 = '0' then
            simplify := '1';
    end;
end;

function differentiate(op, u, v, dudx, dvdx : TToken) : TToken;
var result : TToken;
begin
    result := '0';
    if not (isNumber(u) and isNumber(v)) then
    case op of
        '+':{d/dx(u + v) = du/dx + dv/dx}
            result := simplify('+', dudx, dvdx);
        '-':{d/dx(u + v) = du/dx - dv/dx}
            result := simplify('-', dudx, dvdx);
        '*':{d/dx(u * v) = u*dv/dx + du/dx*v}
            result := simplify( '+', simplify('*', u, dvdx), simplify('*', dudx, v) );
        '/':{d/dx(u / v) = (v*du/dx - u*dv/dx)/v^2}
            result := simplify( '/', simplify('-', simplify('*', v, dudx), simplify('*', u, dvdx)), simplify('^', v, '2') ); 
        '^':
            begin
                if isNumber(v) then { d/dx(u ^ c) = du/dx * c * u^(c - 1) }
                    result := simplify('*', dudx, simplify('*', v, simplify('^', u, simplify('-', v, '1'))))
                else { (v*u^(v-1)*du/dx)+u^v*ln(u)*dv/dx }
                    result := simplify('+',
                        simplify( '*', simplify( '*', simplify('^', u,  simplify('-', v, '1')), v), dudx),
                        simplify( '*', simplify( '*', simplify('^', u,  v), simplify('ln', u, EMPTY_TOKEN)), dvdx)
                    );
            end; 
        'ln': {d/dx(ln(u)) = du/dx / u}
            result := simplify('/', dudx, u);
        'neg':
            result := simplify('neg', dudx, EMPTY_TOKEN);
        EMPTY_TOKEN:{d/dx(c) = 0, d/dx(x) = 1}
            begin
                if u = 'x' then
                    result := '1'
                else
                    result := '0';
            end;
    end;
    differentiate := result;
end;

function differentiatePostfix(postfix : string) : TToken;
var token, operand1, operand2, derivative1, derivative2, f, dfdx : TToken;
    typ : TOperatorType;
begin
    setExpression(postfix);
    clearStack(operandStack, operandStackPointer);
    clearStack(derivativeStack, derivativeStackPointer);

    token := nextToken();
    while token <> '' do
    begin
        if not isOperator(token) then
            begin
                pushStack(operandStack, operandStackPointer, token);
                pushStack(derivativeStack, derivativeStackPointer, differentiate(EMPTY_TOKEN, token, EMPTY_TOKEN, EMPTY_TOKEN, EMPTY_TOKEN));
            end
        else
            begin
                typ := getOperandType(token);

                if typ = OPERATOR_TYPE_UNARY then
                    begin
                        popStack(operandStack, operandStackPointer, operand1);
                        popStack(derivativeStack, derivativeStackPointer, derivative1);

                        f := token + '(' + operand1 + ')';
                        dfdx := differentiate(token, operand1, EMPTY_TOKEN, derivative1, EMPTY_TOKEN);
                        
                        pushStack(operandStack, operandStackPointer, f);
                        pushStack(derivativeStack, derivativeStackPointer, dfdx);
                    end
                else if typ = OPERATOR_TYPE_BINARY then
                    begin
                        popStack(operandStack, operandStackPointer, operand2);
                        popStack(operandStack, operandStackPointer, operand1);
                        popStack(derivativeStack, derivativeStackPointer, derivative2);
                        popStack(derivativeStack, derivativeStackPointer, derivative1);

                        f := simplify(token, operand1, operand2);
                        dfdx := differentiate(token, operand1, operand2, derivative1, derivative2);

                        //writeln(token, ' ', operand1, ' ', operand2, ' ', derivative1, ' ', derivative2);
                        //writeln('f(x) = ', f:20, '  f''(x) = ', dfdx );                     
                        
                        pushStack(operandStack, operandStackPointer, f);
                        pushStack(derivativeStack, derivativeStackPointer, dfdx);
                    end;
            end;
        token := nextToken();
    end;
    popStack(derivativeStack, derivativeStackPointer, token);
    differentiatePostfix := token;
end;
{===============================}


{main procedure}
var str : string;
begin
    initOperators();

    
    //str := 'x*ln(x^3 + 2) + x*2^4';
    str := 'x^x';
    writeln();
    write('d/dx ', str, ' = ');

    str := postfix(str);
    //writeln(str);
    writeln(differentiatePostfix(str));

    writeln();

    
end.