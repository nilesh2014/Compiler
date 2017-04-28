#ifndef PARSE_H
#define PARSE_H

#include<stdbool.h>


union Data {
	int i;
	float f;
	char c;
	char str[20];
	bool b;
	
};


struct symbolTable{
	char name[30];
	char type[30];
	//int offset;
	struct variableList *paramListPtr;
	struct variableList *locVarListPtr;
	//struct variableList *structMemListPtr;
	int num_param;
	int option;
	union Data value;
	int level;
	char tempVar[10];
		
};

struct variableList{
	char name[20];
	char type[20];   //int, float, etc
	char arraytype[10];    //array or simple
	char param[10];  //either var or param type
	int level;
	int offset;
	char tempVar[10];
	struct dimList *dimListPtr;
	struct variableList *structMemListPtr;
	struct variableList *next;
};


struct structMemberList{
	char name[20];
	char type[20];
	struct structMemberList *next;
};


struct structTable{
	char name[20];
	char type[20];
	struct variableList *memListPtr;	
};

struct dimList{
	char dim[10];
	struct dimList *next;
};


struct quadTable{
	char op[5];
	char arg1[10];
	char arg2[10];
	char result[10];
};



struct nonTstruct{
	char fixstr[30];
	char tempVar[10];
	int option;
	union Data value;
};


struct codeLineEntry
{
    char code[100];
    
    int gotoL;

    struct codeLineEntry *next;
    
} ;

struct backpatchList
{
    struct codeLineEntry *entry;

    struct backpatchList *next;

}  ;




/*struct symbolTable symTable[10000];
int symTableIndex=0;

struct structTable structTableList[1000];
int structTableIndex = 0;*/



int search_symTable(char [], struct symbolTable **ptr);

void insertSymTable(char name[], char type[], struct variableList *paramptr, struct variableList *locvarptr, int,struct symbolTable **retPtr );

void printSymTable();

void printStructTable();

void appendVarList(struct variableList **varList, struct variableList **newVar);

void appendDim(struct dimList **list, char dim[]);

int checkArrayDim(struct variableList *tempList, struct variableList *retPtr);

struct structMemberList *appendStructMember(char type[], struct variableList *varList);

struct structMemberList *mergeStructList(struct structMemberList *list1, struct structMemberList *list2);

void printStructMemList(struct structMemberList *memList);

int search_structTable(char name[], struct structTable **);

int search_structTypeTable(char type[],struct structTable ** );   

int check_param_type(struct symbolTable *fnPtr, int paramCount, struct symbolTable *paramptr);

void insertStructTableList(char name[], char type[], struct variableList *memList, struct structTable **);

int coercible(char type_a[], char type_b[]);

int compatibleArithOp(char type_a[], char type_b[]);

char *resultTypeExp(char type_a[], char type_b[]);

int search_param_curr_func(char name[], struct variableList **);

void insert_param_curr_func(struct variableList *param, char type[]);

void delete_content(int lev);

int search_var_curr_struct(char name[], struct structTable **);



void insert_var_curr_struct(struct variableList *var, char type[]);

int search_var_curr_func(char name[], struct variableList **);

int search_var_curr_lev(char name[],struct variableList **ret );

int searchGlobal(char name[], struct variableList **retPtr);

void insert_var_curr_func(struct variableList *var, char type[]);

int search_mem_structSym(char name[],struct variableList *symPtr, struct variableList **retMem);


void backpatch(struct backpatchList* list, int gotoL);

//void mergeQuadList(struct variableList *list1, struct variableList *list2);

struct backpatchList* mergelists(struct backpatchList* a, struct backpatchList* b);

struct backpatchList* addToList(struct backpatchList* list, struct codeLineEntry* entry);

//void generateQuad(char *str);
//void generateQuad(char name[],char op[10], struct symbolTable *tempList);

struct codeLineEntry *genquad(char *code);

void newTemp(char type[], struct symbolTable **retPtr);

bool writeICG(FILE *fp);

void writeSymTable(FILE *fp);

void writeStructTable(FILE *fp);

#endif

