CREATE FUNCTION dbo.[IsDigit] (@string VARCHAR(MAX))  
/*
Select dbo.isdigit('how many times must I tell you')
Select dbo.isdigit('294856')
Select dbo.isdigit('569.45')
*/
RETURNS INT
AS BEGIN
      RETURN CASE WHEN PATINDEX('%[^0-9]%', @string) > 0 THEN 0
                  ELSE 1
             END
   END
