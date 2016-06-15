--***  
create procedure wValidareCodFiscal /*@sesiune varchar(50), */@cod_fiscal varchar(13), @tert varchar(13),
				@coderoare int output , @msgeroare varchar(500) output
as  
declare @lungcod int, @idxstart int, @idx int, @eCNP int, @cheie varchar(12), @suma int, @cifractrl char(1), @Sb char(9), @denumire varchar(100)

set @lungcod = len(rtrim(@cod_fiscal)) 
set @idxstart = 1  
  
while @idxstart <= @lungcod and SUBSTRING(@cod_fiscal, @idxstart, 1) not between '0' and '9'  
 set @idxstart = @idxstart + 1  
  
if @idxstart > @lungcod  
begin  
 select @coderoare=1, @msgeroare='Cod fiscal necompletat'
 return   
end  
  
set @idxstart = @idxstart - 1  
  
set @eCNP=(case when @lungcod - @idxstart = 13 then 1 else 0 end)  
  
if @eCNP=1  
 set @cheie = '279146358279'  
else   
 set @cheie = '753217532'  
   
set @idx = 1  
set @suma = 0  
  
begin try  
 while @idx < @lungcod - @idxstart  
 begin  
  set @suma = @suma + CONVERT(int, substring(@cod_fiscal, (case when @eCNP=1 then @idxstart + @idx else @lungcod - @idx end), 1)) * (case when @eCNP = 1 or 10 - @idx between 1 and LEN(@cheie) then CONVERT(int, substring(@cheie, (case when @eCNP = 1 then @idx else 10 - @idx end), 1)) else 0 end)  
  set @idx = @idx + 1  
    
 end  
set @cifractrl = (case when @eCNP=1 then left(ltrim(convert(char(15), @suma % 11)), 1) else CONVERT(char(1), ((@suma * 10) % 11) % 10) end)  
end try  
begin catch  
 select  @coderoare=3, @msgeroare='Cod fiscal eronat - caractere nepermise'
 return  
end catch  
  
if @cifractrl <> RIGHT(RTrim(@cod_fiscal), 1)  
begin  
 select @coderoare=2, @msgeroare='Cod fiscal eronat - cifra de control incorecta! Cifra corecta:'+@cifractrl
 return  
end  
  
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output  
select @denumire=denumire   
from terti   
where Subunitate=@Sb and Cod_fiscal=@cod_fiscal   
and (isnull(@tert, '')='' or tert<>@tert)  
  
if @denumire is not null  
begin  
 select @coderoare=4, @msgeroare='Cod fiscal existent la tertul ' + RTrim(@denumire) 
 return  
end  
  
select @coderoare=0, @msgeroare='OK' 
  
  
--exec wValidareCodFiscal '','1234567895','1231321'
