--***
create procedure wStergPostLucru @sesiune varchar(50), @parXML xml
as
begin try

declare @postlucru int, @mesajeroare varchar(254)

Set @postlucru= @parXML.value('(/row/@postlucru)[1]','int')
set @mesajeroare=(case when exists (select 1 from devauto where 
	Executant=rtrim(CONVERT(char(3),@postlucru))) then 
	'Codul ales este folosit in documente sau in alte cataloage!' 
	when @postlucru is null then 'Nu a fost ales codul pt. stergere!' else '' end)

if @mesajeroare=''
	delete from Posturi_de_lucru where Postul_de_lucru=@postlucru
else 
	raiserror(@mesajeroare, 11, 1)
	
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
