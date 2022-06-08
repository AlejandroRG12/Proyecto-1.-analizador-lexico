D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{
#include <stdio.h>
#include "y.tab.h"
#include <stdlib.h>

enum{
	VOIDVAL=0,
	CHARVAL,
	INTVAL,
	DOUBLEVAL
};

char buffer[10000];
int bufsize;
int column = 0;
int lineo = 0;


void count();
void comment();
int yylex();
%}

%option noyywrap
%x INCHAR INSTRING
%%
"/*"			{ comment(); }

"auto"			{ count(); return(AUTO); }
"break"			{ count(); return(BREAK); }
"case"			{ count(); return(CASE); }
"char"			{ count(); return(CHAR); }
"const"			{ count(); return(CONST); }
"continue"		{ count(); return(CONTINUE); }
"default"		{ count(); return(DEFAULT); }
"do"			{ count(); return(DO); }
"double"		{ count(); return(DOUBLE); }
"else"			{ count(); return(ELSE); }
"enum"			{ count(); return(ENUM); }
"extern"		{ count(); return(EXTERN); }
"float"			{ count(); return(FLOAT); }
"for"			{ count(); return(FOR); }
"goto"			{ count(); return(GOTO); }
"if"			{ count(); return(IF); }
"int"			{ count(); return(INT); }
"long"			{ count(); return(LONG); }
"register"		{ count(); return(REGISTER); }
"return"		{ count(); return(RETURN); }
"short"			{ count(); return(SHORT); }
"signed"		{ count(); return(SIGNED); }
"sizeof"		{ count(); return(SIZEOF); }
"static"		{ count(); return(STATIC); }
"struct"		{ count(); return(STRUCT); }
"switch"		{ count(); return(SWITCH); }
"typedef"		{ count(); return(TYPEDEF); }
"union"			{ count(); return(UNION); }
"unsigned"		{ count(); return(UNSIGNED); }
"void"			{ count(); return(VOID); }
"volatile"		{ count(); return(VOLATILE); }
"while"			{ count(); return(WHILE); }

{L}({L}|{D})*		{
                        yylval.name = strdup(yytext); 
                        count(); 
                        return(IDENTIFIER); 
                    }

0[xX]{H}+{IS}?		{ 
                        yylval.ival = strtol(yytext, NULL, 16);
                        yylval.valtype = INTVAL;
                        count(); 
                        return(CONSTANT); 
                    }
0{D}+{IS}?		{ 
                    yylval.ival = strtol(yytext, NULL, 8);
                    yylval.valtype = INTVAL;
                    count();
                    return(CONSTANT);
                }
{D}+{IS}?		{   
                    yylval.ival = atol(yytext);
                    yylval.valtype = INTVAL;
                    count();
                    return(CONSTANT);
                }
L?'         	{ 
                    count();
                    BEGIN(INCHAR);
                    buffer[0] = '\0';
                    bufsize = 0;
                }
<INCHAR>(\\0[0-7]*) {
                        int val;
                        if(bufsize>0){
                            printf("ERROR: line %d comun %d multibyte char constant!\n",lineo + 1 , column);
                            exit(2);
                        }
                        val = strtol(yytext + 1, NULL, 8);
                        if(val > 255){
                            printf("ERROR: line %d comun %d multibyte char constant!\n",lineo + 1 , column);
                            exit(2);
                        }
                        count;
                        buffer[0] = val;
                        bufsize++;
                    }
<INCHAR>(\\x[0-9a-fA-F]+)   {
						int val;
						if(bufsize>0)
						{
							 printf("ERROR: line %d comun %d multibyte char constant!\n",lineo + 1 , column);
							exit(2);
						}
						val = strtol(yytext + 2, NULL, 16);
						if(val > 255){
							 printf("ERROR: line %d comun %d multibyte char constant!\n",lineo + 1 , column);
							exit(2);
						}
						count();
						buffer[0] = val;
						bufsize++;
						}
<INCHAR>(\\.)       {
                        if(bufsize>0){
                            printf("ERROR: line %d comun %d multibyte char constant!\n",lineo + 1 , column);
                            exit(2);
                        }
                        count();
                        switch(yytext[1]){
                            case 'a':
                                buffer[0] = '\a';
                                break;
                            case 'b':
                                buffer[0] = '\b';
                                break;
                            case 'f':
                                buffer[0] = '\f';
                                break;
                            case 'n':
                                buffer[0] = '\n';
                                break;
                            case 't':
                                buffer[0] = '\t';
                                break;
                            case 'r':
                                buffer[0] = '\r';
                                break;
                            case 'v':
                                buffer[0] = '\v';
                                break;
                            default:
                                buffer[0] = yytext[1];
                                break;
                            
                        }
                        bufsize++;
                    }
<INCHAR>([^\\'])    {
                        if(bufsize>0){
                            printf("ERROR: line %d comun %d multibyte char constant!\n",lineo + 1 , column);
                            exit(2);
                        }
                        count;
                        buffer[0] = yytext[0];
                        bufsize++;
                    }
<INCHAR>'           {
                        count();
                        BEGIN(INITIAL);
                        yylval.cval = buffer[0];
                        yylval.valtype = CHARVAL;
                        return(CONSTANT);
                    }


{D}+{E}{FS}?		{       
                            yylval.dval = atof(yytext);
							yylval.valtype = DOUBLEVAL;
							count(); 
							return(CONSTANT); 
                    }
{D}*"."{D}+{E}?{FS}?	{  
                            yylval.dval = atof(yytext);
							yylval.valtype = DOUBLEVAL;
							count(); 
							return(CONSTANT); 
                        }
{D}+"."{D}*{E}?{FS}?	{  
                            yylval.dval = atof(yytext);
							yylval.valtype = DOUBLEVAL;
							count(); 
							return(CONSTANT); 
                        }


L?\"	                {   
                            count(); 
                            BEGIN(INSTRING);
                            buffer[0] = '\0';
                            bufsize = 0;
                        }

<INSTRING>(\\0[0-7]*) {
                        int val;
                        val = strtol(yytext + 1, NULL, 8);
                        if(val > 255){
                            printf("ERROR: line %d comun %d multibyte char constant!\n",lineo + 1 , column);
                            exit(2);
                        }
                        count;
                        buffer[bufsize] = val;
                        bufsize++;
                    }
<INSTRING>(\\x[0-9a-fA-F]+) {
						int val;
						val = strtol(yytext + 2, NULL, 16);
						if(val > 255){
							 printf("ERROR: line %d comun %d multibyte char constant!\n",lineo + 1 , column);
							exit(2);
						}
						count();
						buffer[bufsize] = val;
						bufsize++;
						}
<INSTRING>(\\.)       {
                        count();
                        switch(yytext[1]){
                            case 'a':
                                buffer[bufsize] = '\a';
                                break;
                            case 'b':
                                buffer[bufsize] = '\b';
                                break;
                            case 'f':
                                buffer[bufsize] = '\f';
                                break;
                            case 'n':
                                buffer[bufsize] = '\n';
                                break;
                            case 't':
                                buffer[bufsize] = '\t';
                                break;
                            case 'r':
                                buffer[bufsize] = '\r';
                                break;
                            case 'v':
                                buffer[bufsize] = '\v';
                                break;
                            default:
                                buffer[bufsize] = yytext[1];
                                break;
                                        }
                    bufsize++;
                     }
<INSTRING>([^\\"])    {
                        count;
                        buffer[bufsize] = yytext[0];
                        bufsize++;
                    }
<INSTRING>\"           {
                        count();
                        BEGIN(INITIAL);
                        yylval.sval = strdup(buffer);
                        return(STRING_LITERAL);
                    }


"..."			{ count(); return(ELLIPSIS); }
">>="			{ count(); return(RIGHT_ASSIGN); }
"<<="			{ count(); return(LEFT_ASSIGN); }
"+="			{ count(); return(ADD_ASSIGN); }
"-="			{ count(); return(SUB_ASSIGN); }
"*="			{ count(); return(MUL_ASSIGN); }
"/="			{ count(); return(DIV_ASSIGN); }
"%="			{ count(); return(MOD_ASSIGN); }
"&="			{ count(); return(AND_ASSIGN); }
"^="			{ count(); return(XOR_ASSIGN); }
"|="			{ count(); return(OR_ASSIGN); }
">>"			{ count(); return(RIGHT_OP); }
"<<"			{ count(); return(LEFT_OP); }
"++"			{ count(); return(INC_OP); }
"--"			{ count(); return(DEC_OP); }
"->"			{ count(); return(PTR_OP); }
"&&"			{ count(); return(AND_OP); }
"||"			{ count(); return(OR_OP); }
"<="			{ count(); return(LE_OP); }
">="			{ count(); return(GE_OP); }
"=="			{ count(); return(EQ_OP); }
"!="			{ count(); return(NE_OP); }
";"			{ count(); return(';'); }
("{"|"<%")		{ count(); return('{'); }
("}"|"%>")		{ count(); return('}'); }
","			{ count(); return(','); }
":"			{ count(); return(':'); }
"="			{ count(); return('='); }
"("			{ count(); return('('); }
")"			{ count(); return(')'); }
("["|"<:")		{ count(); return('['); }
("]"|":>")		{ count(); return(']'); }
"."			{ count(); return('.'); }
"&"			{ count(); return('&'); }
"!"			{ count(); return('!'); }
"~"			{ count(); return('~'); }
"-"			{ count(); return('-'); }
"+"			{ count(); return('+'); }
"*"			{ count(); return('*'); }
"/"			{ count(); return('/'); }
"%"			{ count(); return('%'); }
"<"			{ count(); return('<'); }
">"			{ count(); return('>'); }
"^"			{ count(); return('^'); }
"|"			{ count(); return('|'); }
"?"			{ count(); return('?'); }

[ \t\v\n\f]		{ count(); }
.			{ /* ignore bad characters */ }

%%




void comment()
{
	char c, c1;

loop:
	while ((c = input()) != '*' && c != 0)
		putchar(c);

	if ((c1 = input()) != '/' && c != 0)
	{
		unput(c1);
		goto loop;
	}

	if (c != 0)
		putchar(c1);
}




void count()
{
	int i;

	for (i = 0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n')
			column = 0;
		else if (yytext[i] == '\t')
			column += 8 - (column % 8);
		else
			column++;
}


char* tokens[] = {
"AUTO" , 
"BREAK" , 
"CASE" , 
"CHAR" , 
"CONST" , 
"CONTINUE" , 
"DEFAULT" , 
"DO",  
"DOUBLE" , 
"ELSE" ,
"ENUM",  
"EXTERN" , 
"FLOAT" , 
"FOR" , 
"GOTO" ,
"IF",
"INT", 
"LONG" , 
"REGISTER" , 
"RETURN" , 
"SHORT" , 
"SIGNED" , 
"SIZEOF" , 
"STATIC" , 
"STRUCT", 
"SWITCH" , 
"TYPEDEF" 
"UNION" , 
"UNSIGNED" , 
"VOID" , 
"VOLATILE" , 
"WHILE" , 
"IDENTIFIER" , 
"CONSTANT" , 
"STRING_LITERAL" , 
"ELLIPSIS" , 
"RIGHT_ASSIGN" ,
"LEFT_ASSIGN" ,
"ADD_ASSIGN",
"SUB_ASSIGN",
"MUL_ASSIGN",
"DIV_ASSIGN",
"MOD_ASSIGN",
"AND_ASSIGN",
"XOR_ASSIGN",
"OR_ASSIGN",
"RIGHT_OP",
"LEFT_OP",
"INC_OP",
"DEC_OP",
"PTR_OP",
"AND_OP",
"OR_OP",
"LE_OP",
"GE_OP",
"EQ_OP",
"NE_OP"
};

void print_token(int c){
    if(c<256)
        printf("<%c>\n",c);
    else{
        switch(c){
            case CONSTANT:
                switch(yylval.valtype){
                    case INTVAL:
                    printf("<%s, %d>\n", tokens[c-AUTO], yylval.ival);
                    break;
                    case DOUBLEVAL:
                    printf("<%s, %g>\n", tokens[c-AUTO], yylval.dval);
                    break;
                    case CHARVAL:
                    printf("<%s, \'\\x%02x\'>\n", tokens[c-AUTO], (unsigned char)yylval.cval);
                    break; 
                }
            break;
            case IDENTIFIER:
                printf("<%s, \"%s\">\n", tokens[c-AUTO], yylval.name);
                break;
            case STRING_LITERAL:
                printf("<%s, \"%s\">\n", tokens[c-AUTO], yylval.sval);
                break;
            default:
                printf("<%s>\n", tokens[c-AUTO]);
            break;
                }
        }
}

int main(int argc, char** argv){
    int c;
    if(argc<2){
        printf("Analizador lexico para ANSI C 1989\n\n");
        printf("Uso:\n");
        printf("%s nombrearchivo\n", argv[0]);
        exit(0);
    }
    yyin = fopen(argv[1], "rt");
    while(1){
        c = yylex();
        if(c==0)
            break;
        print_token(c);
    }
    return 0;
}