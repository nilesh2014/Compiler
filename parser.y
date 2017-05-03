//declaration
%{
int yylex()  ;
void yyerror (char *s) ;
#include <stdio.h>
#include<stdlib.h>
//#include<stdbool.h>
#include "parser.tab.h"
#include "parse.h"
#include <string.h>
extern char *yytext;

struct symbolTable symTable[10000];
int symTableIndex=0;

struct structTable structTableList[1000];
int structTableIndex = 0;

struct symbolTable *call_func_ptr;
struct symbolTable *curr_func_ptr;
int level;

struct structTable *call_struct_ptr;
struct structTable *curr_struct_ptr;
int offset = 0;


struct quadTable quadTableList[10000];
int quadTableIndex =0;

struct quadList *codeLines = NULL;
struct quadList *codeLineHead = NULL, *codeLineTail = NULL;
int nextquad=0;    //number of the next quadruple to be generated
char quadbuffer[50];  //stores the code to be printed in ICG

int intVarCount= 0;
int floatVarCount =0;
int charVarCount = 0;
int boolVarCount = 0;
int defCount = 0;
int structVarCount = 0;

%}


//definition

%union{
	int number;
	char fixstr[30];
	//char *multiStr[30];
	char *string;
	//bool boolean;   //will look into it later
	struct variableList *varPtr;
	struct structMemberList *structMemPtr;
	struct dimList *dimPtr;
	struct symbolTable *symptr;

	struct nonTstruct *nontData;

	struct
	{
	  struct backpatchList	*nextList;
	} stmt;

	struct
	{
	  int				quad;
	  struct backpatchList* 	nextList;
	} mark;

	struct
	{
	    char                 	tempVar[20];
	    char  			type[20];
	    int begin;
	    struct backpatchList* 	trueList;
	    struct backpatchList* 	falseList;
	} expr;
}

%locations

%start start_

%token <fixstr> datatypet identifiert structt andt ort lessthant greaterthant equalstot notequalstot//falset truet integert floatt chart 

%token <nontData> falset truet integert floatt chart stringt

//%token <string> stringt

//%type <fixstr> literal_ 

%type <fixstr> result_ member_ id  func_name structType op1_  //EXP_  T  F 

//%type <number>  arrbox_  arrcomma_
%type <dimPtr>  arrbox_  arrcomma_ paraArrbox_ paraArrcomma_

%type <structMemPtr> struct_declList member1_ 

%type <varPtr> idList structidList LHS 

%type <number> declPlist  multiParam_  start_

%type <symptr> RHS funcCall_ callName

%type <nontData> literal_ EXP_  T  F

%type <stmt> func_def stmtList_  stmt_  return_ if_ ifwhilefor_ while_ for_ body_

%type <mark> marker jump_marker

%type <expr> expression ifExp_  whileExp_ assignment expr_

%token includet
%token headert
%token definet
//%token datatypet
//%token identifiert
%token commentsinglet
%token commentmultistartt
%token commentmultiendt
%token typedeft
//%token structt
%token arrowopt
//%token lessthant
//%token greaterthant
//%token andt
//%token ort
//%token notequalstot
//%token equalstot
%token ift
%token elset
%token dot
%token whilet
%token returnt
%token incrementt
%token decrementt
%token plusequalt
%token minusequalt
//%token falset
//%token truet
//%token integert
//%token floatt
//%token chart
//%token stringt
%token fort
%token '.'
%token ';'
%token '{'
%token '}'
%token '['
%token ']'
%token ','
%token '*'
%token '='
%token '<'
%token '>'
%token '-'
%token '+'
%token '/'
%token '('
%token ')'
%token '~'






//production
%%

/*description of grammar*/

start_ : preprocessor start_								{;} 
	| func_def start_								{;}
	| structure start_								{;}
	| var_declList ';' start_							{;}
	| assignment ';' start_								{;}
 	| preprocessor 									{;} 
	| func_def									{;}
	| structure 									{;}
	| var_declList ';' 								{;}
	| assignment ';'								{;}
	;



preprocessor : '#' includet '<' headert '>'  						{;} 
	| '#' definet id literal_ 		{
						struct symbolTable *symPtr;
						//struct symbolTable symPtr;
						if(search_symTable($3, &symPtr)){
							//yyerror(strcat("Variable ", strcat($3, " already declared")));
							yyerror("variable already declared\n");	
						}
						else{
							//printf("preprocessor part: %s and type: %s\n", $3, $4);
							insertSymTable($3, $4->fixstr, NULL,NULL,  0,&symPtr);
							//insertSymTable("abvg", "onht", NULL,NULL,NULL,  7);
							//printSymTable();
							sprintf(quadbuffer, "d_%d := %s", defCount, $4->fixstr);
							generateQuad(quadbuffer);
						};}
	;


	

literal_ : falset 									{$$= $1;}
	| truet 									{$$= $1;}
	| chart 									{$$= $1;}
	| stringt 									{$$= $1;}
	| integert 									{$$= $1;}
	| floatt									{$$= $1;}
	;




/*
prototype : result_ func_name   '(' FormalPlist ')'  ';' start_ 			{;} 
	| result_ func_name   '('  ')'  ';' start_					{;} 
	;
*/




/*
FormalPlist : result_ ',' FormalPlist 							{;} 
	| result_ func_name ',' FormalPlist						{;}
	| result_ func_name      							{;}
	| result_  							     		{;}
	;

*/



structure :typedef_ 									{offset=0;}
	| struct_									{offset=0;}
	;

typedef_ : typeStruct_  member_								{;}	
	;

typeStruct_: typedeft structt id 		{struct structTable *structPtr;
							if(search_structTable($3,&structPtr)){
								yyerror("Structure already declared\n");
							}
							else{
								//printf("true122222\n");
								insertStructTableList($3, NULL,NULL, &structPtr);
								curr_struct_ptr = structPtr;
								//printf("currstruct: %s\n", structPtr->name); 
							}
						}
	;

member_ : '{'struct_declList '}' id ';' 	{//printf("typedef structure part:id %s \n", $4);
						struct structTable *structPtr;
						if(search_structTypeTable($4, &structPtr)){
							yyerror("Structure instance already declared");	
						}
						else{
							struct structTable *temp = curr_struct_ptr;
							strcpy(temp->type, $4);
						}//printStructTable();
						}
	;

struct_ : structId_ member1_ 			{;}
	;

structId_ : structt id				{struct structTable *structPtr;
							if(search_structTable($2,&structPtr)){
								yyerror("Structure already declared\n");
							}
							else{
								insertStructTableList($2, NULL,NULL, &structPtr);
								curr_struct_ptr = structPtr;
								//printf("currstruct: %s\n", structPtr->name); 
								//ctTable();
							}
						}
	;

member1_ : '{' struct_declList '}' structidList ';' 		{struct variableList *temp = $4;
								struct symbolTable *symPtr ;
									//struct symbolTable symPtr;
								while(temp!=NULL){
									struct variableList *temp1 = temp->next;
									if(search_symTable(temp->name, &symPtr)){
										yyerror("Structure instance already declared");
											
									}
									else{
										
										temp->next = NULL;
										//printf("after insert!!!\n");
										char type[30];
										sprintf(type, "struct %s",curr_struct_ptr->name);
										temp->structMemListPtr = curr_struct_ptr->memListPtr;
										strcpy(temp->type,type);
									//printf("Cuur struct ptrname: %s",curr_struct_ptr->name);
										insertSymTable(temp->name,type , NULL,temp , 0, &symPtr);
										
									}
									temp = temp1;;
								}
								}

	| '{'  struct_declList '}' ';' 				{;}
	;

structidList : LHS ',' idList 					{

									//printf("Struct Member In1st prod of stucdList: %s\n", $1->name);
									appendVarList(&$3,&$1);
									$$ = $1;
									struct variableList *temp = $1;
									//int t = 0;
									while(temp!= NULL){
										//printf("Name: %s\n", temp->name);
										temp = temp->next;
										//t++;
									}
									//printf("TotalNumInList %d: ",t);
								}

	| LHS 								{//struct variableList *tempR = $1;
									//printf("Struct Member: %s\n", tempR->name);
									$$ = $1;}
	;

struct_declList : result_ idList ';'		  		{struct variableList *tempList = $2;
								struct structTable *structPtr ;
								while(tempList!=NULL){
									
									if(search_var_curr_struct(tempList->name, &structPtr)){
										
										yyerror("struct member already declared");		
									}
									else{
										
										insert_var_curr_struct(tempList, $1);
									}
									
									tempList = tempList->next;
									//tempList++;
									
									
								}
								/*struct structMemberList *temp1 = appendStructMember($1, $2);
								$$ = mergeStructList(temp1, $4);*/}

	| struct_declList  result_ idList ';'			{struct variableList *tempList = $3;
								struct structTable *structPtr ;
								while(tempList!=NULL){
									
									if(search_var_curr_struct(tempList->name, &structPtr)){
										
										yyerror("struct member already declared");		
									}
									else{
										
										insert_var_curr_struct(tempList, $2);
									}
									
									tempList = tempList->next;
									//tempList++;
									
									
								}
								//printStructTable();
								}
	;

result_ : datatypet 									{strcpy($$, $1);}
	| structType									{strcpy($$, $1);}
	;

structType : structt id 					{char type[20];
								strcpy(type, "struct ");
								strcpy($$,strcat(type, $2));
								struct structTable *retPtr;
								if(!search_structTable($2, &retPtr))
									yyerror("Structure not defined");
								else
									call_struct_ptr = retPtr;
								} 

	| id  							{strcpy($$, $1);
								struct structTable *retPtr;
								if(!search_structTypeTable($1, &retPtr))
									yyerror("Structure Instance not defined");
								else
									call_struct_ptr = retPtr;
								}
	;

id : identifiert									{strcpy($$, $1);}
	;

idList : structidList						{$$ = $1;}
	| LHS '=' RHS						{appendVarList(&$$,&$1);}
	;

/*
global_assign : LHS '=' RHS 				{struct variableList *tempL = $1;
							struct symbolTable *tempR = $3;
							//struct variableList *retPtr ;
							struct symbolTable *symPtr = (struct symbolTable *)malloc(sizeof(struct symbolTable));
							//struct symbolTable symPtr;							
							if(search_symTable(tempL->name, &symPtr)){
								if(!coercible(symPtr->type, tempR->type)){
									yyerror("Type Mismatch in Assignment\n");
								}
								if(strcmp(tempL->arraytype, (symPtr->locVarListPtr)->arraytype))
									yyerror("Type mismatch in assignment\n");
							}
							else{
								yyerror("Variable  not declared\n");
							} ;}
	;


*/

LHS : func_name arrowopt LHS				{struct variableList *tempL = (struct variableList *)malloc(sizeof(struct variableList));
							strcpy(tempL->name, $1); 
							strcpy(tempL->type, "struct");
							strcpy(tempL->arraytype, "simple");
							tempL->level = level;
							$$ = tempL;}

	| func_name arrbox_				{struct variableList *tempL = (struct variableList *)malloc(sizeof(struct variableList));
							strcpy(tempL->name, $1); 
							strcpy(tempL->arraytype, "array");
							tempL->dimListPtr = $2;
							tempL->level = level;
							$$ = tempL;} 

	| func_name '[' arrcomma_ ']'			{struct variableList *tempL = (struct variableList *)malloc(sizeof(struct variableList));
							strcpy(tempL->name, $1); 
							strcpy(tempL->arraytype, "array");
							tempL->dimListPtr = $3;
							tempL->level = level;
							$$ = tempL;}

	| func_name '.' LHS				{struct variableList *tempL = (struct variableList *)malloc(sizeof(struct variableList));
							strcpy(tempL->name, $1); 
							//strcpy(tempL->type, "struct");
							//strcpy(tempL->arraytype, $3->arraytype);
							tempL->level = level;
							struct variableList *symPtr;
							//printSymTable();
							//if(!search_symTable($1,&symPtr)){
							struct variableList *tempList = $3;
							int flag = 0;
							if(!search_var_curr_func($1, &symPtr)){
								if(!search_param_curr_func($1,&symPtr)){

									if(!searchGlobal($1,&symPtr)){
										yyerror("variable not declared\n");
										flag = 1;
									}
								}

							}
							if(flag == 0){
								//printf("%s\n",symPtr->type);
								//call_struct_ptr = structPtr;
								struct variableList *retPtr ;
								//assert that $3 is a member of symPtr memListPtr
								if(!search_mem_structSym(tempList->name, symPtr, &retPtr)){
										
									yyerror("struct member not declared ");		
								}
								else{
									if(!strcmp(tempList->arraytype, "array")){
								//assert that the index of LHS is <= to the index size defined
										if(!checkArrayDim(tempList, retPtr)){
											yyerror("index out of range");
										}
										else{
										struct dimList *arrlist = tempList->dimListPtr;
										struct dimList *retlist = retPtr->dimListPtr;
										retlist = retlist->next;
										int prevCount =0;
										while(retlist != NULL){
											if(prevCount == 0)
												sprintf(quadbuffer,"i_%d := %s*%s",intVarCount,arrlist->dim,retlist->dim);
											else
												sprintf(quadbuffer,"i_%d := i_%d*%s",intVarCount,prevCount,retlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											arrlist = arrlist->next;
											sprintf(quadbuffer,"i_%d := i_%d+%s",intVarCount,prevCount,arrlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											retlist = retlist->next;
											
										}
										sprintf(quadbuffer,"i_%d := i_%d*sizeof(%s)",intVarCount,prevCount, retPtr->type);
										generateQuad(quadbuffer);
										prevCount = intVarCount;
										intVarCount++;
									
										sprintf(quadbuffer,"i_%d := %d + i_%d", intVarCount, retPtr->offset,prevCount);
										generateQuad(quadbuffer);
										intVarCount++;
										sprintf(quadbuffer, "i_%d := addr(%s)", intVarCount, $1);
										generateQuad(quadbuffer);
										//intVarCount++;
										//sprintf(quadbuffer, "i_%d := i_%d[i_%d]", intVarCount,intVarCount-1,intVarCount-2);
										//generateQuad(quadbuffer);
										sprintf(quadbuffer, "i_%d[i_%d]", intVarCount,intVarCount-1 );
										strcpy(tempL->tempVar, quadbuffer);
										strcpy(tempL->type, retPtr->type);
										strcpy(tempL->arraytype, "struct");
										intVarCount++;
										}	
									}
									else if(!strcmp(tempList->arraytype, "simple")){
									
									//tempL->offset = retMem->offset;
									//printf("ret type:%s\n", retMem->type);
									
									sprintf(quadbuffer, "i_%d := addr(%s)", intVarCount, $1);
									generateQuad(quadbuffer);
									//intVarCount++;
									//sprintf(quadbuffer, "i_%d := i_%d[%d]",intVarCount, intVarCount-1,retPtr->offset );
									//generateQuad(quadbuffer);
									sprintf(quadbuffer, "i_%d[%d]", intVarCount, retPtr->offset);
									strcpy(tempL->tempVar, quadbuffer);
									strcpy(tempL->type, retPtr->type);
									strcpy(tempL->arraytype, "struct");
									intVarCount++;
									}
									}
							}		
							$$ = tempL;}

	

	| func_name 					{struct variableList *tempL = (struct variableList *)malloc(sizeof(struct variableList));
							strcpy(tempL->name, $1);
							strcpy(tempL->arraytype, "simple");
							tempL->level = level;
							tempL->next = NULL;
							$$ = tempL;}

	;

func_name : id 										{strcpy($$, $1);}
	| '*' id  									{strcpy($$, strcat("*",$2));}
	;

arrbox_ : '[' RHS ']' arrbox_  				{//$$ = $4+1;
							struct symbolTable *temp = $2;
							if(strcmp(temp->type, "int")){
								yyerror("Only integers are allowed in array declaration");
							}
							else{
							appendDim(&$4, temp->tempVar);
							$$ = $4;
							}
							}

	| '[' RHS ']'					{//$$ = 1;
							struct symbolTable *temp = $2;
							if(strcmp(temp->type, "int")){
								yyerror("Only integers are allowed in array declaration");
							}
							else{
							struct dimList *dimTemp = (struct dimList *)malloc(sizeof(struct dimList));
							strcpy(dimTemp->dim , temp->tempVar);
							dimTemp->next = NULL;
							$$ = dimTemp;
							}}

	| paraArrbox_					{$$ = $1;}

   
	 
paraArrbox_: '[' ']' paraArrbox_			{appendDim(&$3, "9999");
							$$ = $3;}			

	| '[' ']' 					{struct dimList *dimTemp = (struct dimList *)malloc(sizeof(struct dimList));
							strcpy(dimTemp->dim , "9999");
							dimTemp->next = NULL;
							$$ = dimTemp;
							}  
	;

arrcomma_ : RHS ',' arrcomma_ 				{//$$ = $4+1;
							struct symbolTable *temp = $1;
							if(strcmp(temp->type, "int")){
								yyerror("Only integers are allowed in array declaration");
							}
							else{
								appendDim(&$3, temp->tempVar);
								$$ = $3;
							}
							}
	| RHS 						{//$$ = 1;
							struct symbolTable *temp = $1;
							if(strcmp(temp->type, "int")){
								yyerror("Only integers are allowed in array declaration");
							}
							else{
							struct dimList *dimTemp = (struct dimList *)malloc(sizeof(struct dimList));
							strcpy(dimTemp->dim , temp->tempVar);
							dimTemp->next = NULL;
							$$ = dimTemp;
							}}  
	
	|paraArrcomma_					{$$ = $1;}
	;

paraArrcomma_: ',' paraArrcomma_			{appendDim(&$2, "9999");
							$$ = $2;
							}
							
	
	| ','						{struct dimList *dimTemp = (struct dimList *)malloc(sizeof(struct dimList));
							strcpy(dimTemp->dim , "9999");
							dimTemp->next = NULL;
							$$ = dimTemp;}
	;

RHS : EXP_  					{struct symbolTable *tempL = (struct symbolTable *)malloc(sizeof(struct symbolTable));
						strcpy(tempL->type, $1->fixstr); tempL->value = $1->value;
						tempL->option = $1->option; strcpy(tempL->tempVar ,$1->tempVar);
						$$ = tempL;
						//printf("Type: %s\n", tempL->type );
						}
	
	/*| LHS	  						{struct symbolTable *tempL = (struct symbolTable *)malloc(sizeof(struct symbolTable));
								struct variableList *tempR = $1;
								strcpy(tempL->type, tempR->type);
								if(tempR->level == 1)
									tempL->paramListPtr = tempR;
								else
									tempL->paramListPtr = tempR;
								$$ = tempL;}*/
	;

funcCall_ : callName  ')'  					{
								if(call_func_ptr->num_param != 0){
									yyerror("Argument count mismatch\n");
								}
								$$ = $1;
								}

	| callName  multiParam_ ')'  				{	
								//printf("assgn: %s \n", $$->type );
								if($1->num_param != $2){
									yyerror("Argument count mismatch\n");
								}$$ = $1;}	 
	;

callName : func_name '('					{struct symbolTable *symPtr ;
								//struct symbolTable symPtr;
								if(!search_symTable($1, &symPtr)){
									yyerror("Function not defined\n");
									call_func_ptr = NULL;
								}
								else{
									//printf("%s type\n", call_func_ptr->paramListPtr->type);
									call_func_ptr = symPtr;
									//struct quadList *retCode = 
									$$ = symPtr;
									//printf("%s type\n", call_func_ptr->paramListPtr->type);
																		
								}//printSymTable();
								}
	;

multiParam_ : RHS 						{$$ = 1;
								
								if(!check_param_type(call_func_ptr, 1, $1)){
									yyerror("parameter type mismatched\n");
								}
								else{
									//ICG
									sprintf(quadbuffer,"PARAM %s",$1->tempVar);
									generateQuad(quadbuffer);
								}}


	| multiParam_  ','  RHS					{$$ = $1+1;
								if(!check_param_type(call_func_ptr, $$, $3)){
									yyerror("parameter type mismatched\n");
								}else{
									//ICG
									sprintf(quadbuffer,"PARAM %s",$3->tempVar);
									generateQuad(quadbuffer);
								}}
	
	
	;


EXP_ : 	'~' EXP_ 						{if(!strcmp($2->fixstr,"bool") || !strcmp($2->fixstr,"int")){
								struct nonTstruct *temp = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
									strcpy($$->fixstr,"bool");
								}}

	//| '-' EXP_						{;}

	| T '+' EXP_ 					{//printf("%s %s\n", $1-, $3);
							if(!(compatibleArithOp($1->fixstr, $3->fixstr))){
								
								yyerror("Type Mismatch\n");
							}
							else{	char tempVar[10];
								struct nonTstruct *temp = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
									//printf("here!\n");
								strcpy(temp->fixstr , resultTypeExp($1->fixstr, $3->fixstr));
								if(!strcmp(temp->fixstr, "int")){
								sprintf(quadbuffer,"i_%d = %s + %s",intVarCount, $1->tempVar, $3->tempVar);
								sprintf(tempVar, "i_%d", intVarCount);
								intVarCount++;
								generateQuad(quadbuffer);
									
								}
								else if(!strcmp(temp->fixstr, "float")){
									sprintf(quadbuffer,"f_%d = %s + %s",floatVarCount, $1->tempVar, $3->tempVar);
									sprintf(tempVar, "f_%d", floatVarCount);
									floatVarCount++;
									generateQuad(quadbuffer);
									
								}
								
								strcpy(temp->tempVar, tempVar);
								$$ = temp;
									
							}
							}
	
	| T '-' EXP_ 					{if(!compatibleArithOp($1->fixstr, $3->fixstr)){
								yyerror("Type Mismatch\n");
							}
							else{
								char tempVar[10];
								struct nonTstruct *temp = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
									//printf("here!\n");
								strcpy(temp->fixstr , resultTypeExp($1->fixstr, $3->fixstr));
								if(!strcmp(temp->fixstr, "int")){
								sprintf(quadbuffer,"i_%d = %s - %s",intVarCount, $1->tempVar, $3->tempVar);
								sprintf(tempVar, "i_%d", intVarCount);
								intVarCount++;
								generateQuad(quadbuffer);
									
								}
								else if(!strcmp(temp->fixstr, "float")){
									sprintf(quadbuffer,"f_%d = %s - %s",floatVarCount, $1->tempVar, $3->tempVar);
									sprintf(tempVar, "f_%d", floatVarCount);
									floatVarCount++;
									generateQuad(quadbuffer);
									
								}
								
								strcpy(temp->tempVar, tempVar);
								$$ = temp;
									
							}
								}

	| T op1_ EXP_					{if(coercible($1->fixstr, $3->fixstr)){
									
							
								char tempVar[10];
								struct nonTstruct *temp = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
									//printf("here!\n");
								strcpy(temp->fixstr , "bool");
								
								sprintf(quadbuffer,"b_%d = %s %s %s",boolVarCount, $1->tempVar,$2, $3->tempVar);
								sprintf(tempVar, "b_%d", boolVarCount);
								boolVarCount++;
								generateQuad(quadbuffer);

								strcpy(temp->tempVar, tempVar);
								$$ = temp;
									
							}
							else{
								yyerror("Type Mismatch");
							}}

	
	| T						{$$= $1;}
	;

op1_	:  andt										{strcpy($$, $1);}
	| ort										{strcpy($$, $1);}
	| lessthant									{strcpy($$, $1);}
	| equalstot									{strcpy($$, $1);}
	| greaterthant									{strcpy($$, $1);}
	| notequalstot									{strcpy($$, $1);}
	| '<'										{strcpy($$, "<");}
	| '>'										{strcpy($$, ">");}
	;

T : F '*' T 						{if(!coercible($1->fixstr,$3->fixstr) || !compatibleArithOp($1->fixstr, $3->fixstr)){
								yyerror("Type Mismatch\n");
							}
							else{
								char tempVar[10];
								struct nonTstruct *temp = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
									//printf("here!\n");
								strcpy(temp->fixstr , resultTypeExp($1->fixstr, $3->fixstr));

								if(!strcmp(temp->fixstr, "int")){
								sprintf(quadbuffer,"i_%d = %s * %s",intVarCount, $1->tempVar, $3->tempVar);
								sprintf(tempVar, "i_%d", intVarCount);
								intVarCount++;
								generateQuad(quadbuffer);
									
								}
								else if(!strcmp(temp->fixstr, "float")){
									sprintf(quadbuffer,"f_%d = %s * %s",floatVarCount, $1->tempVar, $3->tempVar);
									sprintf(tempVar, "f_%d", floatVarCount);
									floatVarCount++;
									generateQuad(quadbuffer);
									
								}
								
								strcpy(temp->tempVar, tempVar);
								$$ = temp;
									
							}}

	| F '/' T 						{if(!coercible($1->fixstr,$3->fixstr) || !compatibleArithOp($1->fixstr, $3->fixstr)){
									yyerror("Type Mismatch\n");
								}
							else{
								char tempVar[10];
								struct nonTstruct *temp = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
									//printf("here!\n");
								strcpy(temp->fixstr , resultTypeExp($1->fixstr, $3->fixstr));

								if(!strcmp(temp->fixstr, "int")){
								sprintf(quadbuffer,"i_%d = %s/%s",intVarCount, $1->tempVar, $3->tempVar);
								sprintf(tempVar, "i_%d", intVarCount);
								intVarCount++;
								generateQuad(quadbuffer);
									
								}
								else if(!strcmp(temp->fixstr, "float")){
									sprintf(quadbuffer,"f_%d = %s/%s",floatVarCount, $1->tempVar, $3->tempVar);
									sprintf(tempVar, "f_%d", floatVarCount);
									floatVarCount++;
									generateQuad(quadbuffer);
									
								}
								
								strcpy(temp->tempVar, tempVar);
								$$ = temp;
									
							}}

	| F 							{$$= $1;}
	;

F :  '(' EXP_ ')'  						{$$= $2;}


	| LHS							{struct nonTstruct *ret = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));								//$$ = ret;
								struct variableList *tempList = $1;
								if(!strcmp(tempList->arraytype, "struct")){
									
									strcpy(ret->tempVar, tempList->tempVar);
									//printf("ret Type: %s\n", tempList->type);
									strcpy(ret->fixstr, tempList->type);
								}else{
									int flag = 0;
									struct variableList *retPtr ;
									if(!search_var_curr_func(tempList->name, &retPtr)){
										if(!search_param_curr_func(tempList->name, &retPtr)){
											if(!searchGlobal(tempList->name, &retPtr)){
												yyerror("Identifier not declared \n");
												flag = 1;
											}
											else{
												strcpy(ret->fixstr, retPtr->type);
											}								
										}
										else{
											strcpy(ret->fixstr, retPtr->type);
											//strcpy(ret->tempVar, temp->tempVar);
										}	
									}
									else{
										//printf("type: %s\n", retPtr->type);
										strcpy(ret->fixstr, retPtr->type);
										//strcpy(ret->tempVar, temp->tempVar);
									}
									//ICG
									if(flag == 0 && !strcmp(tempList->arraytype, "array")){
									//assert that the index of LHS is <= to the index size defined
									if(!checkArrayDim(tempList, retPtr)){
										yyerror("index out of range");
									}
									else{
										struct dimList *arrlist = tempList->dimListPtr;
										struct dimList *retlist = retPtr->dimListPtr;
										retlist = retlist->next;
										int prevCount =0;
										while(retlist != NULL){
											if(prevCount == 0)
											sprintf(quadbuffer,"i_%d := %s*%s",intVarCount,arrlist->dim,retlist->dim);
											else
											sprintf(quadbuffer,"i_%d := i_%d*%s",intVarCount,prevCount,retlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											arrlist = arrlist->next;
											sprintf(quadbuffer,"i_%d := i_%d+%s",intVarCount,prevCount,arrlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											retlist = retlist->next;
											
										}
									sprintf(quadbuffer,"i_%d := i_%d*sizeof(%s)",intVarCount,prevCount, retPtr->type);
									generateQuad(quadbuffer);
									prevCount = intVarCount;
									intVarCount++;

									sprintf(quadbuffer,"i_%d := addr(%s)",intVarCount,tempList->name);
									generateQuad(quadbuffer);
 									
									sprintf(quadbuffer,"i_%d := i_%d[i_%d] ",intVarCount+1,intVarCount,prevCount);
									generateQuad(quadbuffer);
									sprintf(quadbuffer, "i_%d", intVarCount+1);
									strcpy(ret->tempVar, quadbuffer);
									//strcpy(ret->fixstr, retPtr->type);
									intVarCount+= 2;
									}
								}
								
								else 
									strcpy(ret->tempVar, tempList->name);
								}
								$$ = ret;}
	
	| funcCall_ 						{//printSymTable();
								
								char tempVar[10];
								//printf("%s  call \n", $1->name);
								struct symbolTable *temp = $1;
								if(!strcmp(temp->type, "int")){
									sprintf(quadbuffer,"REFPARAM i_%d",intVarCount);
									sprintf(tempVar, "i_%d", intVarCount);
									intVarCount++;
									generateQuad(quadbuffer);
									
								}
								else if(!strcmp(temp->type, "float")){
									sprintf(quadbuffer,"REFPARAM f_%d",floatVarCount);
									sprintf(tempVar, "f_%d", floatVarCount);
									floatVarCount++;
									generateQuad(quadbuffer);
									
								}
								else if(!strcmp(temp->type, "char")){
									sprintf(quadbuffer,"REFPARAM c_%d",charVarCount);
									sprintf(tempVar, "c_%d", charVarCount);
									charVarCount++;
									generateQuad(quadbuffer);
									
								}
								else if(!strcmp(temp->type, "bool")){
									sprintf(quadbuffer,"REFPARAM b_%d",boolVarCount);
									sprintf(tempVar, "b_%d", boolVarCount);
									boolVarCount++;
									generateQuad(quadbuffer);
									
								}
								else if(!strcmp(temp->type, "void")){
									sprintf(tempVar, "void");
								}
								else {
									sprintf(quadbuffer,"REFPARAM s_%d",structVarCount);
									sprintf(tempVar, "s_%d", structVarCount);
									structVarCount++;
									generateQuad(quadbuffer);

									
								}
								
								if(!strcmp(temp->type, "void")){
									sprintf(quadbuffer,"CALL %s, %d",temp->name,temp->num_param);
									generateQuad(quadbuffer);
								}
								else{
									sprintf(quadbuffer,"CALL %s, %d",temp->name,temp->num_param+1);
									generateQuad(quadbuffer);
								}
								struct nonTstruct *tempN  = (struct nonTstruct *)malloc(sizeof(struct nonTstruct));
								strcpy(tempN->tempVar, tempVar);
								strcpy(tempN->fixstr, temp->type);
								$$ = tempN;
								//printSymTable();
								}


									
	| literal_ 						{$$= $1;}
	;



/*
func_def :func_head '{' var_declList body_ return_  '}' start_				{;}
	| func_head '{' var_declList body_ '}' start_					{;}
	| func_head '{' var_declList  return_ '}' start_				{;}
	| func_head '{' var_declList '}' start_						{;}
	;
*/
/*
func_proto:	func_head ';'					{curr_func_ptr = NULL;level = 0;$$.nextList = NULL;}
	;
*/
func_def : func_head '{' '}'					{//delete_content(level);   //need to know what it does.
								curr_func_ptr = NULL;level =0;
								$$.nextList = NULL;
								generateQuad("FUNC END");}

	| func_head '{' stmtList_ '}' 				{//delete_content(level);
								
								curr_func_ptr = NULL;level =0;
								$$.nextList = $3.nextList;
								generateQuad("FUNC END");}
	;

func_head : resId '(' declPlist ')' 				{level =2;
								curr_func_ptr->num_param = $3;
								//printSymTable();
								//printf("func head correct!!!\n");
								}

	| resId '(' ')'						{level =2;curr_func_ptr->num_param = 0;}
	;

resId : result_ func_name					{struct symbolTable *symPtr;//= (struct symbolTable *)malloc(sizeof(struct symbolTable));
								if(search_symTable($2,&symPtr)){
									yyerror("Function already declared\n");
								}
								else{
									//printf("%s\n", $2);
									insertSymTable($2, $1, NULL,NULL,0, &symPtr);
									curr_func_ptr = symPtr; level = 1;
									//printf("currfunc: %s\n", symPtr->name); 
									//ICG
									sprintf(quadbuffer,"FUNC BEGIN %s",$2);
									//printf("%s\n", symTable[0].name);
									//printf("func head correct!!!\n") ;
									generateQuad(quadbuffer);
								}level = 1;}
	;

var_declList : result_ idList   				{struct variableList *tempList = $2;
								struct variableList *temp = $2;
								struct symbolTable *symPtr = (struct symbolTable *)malloc(sizeof(struct symbolTable));
								while(tempList!=NULL){
									temp = tempList->next;
									if(search_symTable(tempList->name, &symPtr)){
										
										yyerror("variable already declared");		
									}
									else{
										
										tempList->next = NULL;
										strcpy(tempList->type, $1);
										
										insertSymTable(tempList->name,$1 , NULL,tempList,  0,&symPtr);				
										//printSymTable();
								
									}
									
									tempList = temp;
									
								}
								
								$2 =NULL;}
	;

return_ : returnt RHS 						{struct symbolTable *ret = curr_func_ptr;
								struct symbolTable *tempR = $2;
								if(strcmp(tempR->type , ret->type))
									yyerror("Return type does not match with function return type\n");
								//ICG
								else{
								$$.nextList = NULL;
								
													
            							sprintf(quadbuffer,"RETURN %s",$2->tempVar);
								generateQuad(quadbuffer);				
								}}

	| returnt 						{struct symbolTable *ret = curr_func_ptr;
								if(strcmp(ret->type, "void"))
									yyerror("Return type is not void\n");
								//ICG
								else{
								$$.nextList = NULL;
	    							sprintf(quadbuffer,"RETURN");
								generateQuad(quadbuffer);
								}
								}
	;

declPlist : declPl ',' declPlist 							{$$ = $3 + 1;}
	| declPl  									{$$ = 1;}
	;

declPl : result_ LHS 						{struct variableList *tempR = $2;
								
								struct variableList *retPtr;
								if(search_param_curr_func(tempR->name, &retPtr)){
									yyerror("Parameter already declared\n");
								}
								else{
									insert_param_curr_func(tempR, $1);
								}}
	;

stmtList_ : stmt_ ';' marker stmtList_					{//backpatch($1.nextList,$3.quad);
									$$.nextList = $4.nextList;}

	|  stmt_ ';'							{$$.nextList = $1.nextList;}

	| body_ marker stmtList_ 					{backpatch($1.nextList,$2.quad);
									$$.nextList = $3.nextList;}

	| body_								{$$.nextList = $1.nextList;}

	| ifwhilefor_ marker stmtList_ 					{backpatch($1.nextList,$2.quad);
									$$.nextList = $3.nextList;}

	| ifwhilefor_							{$$.nextList = $1.nextList;}
	;

body_ : {level++;} '{' stmtList_  '}' 			{//delete_content( level);
							level--;
							$$.nextList = $3.nextList;} 	
	;
	
assignment : LHS '=' RHS 				{struct variableList *tempList = $1;
								//struct symbolTable *symPtr = (struct symbolTable *)malloc(sizeof(struct symbolTable));	
							struct symbolTable *tempR = $3;
							int flag=0;
							//printf("struct: %s\n", tempList->arraytype);
							if(!strcmp(tempList->arraytype, "struct")){
								//printf("%s %s\n", tempList->type, tempR->type);
								if(!coercible(tempList->type, tempR->type)){
									yyerror("Type Mismatch\n");
									flag=1;
								}
								if(flag == 0){	
									sprintf(quadbuffer, "%s = %s", tempList->tempVar, $3->tempVar);
									generateQuad(quadbuffer);
								}	
							}else{
							//printf("assgn: %s \n", tempR->type );
							struct variableList *retPtr;
							
							//printf("assgn: %s\n",tempList->name );
							if(!search_var_curr_func(tempList->name, &retPtr)){
								if(!search_param_curr_func(tempList->name, &retPtr)){
									if(!searchGlobal(tempList->name, &retPtr)){
										yyerror("Identifier not declared \n");
										flag=1;
									}
									else if(!coercible(retPtr->type, tempR->type)){
										yyerror("Type Mismatch\n");
										flag=1;
									}
								}
								else{
									
									if(!coercible(retPtr->type, tempR->type)){
										yyerror("Type Mismatch\n");
										flag=1;
									}
									
									/*//ICG
									else if(strcmp($3->tempVar , "void")){
										sprintf(quadbuffer,"%s := %s",$1->name,$3->tempVar);
										generateQuad(quadbuffer);
									}*/
								}		
							}
							if(flag == 0 && !coercible(retPtr->type, tempR->type)){
									yyerror("Type Mismatch\n");
									flag =1;
							}
							else if(flag==0){
								//ICG
								if(!strcmp(tempList->arraytype, "array")){
								//assert that the index of LHS is <= to the index size defined
									if(!checkArrayDim(tempList, retPtr)){
										yyerror("index out of range");
									}
									else{
										struct dimList *arrlist = tempList->dimListPtr;
										struct dimList *retlist = retPtr->dimListPtr;
										retlist = retlist->next;
										int prevCount =0;
										while(retlist != NULL){
											if(prevCount == 0)
											sprintf(quadbuffer,"i_%d := %s*%s",intVarCount,arrlist->dim,retlist->dim);
											else
											sprintf(quadbuffer,"i_%d := i_%d*%s",intVarCount,prevCount,retlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											arrlist = arrlist->next;
											sprintf(quadbuffer,"i_%d := i_%d+%s",intVarCount,prevCount,arrlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											retlist = retlist->next;
											
										}
									sprintf(quadbuffer,"i_%d := i_%d*sizeof(%s)",intVarCount,prevCount, retPtr->type);
									generateQuad(quadbuffer);
									prevCount = intVarCount;
									intVarCount++;

									sprintf(quadbuffer,"i_%d := addr(%s)",intVarCount,tempList->name);
									generateQuad(quadbuffer);
 									
									sprintf(quadbuffer,"i_%d[i_%d] := %s",intVarCount,prevCount,$3->tempVar);
									generateQuad(quadbuffer);
									intVarCount++;
									
									
									}
								}
								else if(!strcmp(tempList->arraytype, "simple")){
									if(strcmp($3->tempVar , "void")){
										sprintf(quadbuffer,"%s := %s",$1->name,$3->tempVar);
										generateQuad(quadbuffer);
									}
								}	
							}}}								
							

	| LHS plusequalt RHS				{struct variableList *tempList = $1;
								//struct symbolTable *symPtr = (struct symbolTable *)malloc(sizeof(struct symbolTable));						
							int flag=0;
							struct symbolTable *tempR = $3;
							if(!strcmp(tempList->arraytype, "struct")){
								if(!compatibleArithOp(tempList->type, tempR->type)){
									
									yyerror("Type Mismatch\n");
									flag=1;
								}
								if(flag == 0){	
									sprintf(quadbuffer, "%s = %s + %s", tempList->tempVar,tempList->tempVar, $3->tempVar);
									generateQuad(quadbuffer);
								}	
							}else{
							//printf("assgn: %s \n", tempR->type );
							struct variableList *retPtr;
							
							//printf("assgn: %s\n",tempList->name );
							if(!search_var_curr_func(tempList->name, &retPtr)){
								if(!search_param_curr_func(tempList->name, &retPtr)){
									if(!searchGlobal(tempList->name, &retPtr)){
										yyerror("Identifier not declared \n");
										flag=1;
									}
									else if(!coercible(retPtr->type, tempR->type)){
										yyerror("Type Mismatch\n");
										flag=1;
									}
								}
								else{
									
									if(strcmp(retPtr->type, tempR->type)){
										yyerror("Type Mismatch\n");
										flag=1;
									}
									
									/*//ICG
									else if(strcmp($3->tempVar , "void")){
										sprintf(quadbuffer,"%s := %s",$1->name,$3->tempVar);
										generateQuad(quadbuffer);
									}*/
								}		
							}
							if(flag == 0 && !compatibleArithOp(retPtr->type, tempR->type)){
									yyerror("Type Mismatch\n");
									flag =1;
							}
							else if(flag==0){
								//ICG
								//ICG
								if(!strcmp(tempList->arraytype, "array")){
								//assert that the index of LHS is <= to the index size defined
									if(!checkArrayDim(tempList, retPtr)){
										yyerror("index out of range");
									}
									else{
										struct dimList *arrlist = tempList->dimListPtr;
										struct dimList *retlist = retPtr->dimListPtr;
										retlist = retlist->next;
										int prevCount =0;
										while(retlist != NULL){
											if(prevCount == 0)
											sprintf(quadbuffer,"i_%d := %s*%s",intVarCount,arrlist->dim,retlist->dim);
											else
											sprintf(quadbuffer,"i_%d := i_%d*%s",intVarCount,prevCount,retlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											arrlist = arrlist->next;
											sprintf(quadbuffer,"i_%d := i_%d+%s",intVarCount,prevCount,arrlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											retlist = retlist->next;
											
										}
									sprintf(quadbuffer,"i_%d := i_%d*sizeof(%s)",intVarCount,prevCount, retPtr->type);
									generateQuad(quadbuffer);
									prevCount = intVarCount;
									intVarCount++;

									sprintf(quadbuffer,"i_%d := addr(%s)",intVarCount,tempList->name);
									generateQuad(quadbuffer);
 									sprintf(quadbuffer, "i_%d := i_%d[i_%d]", intVarCount + 1,intVarCount,prevCount);
									generateQuad(quadbuffer);
									intVarCount++;
									sprintf(quadbuffer,"i_%d := i_%d + %s",intVarCount,intVarCount,$3->tempVar);
									generateQuad(quadbuffer);
									intVarCount++;
									
									
									}
								}
								else if(!strcmp(tempList->arraytype, "simple")){
									if(strcmp($3->tempVar , "void")){
										sprintf(quadbuffer,"%s := %s + %s",$1->name,$1->name ,$3->tempVar);
										generateQuad(quadbuffer);
									}
								}
									
							}}}

	| LHS minusequalt RHS				{struct variableList *tempList = $1;
								//struct symbolTable *symPtr = (struct symbolTable *)malloc(sizeof(struct symbolTable));	
							int flag=0;
							struct symbolTable *tempR = $3;
							if(!strcmp(tempList->arraytype, "struct")){
								if(!compatibleArithOp(tempList->type, tempR->type)){
									yyerror("Type Mismatch\n");
									flag=1;
								}
								if(flag == 0){	
									sprintf(quadbuffer, "%s = %s - %s", tempList->tempVar,tempList->tempVar, $3->tempVar);
									generateQuad(quadbuffer);
								}	
									
							}else{
							//printf("assgn: %s \n", tempR->type );
							struct variableList *retPtr;
							
							//printf("assgn: %s\n",tempList->name );
							if(!search_var_curr_func(tempList->name, &retPtr)){
								if(!search_param_curr_func(tempList->name, &retPtr)){
									if(!searchGlobal(tempList->name, &retPtr)){
										yyerror("Identifier not declared \n");
										flag=1;
									}
									else if(!coercible(retPtr->type, tempR->type)){
										yyerror("Type Mismatch\n");
										flag=1;
									}
								}
								else{
									
									if(strcmp(retPtr->type, tempR->type)){
										yyerror("Type Mismatch\n");
										flag=1;
									}
									
									/*//ICG
									else if(strcmp($3->tempVar , "void")){
										sprintf(quadbuffer,"%s := %s",$1->name,$3->tempVar);
										generateQuad(quadbuffer);
									}*/
								}		
							}
							if(flag == 0 && !compatibleArithOp(retPtr->type, tempR->type)){
									yyerror("Type Mismatch\n");
									flag =1;
							}
							else if(flag==0){
								//ICG
								if(!strcmp(tempList->arraytype, "array")){
								//assert that the index of LHS is <= to the index size defined
									if(!checkArrayDim(tempList, retPtr)){
										yyerror("index out of range");
									}
									else{
										struct dimList *arrlist = tempList->dimListPtr;
										struct dimList *retlist = retPtr->dimListPtr;
										retlist = retlist->next;
										int prevCount =0;
										while(retlist != NULL){
											if(prevCount == 0)
											sprintf(quadbuffer,"i_%d := %s*%s",intVarCount,arrlist->dim,retlist->dim);
											else
											sprintf(quadbuffer,"i_%d := i_%d*%s",intVarCount,prevCount,retlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											arrlist = arrlist->next;
											sprintf(quadbuffer,"i_%d := i_%d+%s",intVarCount,prevCount,arrlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											retlist = retlist->next;
											
										}
									sprintf(quadbuffer,"i_%d := i_%d*sizeof(%s)",intVarCount,prevCount, retPtr->type);
									generateQuad(quadbuffer);
									prevCount = intVarCount;
									intVarCount++;

									sprintf(quadbuffer,"i_%d := addr(%s)",intVarCount,tempList->name);
									generateQuad(quadbuffer);
 									
									sprintf(quadbuffer, "i_%d := i_%d[i_%d]", intVarCount + 1,intVarCount,prevCount);
									generateQuad(quadbuffer);
									intVarCount++;
									sprintf(quadbuffer,"i_%d := i_%d - %s",intVarCount,intVarCount,$3->tempVar);
									generateQuad(quadbuffer);
									intVarCount++;
									
									
									}
								}
								else if(!strcmp(tempList->arraytype, "simple")){
									if(strcmp($3->tempVar , "void")){
										sprintf(quadbuffer,"%s := %s - %s",$1->name,$1->name ,$3->tempVar);
										generateQuad(quadbuffer);
									}
								}
									
							}}}

	| LHS incrementt				{struct variableList *tempList = $1;
								//struct symbolTable *symPtr = (struct symbolTable *)malloc(sizeof(struct symbolTable));	
							//struct symbolTable *tempR = $3;
							if(!strcmp(tempList->arraytype, "struct")){
									sprintf(quadbuffer, "%s = %s + 1", tempList->tempVar,tempList->tempVar);
									generateQuad(quadbuffer);
									
							}else{
							//printf("assgn: %s \n", tempR->type );
							struct variableList *retPtr;
							//printf("assgn: %s\n",tempList->name );
							int flag = 0;
							if(!search_var_curr_func(tempList->name, &retPtr)){
								if(!search_param_curr_func(tempList->name, &retPtr)){
									if(!searchGlobal(tempList->name, &retPtr)){
										yyerror("Identifier not declared \n");
										flag=1;
									}
									else if(strcmp(retPtr->type, "int") && strcmp(retPtr->type, "float")){
										yyerror("Invalid Increment Type\n");
										flag=1;
									}
								}
										
							}
							if(flag==0){
								//ICG
								//printf("%s\n", tempList->arraytype);
								if(!strcmp(retPtr->arraytype, "array")){
								//assert that the index of LHS is <= to the index size defined
									if(!checkArrayDim(tempList, retPtr)){
										yyerror("index out of range");
									}
									else{
										struct dimList *arrlist = tempList->dimListPtr;
										struct dimList *retlist = retPtr->dimListPtr;
										retlist = retlist->next;
										int prevCount =0;
										while(retlist != NULL){
											if(prevCount == 0)
											sprintf(quadbuffer,"i_%d := %s*%s",intVarCount,arrlist->dim,retlist->dim);
											else
											sprintf(quadbuffer,"i_%d := i_%d*%s",intVarCount,prevCount,retlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											arrlist = arrlist->next;
											sprintf(quadbuffer,"i_%d := i_%d+%s",intVarCount,prevCount,arrlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											retlist = retlist->next;
											
										}
									sprintf(quadbuffer,"i_%d := i_%d*sizeof(%s)",intVarCount,prevCount, retPtr->type);
									generateQuad(quadbuffer);
									prevCount = intVarCount;
									intVarCount++;

									sprintf(quadbuffer,"i_%d := addr(%s)",intVarCount,tempList->name);
									generateQuad(quadbuffer);
 									
									sprintf(quadbuffer, "i_%d := i_%d[i_%d]", intVarCount + 1,intVarCount,prevCount);
									generateQuad(quadbuffer);
									intVarCount++;
									sprintf(quadbuffer,"i_%d := i_%d + 1",intVarCount,intVarCount);
									generateQuad(quadbuffer);
									intVarCount++;
									
									
									}
								}
								else if(!strcmp(retPtr->arraytype, "simple")){
									
										sprintf(quadbuffer,"%s := %s + 1",$1->name,$1->name);
										generateQuad(quadbuffer);
								}
									
							}}}

	| LHS decrementt				{struct variableList *tempList = $1;
								//struct symbolTable *symPtr = (struct symbolTable *)malloc(sizeof(struct symbolTable));	
							//struct symbolTable *tempR = $3;
							if(!strcmp(tempList->arraytype, "struct")){
									sprintf(quadbuffer, "%s = %s - 1", tempList->tempVar,tempList->tempVar);
									generateQuad(quadbuffer);
									
							}else{
							//printf("assgn: %s \n", tempR->type );
							struct variableList *retPtr;
							int flag=0;
							//printf("assgn: %s\n",tempList->name );
							if(!search_var_curr_func(tempList->name, &retPtr)){
								if(!search_param_curr_func(tempList->name, &retPtr)){
									if(!searchGlobal(tempList->name, &retPtr)){
										yyerror("Identifier not declared \n");
										flag=1;
									}
									else if(strcmp(retPtr->type, "int") && strcmp(retPtr->type, "float")){
										yyerror("Type Mismatch\n");
										flag=1;
									}
								}
										
							}
							
							if(flag==0){	//ICG
								if(!strcmp(tempList->arraytype, "array")){
								//assert that the index of LHS is <= to the index size defined
									if(!checkArrayDim(tempList, retPtr)){
										yyerror("index out of range");
									}
									else{
										struct dimList *arrlist = tempList->dimListPtr;
										struct dimList *retlist = retPtr->dimListPtr;
										retlist = retlist->next;
										int prevCount =0;
										while(retlist != NULL){
											if(prevCount == 0)
											sprintf(quadbuffer,"i_%d := %s*%s",intVarCount,arrlist->dim,retlist->dim);
											else
											sprintf(quadbuffer,"i_%d := i_%d*%s",intVarCount,prevCount,retlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											arrlist = arrlist->next;
											sprintf(quadbuffer,"i_%d := i_%d+%s",intVarCount,prevCount,arrlist->dim);
											generateQuad(quadbuffer);
											prevCount = intVarCount;
											intVarCount++;
											retlist = retlist->next;
											
										}
									sprintf(quadbuffer,"i_%d := i_%d*sizeof(%s)",intVarCount,prevCount, retPtr->type);
									generateQuad(quadbuffer);
									prevCount = intVarCount;
									intVarCount++;

									sprintf(quadbuffer,"i_%d := addr(%s)",intVarCount,tempList->name);
									generateQuad(quadbuffer);
 									
									sprintf(quadbuffer, "i_%d := i_%d[i_%d]", intVarCount + 1,intVarCount,prevCount);
									generateQuad(quadbuffer);
									intVarCount++;
									sprintf(quadbuffer,"i_%d := i_%d - 1",intVarCount,intVarCount);
									generateQuad(quadbuffer);
									intVarCount++;
									
									
									}
								}
								else if(!strcmp(tempList->arraytype, "simple")){
									
										sprintf(quadbuffer,"%s := %s - 1",$1->name,$1->name);
										generateQuad(quadbuffer);
								}
									
							}}}
	;

ifwhilefor_ : if_ 									{$$.nextList = $1.nextList;}
	| while_									{$$.nextList = $1.nextList;}
	| for_  									{$$.nextList = $1.nextList;}
	;

stmt_ : funcCall_ 									{;}	
	| assignment  					{$$.nextList = NULL;}
	| locVar 									{;}
	| return_					{$$.nextList = NULL;}
	;

locVar : result_ idList 					{struct variableList *tempList = $2;
								//struct symbolTable *symPtr = (struct symbolTable *)malloc(sizeof(struct symbolTable));
								struct variableList *retPtr;
								while(tempList!=NULL){
									//printf("Level: %d",level);
									if(search_var_curr_lev(tempList->name, &retPtr)){
										
										yyerror("variable already declared at the same level\n");		
									}
									else if(level==2){
										if(search_param_curr_func(tempList->name, &retPtr)){
											yyerror("Redclaration of Parameter as variable\n");
										}
										else {
										
											insert_var_curr_func(tempList, $1);
										}
									}
									else {
										
										insert_var_curr_func(tempList, $1);
									}
									//printf("dim: %s\n", tempList->dimListPtr->dim);
									tempList = tempList-> next;
									//tempList++;
									//printf("loc var: %s\n",curr_func_ptr->name );
									
								}//printSymTable();
								}
	;

expression: EXP_					{strcpy($$.tempVar, $1->tempVar);
							strcpy($$.type, $1->fixstr);}
	;

if_ 	: ifExp_   body_ jump_marker elset marker body_		{backpatch($1.falseList,$5.quad);
								$$.nextList = mergelists($3.nextList, $6.nextList);
								$$.nextList = mergelists($$.nextList, $2.nextList);} 

	| ifExp_   body_					{//backpatch($1.trueList,$2.quad);
								$$.nextList = mergelists($1.falseList,$2.nextList);}
	;

ifExp_	: ift  '(' expression ')'				{//struct symbolTable *tempR = $3;
								if(strcmp($3.type, "bool") && strcmp($3.type, "int")){
									yyerror("Boolean Expression expected\n");
								}
								else{
									sprintf(quadbuffer,"IF (%s<=0) GOTO",$3.tempVar);
									$$.falseList = addToList(NULL, generateQuad(quadbuffer));
	    								//sprintf(quadBuffer,"GOTO");
									//$$.trueList = addToList(NULL, generateQuad(quadBuffer));
								}}
	;

while_ : whileExp_  dot  body_  				{sprintf(quadbuffer,"GOTO %d",$1.begin);
								generateQuad(quadbuffer);
								backpatch($3.nextList, $1.begin); 
								$$.nextList = $1.falseList;}

	|  whileExp_  body_ 					{sprintf(quadbuffer,"GOTO %d",$1.begin);
								generateQuad(quadbuffer);
								backpatch($2.nextList, $1.begin); 
								$$.nextList = $1.falseList;
								}
	;

whileExp_: whilet marker '(' expression ')'			{//struct symbolTable *tempR = $3;
								if(strcmp($4.type, "bool") && strcmp($4.type, "int")){
									yyerror("Boolean Expression expected\n");
								}
								else{
									sprintf(quadbuffer,"IF (%s<=0) GOTO",$4.tempVar);
									$$.falseList = addToList(NULL, generateQuad(quadbuffer));
									$$.begin = $2.quad;
									//backpatch($$.trueList, $2.quad);
									//printf("value of quad: %d\n", $2.quad); 
									/*backpatch($4.trueList,$6.quad);
	    								$$.nextList = $4.falseList;
	   								backpatch($7.nextList,$2.quad);
									backpatch($8.nextList,$2.quad);*/
								}}
	;

for_ : fort  '(' assignment ';' marker expr_ jump_marker ';' marker assignment jump_marker ')' marker body_ jump_marker
								{if(strcmp($6.type, "bool") && strcmp($6.type, "int")){
									yyerror("Boolean Expression expected\n");
								}
								else{
									//backpatch($3.trueList, $5.quad);
            								backpatch($14.nextList, $9.quad);
            								backpatch($15.nextList, $9.quad);
           								$$.nextList = $6.falseList;
            								//backpatch($6.trueList, $13.quad);
            								backpatch($10.trueList, $5.quad);
									backpatch($11.nextList, $5.quad);
									backpatch($7.nextList, $13.quad);		
								}}
	;

expr_	: marker expression					{sprintf(quadbuffer,"IF (%s<=0) GOTO",$2.tempVar);
								$$.falseList = addToList(NULL, generateQuad(quadbuffer));
								$$.begin = $1.quad;strcpy($$.type, $2.type);}
	;

marker	:							{$$.quad = nextquad+1; }
	;

jump_marker:							{//$$.quad = nextquad+1;
								sprintf(quadbuffer,"GOTO");
								$$.nextList = addToList(NULL, generateQuad(quadbuffer));}
	;

%%

//user subroutines

#include <ctype.h>
//#include"lex.yy.c"



int main (void ) {

	yyparse () ;
	FILE *fp = fopen("ICGOutput.txt", "w+");
	writeSymTable(fp);
	writeICG(fp);
	writeStructTable(fp);
	fclose(fp);
	return 1;
	
}

void yyerror ( char *s ) {
	fprintf ( stderr,"%s in line_no.:%d near token '%s'  ( at column_no.:%d ) \n",s,yylloc.first_line,yytext,yylloc.first_column ) ;
	//exit(0);
}


int search_symTable(char name[], struct symbolTable **ptr){
	int i, flag = 0;
	//printf("Index: %d\n", symTableIndex);
	//struct symbolTable *temp = (struct symbolTable *)malloc(sizeof(struct symbolTable));
	//struct symbolTable temp;
	for(i=0; i<symTableIndex; i++){
		//printf("i: %d",i);
		if(!strcmp(symTable[i].name, name)){
			flag = 1;
			// strcpy(temp->name, symTable[i].name);
			// strcpy(temp->type, symTable[i].type);
			// temp->paramListPtr = symTable[i].paramListPtr;
			// temp->locVarListPtr = symTable[i].locVarListPtr;
			// temp->structMemListPtr = symTable[i].structMemListPtr;
			// temp->num_param = symTable[i].num_param;
			*ptr = &symTable[i]	;	
			return 1;
			
		}
	}
	
	*ptr = NULL;
	return 0;	
}

void insertSymTable(char Name[], char Type[], struct variableList *paramptr, struct variableList *locvarptr, int numParam, struct symbolTable **retPtr){
	//printf("preprocessor part: %s and type: %s\n", Name, Type);
	strcpy(symTable[symTableIndex].name, Name);
	//printf("%s\n", symTable[symTableIndex].name);
	strcpy(symTable[symTableIndex].type, Type);
	symTable[symTableIndex].paramListPtr = paramptr;
	symTable[symTableIndex].locVarListPtr = locvarptr;
	//symTable[symTableIndex].structMemListPtr = structPtr;
	symTable[symTableIndex].num_param = numParam;
	symTable[symTableIndex].level = level;
	*retPtr = &symTable[symTableIndex];
	symTableIndex++;
	
}

void printSymTable(){
	int i;
	printf("Name \t\t Type \t\t ParamPtr \t LocVariable\t  Num_param\n");
	for(i=0;i<symTableIndex;i++){
		printf("%s\t\t %s\t\t %s\t\t %s\t\t  %d\n", symTable[i].name, symTable[i].type, symTable[i].paramListPtr->name, symTable[i].locVarListPtr->name, symTable[i].num_param);
	}
}

void writeSymTable(FILE *fp){
	int i ;
	int num = 1;
	int ret = fprintf(fp, "-------SYMBOL TABLE--------\n");
	if(ret<=0){
		yyerror("error in write");
		return;
	}
	fprintf(fp, "%-5s%-20s%-20s%-60s%-5s\n","SI", "Name", "Type","ParamList","No. Of Param" );
	fprintf(fp, "----------------------------------------------------------------------------\n");
	for(i=0;i<symTableIndex;i++){
		fprintf(fp, "%-5d%-20s%-20s",num++,symTable[i].name,symTable[i].type);
		struct variableList *temp = symTable[i].paramListPtr;
		while(temp!=NULL){
			fprintf(fp, "%s %s", temp->type, temp->name);
			if(!strcmp(temp->arraytype, "array")){
				struct dimList *dim = temp->dimListPtr;
				while(dim != NULL){
					fprintf(fp,"%s","[]");
					dim = dim->next;
				}
			}
			if(temp->next != NULL){
				fprintf(fp," , ");
			}
			temp = temp->next;
	
		}
		fprintf(fp,"\t\t\t%d\nLocalVarList:\n",symTable[i].num_param);
		fprintf(fp, "%-10s%-10s%-5s\n","VarType", "VarName","Level");
		struct variableList *temploc = symTable[i].locVarListPtr;
		while(temploc!=NULL){
			fprintf(fp, "%s   %s", temploc->type, temploc->name);
			if(!strcmp(temploc->arraytype, "array")){
				struct dimList *dim = temploc->dimListPtr;
				while(dim != NULL){
					fprintf(fp,"[%s]",dim->dim);
					dim = dim->next;
				}
			}
			fprintf(fp,"   %d\n", temploc->level);
			temploc = temploc->next;
		}
		fprintf(fp, "\n\n\n");	
		
	}
	
    	
    	
}

void writeStructTable(FILE *fp){
	int i ;
	int num = 1;
	int ret = fprintf(fp, "\n\n\n-------STRUCT TABLE--------\n");
	if(ret<=0){
		yyerror("error in write");
		return;
	}
	fprintf(fp, "%-5s%-20s%-20s%-80s\n","SI", "Name", "Type","MemberList" );
	fprintf(fp, "--------------------------------------------------------------\n");
	for(i=0;i<structTableIndex;i++){
		fprintf(fp, "%-5d%-20s%-20s",num++,structTableList[i].name,structTableList[i].type);
		struct variableList *temp = structTableList[i].memListPtr;
		while(temp!=NULL){
			fprintf(fp, "%s %s", temp->type, temp->name);
			if(!strcmp(temp->arraytype, "array")){
				struct dimList *dim = temp->dimListPtr;
				while(dim != NULL){
					
					fprintf(fp,"[%s]",dim->dim);
					dim = dim->next;
				}
			}
			if(temp->next != NULL){
				fprintf(fp," , ");
			}
			temp = temp->next;
	
		}
		
		fprintf(fp, "\n\n\n");	
		
	}
	
}
void printStructTable(){
	int i;
	printf("Name \t\t Type \t\t StructPtr\n");
	for(i=0;i<structTableIndex;i++){
		printf("%s\t\t %s\t%s\n", structTableList[i].name, structTableList[i].type, structTableList[i].memListPtr->name);
	}
}

void appendVarList(struct variableList **varList, struct variableList **newVar){
	//struct variableList **temp = (struct variableList **)varList;
	//struct variableList **temp1 = (struct variableList **)newVar;
	struct variableList *temp = *newVar;
	temp->next = *varList;
	//*temp1 = temp2;
	//return newVar;
}

void appendDim(struct dimList **list, char dim[]){
	struct dimList *newDim = (struct dimList *)malloc(sizeof(struct dimList));
	strcpy(newDim->dim, dim);
	newDim->next = NULL;
	if(list == NULL){
		*list = newDim;
		return;
	}
	newDim->next = *list;
	*list = newDim;
	return;
}

int checkArrayDim(struct variableList *dimList, struct variableList *retPtr){
	struct dimList *tempArr = dimList->dimListPtr;
	struct dimList *tempRet = retPtr->dimListPtr;
	while(tempArr!=NULL && tempRet!=NULL ){
		if(atoi(tempArr->dim) > atoi(tempRet->dim)){
			return 0;
		}
		tempArr = tempArr->next;
		tempRet = tempRet->next;
	}
	if(tempArr != NULL){
		yyerror("Dimension exceeded");
		return 0;
	}
	if(tempRet != NULL){
		yyerror("few dimension declared");
		return 0;
	}
	return 1;
}

struct structMemberList *appendStructMember(char type[], struct variableList *varList){
	struct structMemberList *memList = (struct structMemberList *)malloc(sizeof(struct structMemberList));
	struct variableList *varTemp = varList;
	if(varTemp != NULL){
		strcpy(memList->name, varTemp->name);
		strcpy(memList->type, type);
		memList->next = NULL;
		varTemp++;
	}
	struct structMemberList * memTemp = memList;
	while(varTemp!=NULL){
		struct structMemberList *temp = (struct structMemberList *)malloc(sizeof(struct structMemberList));
		strcpy(temp->type, type);
		strcpy(temp->name, varTemp->name);
		temp->next =NULL;
		memTemp->next = temp;     //memList is the root
		free(temp);
		if(varTemp->next == NULL)
			break;
		varTemp ++;
	}
	//printStructMemList(memList);
	return memList;
}

struct structMemberList *mergeStructList(struct structMemberList *list1, struct structMemberList *list2){
	struct structMemberList *listTemp = list1;	
	while(listTemp!=NULL){
		if(listTemp->next == NULL)
			break;
		listTemp++;
	}
	listTemp->next = list2;
	return list1;
}
 

void printStructMemList(struct structMemberList *memList){
	struct structMemberList *temp = memList;
	//while(temp!=NULL){
		printf("%s \t %s\n", temp->name, temp->type);
		temp ++;
	//}
}

int search_structTable(char name[], struct structTable **retPtr){
	int i, flag;
	for(i=0;i<structTableIndex;i++){
		if(!strcmp(structTableList[i].name, name)){
			*retPtr = &structTableList[i];
			return 1;
		}
	}
	*retPtr = NULL;
	return 0;	
}

int search_structTypeTable(char type[], struct structTable **retPtr){
	int i, flag;
	for(i=0;i<structTableIndex;i++){
		if(!strcmp(structTableList[i].type, type)){
			*retPtr = &structTableList[i];
			return 1;
		}
	}
	*retPtr = NULL;
	return 0;
	
}

int check_param_type(struct symbolTable *fnPtr, int paramCount, struct symbolTable *paramptr){
	struct variableList *paraList = fnPtr->paramListPtr;
	int count = 0;
	while(paraList!=NULL){
		count++;
		if(count == paramCount){
			if(!strcmp(paraList->type, paramptr->type))
				return 1;
			else
				return 0;
		}
		paraList = paraList->next;
	}
	yyerror("Parameter count does not match with function defined\n");
	return 0;
}

void insertStructTableList(char structName[],char type[],  struct variableList *memList, struct structTable **retPtr){
	strcpy(structTableList[structTableIndex].name, structName);
	if(type != NULL)
		strcpy(structTableList[structTableIndex].type, type);
	structTableList[structTableIndex].memListPtr = memList;
	*retPtr = &structTableList[structTableIndex];
	structTableIndex++;
}


int coercible(char type_a[], char type_b[]){
	if((!strcmp(type_a, "int") || !strcmp(type_a, "float")) && (!strcmp(type_b, "int") || !strcmp(type_b, "float")))
		return 1;
	else if(!strcmp(type_a, "char") && !strcmp(type_b, "char"))
		return 1;
	else if(!strcmp(type_a, "bool") && !strcmp(type_b, "bool"))
		return 1 ;
	else
		return 0;
}

int compatibleArithOp(char type_a[], char type_b[]){
	if((!strcmp(type_a, "int") || !strcmp(type_a, "float")) && (!strcmp(type_b, "int") || !strcmp(type_b, "float")))
		return 1;
	else if(!strcmp(type_a, "bool") && !strcmp(type_b, "bool"))
		return 1 ;  //two char can not be added
	else
		return 0;
}

char *resultTypeExp(char type_a[], char type_b[]){
	if(!strcmp(type_a, "int") &&  !strcmp(type_b, "int"))
		return "int";
	if(!strcmp(type_a, "float") &&  !strcmp(type_b, "float"))
		return "float";
	if(!strcmp(type_a, "int") &&  !strcmp(type_b, "float"))
		return "float";
	if(!strcmp(type_a, "float") &&  !strcmp(type_b, "int"))
		return "float";
	//if(!strcmp(type_a, "char") &&  !strcmp(type_b, "char"))
	//	return "char";
}

int search_param_curr_func(char name[],struct variableList **ret){
	if(curr_func_ptr == NULL)
		return 0;
	struct variableList *paraList = curr_func_ptr->paramListPtr;
	struct variableList *temp = *ret;
	while(paraList!=NULL){
		if(!strcmp(paraList->name, name)){
			temp = paraList;
			*ret = temp;
			return 1;
		}
		paraList = paraList->next;
	}
	return 0;
}


void insert_param_curr_func(struct variableList *param, char type[]){
	struct variableList *paraList = curr_func_ptr->paramListPtr;

	struct variableList *newParam = (struct variableList *)malloc(sizeof(struct variableList));
	strcpy(newParam->name, param->name);
	strcpy(newParam->type, type);
	strcpy(newParam->arraytype, param->arraytype);
	strcpy(newParam->param, "param");
	newParam->level = 1;
	newParam->dimListPtr = param->dimListPtr;
	newParam->next = NULL;
	
	if(paraList == NULL){
		paraList = newParam;
		curr_func_ptr->paramListPtr = paraList;
		return;
	}
	while(paraList->next != NULL){
		paraList = paraList->next;
	}
	paraList->next = newParam;
	//curr_func_ptr->paramListPtr = paraList;
	
}


void delete_content( int lev){
	//code will be added later
	struct variableList *varList = curr_func_ptr->locVarListPtr;
	struct variableList *temp = curr_func_ptr->locVarListPtr;
	if(varList != NULL){
	while(varList->level ==lev){
		varList = varList->next;
		temp = temp->next;
		curr_func_ptr->locVarListPtr = temp;
			
	}}
	while(varList!=NULL){
		
		if(varList->level == lev){
			temp->next = varList->next;

		}
		varList = varList->next;
		while(temp->next!=varList){
			temp = temp->next;
		}

	}
}

int search_var_curr_struct(char name[], struct structTable **ret){
	struct variableList *varList = curr_struct_ptr->memListPtr;
	//struct variableList *temp = *ret;
	while(varList!=NULL){
		if(!strcmp(varList->name, name) ){
			*ret = curr_struct_ptr;
			return 1;
		}
		varList = varList->next;
	}
	return 0;
}

int search_mem_structSym(char name[],struct variableList *symPtr, struct variableList **retMem){
	struct variableList *tempMem = symPtr->structMemListPtr;
	while(tempMem!=NULL){
		//printf("member: %s\n", name);
		if(!strcmp(tempMem->name, name)){
			*retMem = tempMem;
			return 1;
		}
		tempMem = tempMem->next;
	}
	*retMem = NULL;
	return 0;
}

void insert_var_curr_struct(struct variableList *var, char type[]){
	struct variableList *varList = curr_struct_ptr->memListPtr;
	struct variableList *temp = curr_struct_ptr->memListPtr;

	struct variableList *newParam = (struct variableList *)malloc(sizeof(struct variableList));
	strcpy(newParam->name, var->name);
	strcpy(newParam->type, type);
	strcpy(newParam->arraytype, var->arraytype);
	strcpy(newParam->param, "var");
	newParam->level = 0;
	newParam->dimListPtr = var->dimListPtr;
	newParam->offset = offset;
	int prod_dim = 1;
	struct dimList *dimTemp = var->dimListPtr;
	while(dimTemp!=NULL){
		prod_dim *= atoi(dimTemp->dim);
		dimTemp = dimTemp->next;
	}
	

	if(strcmp(type, "int"))
		offset += prod_dim*sizeof(int);
	else if(strcmp(type, "float"))
		offset += prod_dim*sizeof(float);
	else if(strcmp(type, "char"))
		offset += prod_dim*sizeof(char);
	else if(strcmp(type, "bool"))
		offset += prod_dim*sizeof(bool);
	else
		offset += 10;    ///this case is for struct type member in a structure..

	newParam->next = NULL;
	//printf("var list%s\n", varList->name);
	if(varList == NULL){
		varList = newParam;
		curr_struct_ptr->memListPtr = varList;

		return;
	}
	while(varList->next != NULL){
		varList = varList->next;
	}
	varList->next = newParam;
	curr_struct_ptr->memListPtr = temp;

	return;
}

int search_var_curr_func(char name[],struct variableList **ret ){
	if(curr_func_ptr == NULL)
		return 0;
	struct variableList *varList = curr_func_ptr->locVarListPtr;
	struct variableList *temp = *ret;
	int lev = level;
	while(lev >= 2){
	varList = curr_func_ptr->locVarListPtr;
	while(varList!=NULL){
		if(!strcmp(varList->name, name) && varList->level == lev){
			temp = varList;
			*ret = temp;
			return 1;
		}
		varList = varList->next;
	}
	lev--;}
	return 0;
}
int search_var_curr_lev(char name[],struct variableList **ret ){
	if(curr_func_ptr == NULL)
		return 0;
	struct variableList *varList = curr_func_ptr->locVarListPtr;
	struct variableList *temp = *ret;
	int lev = level;
	while(varList!=NULL){
		if(!strcmp(varList->name, name) && varList->level == lev){
			temp = varList;
			*ret = temp;
			return 1;
		}
		varList = varList->next;
	}
	return 0;
}
int searchGlobal(char name[], struct variableList **retPtr){
	//int lev = 0;
	int i;
	//printf("searchGlobal\n");
	for(i=0;i<symTableIndex;i++){
		if(!strcmp(symTable[i].name, name)){
			*retPtr = symTable[i].locVarListPtr;
			return 1;
		}
	}
	*retPtr = NULL;
	return 0;
}


void insert_var_curr_func(struct variableList *var, char type[]){
	struct variableList *varList = curr_func_ptr->locVarListPtr;
	//struct variableList *temp = curr_func_ptr->locVarListPtr;

	struct variableList *newParam = (struct variableList *)malloc(sizeof(struct variableList));
	strcpy(newParam->name, var->name);
	strcpy(newParam->type, type);
	strcpy(newParam->arraytype, var->arraytype);
	strcpy(newParam->param, "var");
	newParam->level = level;
	newParam->dimListPtr = var->dimListPtr;
	
	if(!strcmp(type, "int") || !strcmp(type, "float") || !strcmp(type, "char") || !strcmp(type, "bool")){
		;
	}
	else{
		newParam->structMemListPtr = call_struct_ptr->memListPtr;
	}
	//printf("mem func: %s\n", newParam->structMemListPtr->name);

	newParam->next = NULL;
	//printf("var list%s\n", varList->name);
	if(varList == NULL){
		varList = newParam;
		curr_func_ptr->locVarListPtr = varList;

		return;
	}
	while(varList->next != NULL){
		varList = varList->next;
	}
	varList->next = newParam;
	//curr_func_ptr->locVarListPtr = temp;

	return;
}



//function for intermediate code generation//

void backpatch(struct backpatchList* list, int gotoL){
	//printf("In backpatch with %d\n", gotoL);
	//fflush(stdout);
	if(list == NULL){
		return;
	} else{
		struct backpatchList* temp;
		while(list){
			
			if(list->entry != NULL){
				
				list->entry->gotoL = gotoL;
			}
			//printf("inside packpatch\n");
			//printf("backpatching: %s",list->entry->code);
			temp = list;
			list = list->next;
			//free(temp);
		}
	}
}
/*
void mergeQuadList(struct variableList *list1, struct variableList *list2){

}

void generateQuad(char name[],char op[10], struct symbolTable *tempList){
	int option = tempList->option;
	switch(option){
	case 1:
		printf("%s %s %d\n", name, op, tempList->value.i);
		break;
	
	}
}
*/


//returns current code line
struct quadList *generateQuad(char *code){
	//printf("In generateQuad\n");
	//fflush(stdout);
	nextquad++;
	printf("%d %s\n",nextquad,code);
	//Create the element
	struct quadList* newCodeLine = (struct quadList *)malloc(sizeof(struct quadList));
	strcpy(newCodeLine->code, code);
	//printf("generateQuad func!!\n");
	newCodeLine->next = NULL;
	newCodeLine->gotoL = -1;
	
	//refresh the header/tail
	if(codeLineHead == NULL){
		codeLineHead = newCodeLine;
		codeLineTail = newCodeLine;
	}
	else{
		codeLineTail->next = newCodeLine;
		codeLineTail = newCodeLine;
	}
	
	
	//return a pointer to the new element
	return newCodeLine;
}

struct backpatchList* mergelists(struct backpatchList* a, struct backpatchList* b){
	//printf("In mergelists\n");
	//fflush(stdout);
	if(a != NULL && b == NULL){
		return a;
	}
	else if(a == NULL && b != NULL){
		return b;
	}
	else if(a == NULL && b == NULL){
		return NULL;
	}
	else{
		struct backpatchList* temp = a;
		while(a->next){
			a = a->next;
		}
		a->next = b;
		return temp;
	}
}

struct backpatchList* addToList(struct backpatchList* list, struct quadList* entry){
	//printf("In addToList\n");
	//fflush(stdout);
	if(entry == NULL){
		return list;
	}
	else if(list == NULL){
		struct backpatchList* newEntry = malloc(sizeof(struct backpatchList));
		newEntry->entry = entry;
		newEntry->next = NULL;
		return newEntry;
	}
	else{
		struct backpatchList* newEntry = malloc(sizeof(struct backpatchList)), *temp = list;
		newEntry->entry = entry;
		newEntry->next=NULL;
		while(list->next){
			list = list->next;
		}
		list->next = newEntry;
		return temp;
	}
}


bool writeICG(FILE *fp)
{
    struct quadList *codeLine = codeLineHead;

    if(codeLine == NULL)
    {
        printf("No ICG\n");

        return false;
    }

    int lineNumber = 1;
	
	fprintf(fp,"\n\n---------------ICG--------------\n");
    while(codeLine)
    {
    	int ret;
    	//No goto
    	if(codeLine->gotoL == -1){
    		ret = fprintf(fp, "%d %s\n", lineNumber, codeLine->code);
    	}
    	//goto
    	else{
    		ret = fprintf(fp, "%d %s %d\n", lineNumber, codeLine->code, codeLine->gotoL);
    	}
        if(ret <= 0)
        {
            printf("error in file write!!\n");

            return false;
        }

        codeLine = codeLine->next;
        lineNumber++;
    }

    return true;
}


bool printSymbolTable(FILE *outputFile)
{

}

void newTemp(char type[], struct symbolTable **retPtr){
	
}



