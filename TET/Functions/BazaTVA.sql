--***
create function  BazaTVA (@ValFact float, @Baza float, @RecalcBaza int, @DifIgnor float)
returns float 
begin
 return (case when @RecalcBaza = 1 and abs(@ValFact - @Baza) <= @DifIgnor then @ValFact else @Baza end)
end
