--***
create procedure wIaOrdonareElement_1_TB(@sesiune varchar(50), @parXML xml)
as
begin
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	declare @categorie varchar(20)
	select @categorie=@parXML.value('(row/@codCat)[1]','varchar(20)')

	select ordine, element_1 from fOrdineElement_1_TB(@categorie) for xml raw
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wIaOrdonareElement_1_TB '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
