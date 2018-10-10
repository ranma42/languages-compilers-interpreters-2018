COMMA       ,
CRLF        \r\n
TEXTDATA    [^,\0-\x1F]+

%%

{CRLF}                    printf("\n=== NEW RECORD ===\n");
{COMMA}                   printf("\n");
{TEXTDATA}                printf("%s", yytext);

%%

int yywrap(void)
{
  return 1;
}

int main(void) {
  yylex();
  return 0;
}
