%{
#include"parse.h"
#include "parser.tab.h"
//#include<stdbool.h>
#include<string.h>
#include<stdlib.h>
#include<stdio.h>
#include<stdbool.h>
//#include "lexcode.h"
int yycolumn = 1;

/*
* This structure is used to store location of the current token
* So that when a syntax error occures we can tell where has it occurred
*/
#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno; \
    yylloc.first_column = yycolumn; yylloc.last_column = yycolumn + yyleng - 1; \
    yycolumn += yyleng;

%}
%option yylineno

%%

"/*"[^*/]*"*/"				{printf("MultiLine Comment\n");};
"//"[^\n]*				{printf("SingleLine Comment\n");};

"#"					return '#';

"include"				return includet;

[_a-zA-Z][_a-zA-Z]*.".h"		return headert;

"define"				return definet;

"int"					{strcpy(yylval.fixstr, "int"); return datatypet;};

"float"					{strcpy(yylval.fixstr, "float"); return datatypet;};

"char" 					{strcpy(yylval.fixstr, "char"); return datatypet;};

"void"					{strcpy(yylval.fixstr, "void"); return datatypet;};

"bool"					{strcpy(yylval.fixstr, "bool"); return datatypet;};

"typedef"				return typedeft;

"struct"				{strcpy(yylval.fixstr,"struct");return structt;};

"->"					{strcpy(yylval.fixstr, yytext); return arrowopt;}

"<="					{strcpy(yylval.fixstr, yytext); return lessthant;}

">="					{strcpy(yylval.fixstr, yytext); return greaterthant;}

"&&"					{strcpy(yylval.fixstr, yytext); return andt;}

"||"					{strcpy(yylval.fixstr, yytext); return ort;}

"!="					{strcpy(yylval.fixstr, yytext); return notequalstot;}

"=="					{strcpy(yylval.fixstr, yytext); return equalstot;}

"for"					{strcpy(yylval.fixstr, yytext); return fort;}

"if"					{strcpy(yylval.fixstr, yytext); return ift;}

"else"					{strcpy(yylval.fixstr, yytext); return elset;}

"do"					{strcpy(yylval.fixstr, yytext); return dot;}

"while"					{strcpy(yylval.fixstr, yytext); return whilet;}

"return"				{strcpy(yylval.fixstr, yytext); return returnt;}

"++"					{strcpy(yylval.fixstr, yytext); return incrementt;}

"--"					{strcpy(yylval.fixstr, yytext); return decrementt;}

"+="					{strcpy(yylval.fixstr, yytext); return plusequalt;}

"-="					{strcpy(yylval.fixstr, yytext); return minusequalt;}

"false"					{yylval.nontData = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
					strcpy(yylval.nontData->fixstr, "bool");yylval.nontData->value.b = false;
					yylval.nontData->option = 5;strcpy(yylval.nontData->tempVar , yytext);return falset;};

"true"					{yylval.nontData = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
					strcpy(yylval.nontData->fixstr, "bool");yylval.nontData->value.b = true;
					yylval.nontData->option = 5;strcpy(yylval.nontData->tempVar , yytext);return truet;};

[0-9][0-9]*"."[0-9][0-9]*		{yylval.nontData = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
					strcpy(yylval.nontData->fixstr, "float");yylval.nontData->value.f = atof(yytext);
					yylval.nontData->option = 2;strcpy(yylval.nontData->tempVar , yytext); return floatt;};

"."	{strcpy(yylval.fixstr, yytext); return '.';}

";"	{strcpy(yylval.fixstr, yytext); return ';';}

"{"	{strcpy(yylval.fixstr, yytext); return '{';}

"}"	{strcpy(yylval.fixstr, yytext); return '}';}

"["	{strcpy(yylval.fixstr, yytext); return '[';}

"]"	{strcpy(yylval.fixstr, yytext); return ']';}

","	{strcpy(yylval.fixstr, yytext); return ',';}

"*"	{strcpy(yylval.fixstr, yytext); return '*';}

"="	{strcpy(yylval.fixstr, yytext); return '=';}

"<"	{strcpy(yylval.fixstr, yytext); return '<';}

">"	{strcpy(yylval.fixstr, yytext); return '>';}

"-"	{strcpy(yylval.fixstr, yytext); return '-';}

"+"	{strcpy(yylval.fixstr, yytext); return '+';}

"/"	{strcpy(yylval.fixstr, yytext); return '/';}

"("	{strcpy(yylval.fixstr, yytext); return '(';}

")"	{strcpy(yylval.fixstr, yytext); return ')';}

"~"	{strcpy(yylval.fixstr, yytext); return '~';}






[0-9][0-9]*				{yylval.nontData = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
					strcpy(yylval.nontData->fixstr, "int");yylval.nontData->value.i = atoi(yytext);
					yylval.nontData->option = 1; strcpy(yylval.nontData->tempVar , yytext);return integert;};

"'"[_a-zA-Z0-9]"'"			{yylval.nontData = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
					strcpy(yylval.nontData->fixstr, "char");yylval.nontData->value.c = yytext[0];
					yylval.nontData->option = 3;strcpy(yylval.nontData->tempVar , yytext);return chart;};

\"[_a-z A-Z][_a-z A-Z0-9]*\"		{yylval.nontData = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
					strcpy(yylval.nontData->fixstr, "char");strcpy(yylval.nontData->value.str, yytext);
					yylval.nontData->option = 4;strcpy(yylval.nontData->tempVar , yytext); return stringt;};
	
[_a-zA-Z][_a-zA-Z0-9]*			{strcpy(yylval.fixstr, yytext); return identifiert;};

[ \t]			;
[\n]			{yycolumn = 1;};
.			printf("Unexpected Character\n");

%%

int yywrap(void)
{
	return 1;   /*this function is used when multiple input file is taken*/
}



