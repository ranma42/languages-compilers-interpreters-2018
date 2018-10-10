              int record_idx = 0, field_idx = 0;

              void new_field() {
                printf("\n%d:\t", field_idx++);
              }

              void new_record() {
                printf("=== RECORD %d ===", record_idx++);
                field_idx = 0;
                new_field();
              }

COMMA       ,
CRLF        \r\n
TEXTDATA    [^,\0-\x1F]+

%%

                          new_record();
{CRLF}                    printf("\n"); new_record();
{COMMA}                   new_field();
{TEXTDATA}                printf("%s", yytext);

%%

int yywrap(void)
{
  printf("\n"); 
  return 1;
}

int main(void) {
  yylex();
  return 0;
}
