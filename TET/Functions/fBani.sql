--***
create function dbo.fBani(@val decimal(30,10),@nrZecimale int	) returns money	-- parametri: valoare si nr zecimale
as
begin
return convert(money,round(isnull(@val,0),@nrzecimale))
end
