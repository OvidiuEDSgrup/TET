--***
create function ScutitTVA (@ValFact float, @Baza float, @CotaTVA int, @RecalcBaza int, @DifIgnor float)
returns float 
begin
 return (case when @RecalcBaza = 1 then (case when abs(@ValFact - @Baza) > @DifIgnor then @ValFact - @Baza else 0 end) 
  when @CotaTVA = 0 then @ValFact else 0 end)
end
