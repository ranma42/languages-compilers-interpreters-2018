        int num_lines = 0, num_chars = 0;

%%

\n      ++num_lines; ++num_chars;
.       ++num_chars;

%%

int yywrap(void)
{
  printf("# of lines = %d, # of chars = %d\n",
    num_lines, num_chars);
  return 1;
}

int main()
{
  yylex();
  return 0;
}
