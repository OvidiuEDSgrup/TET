--***
create procedure wStergIndicatorCategorie @sesiune varchar(50), @parXML xml
as
begin try

declare @codCat varchar(20),@codInd varchar(20)
Set @codCat = @parXML.value('(/row/@codCat)[1]','varchar(20)')
Set @codInd = @parXML.value('(/row/row/@cod)[1]','varchar(20)')


declare @mesajeroare varchar(100)
set @mesajeroare=''

if @mesajeroare=''
begin
	delete from compcategorii where Cod_Categ=@codCat and Cod_Ind=@codInd
end
else 
	raiserror(@mesajeroare, 11, 1)
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
