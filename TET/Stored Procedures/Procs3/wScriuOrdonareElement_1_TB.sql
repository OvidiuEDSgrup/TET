--***
create procedure wScriuOrdonareElement_1_TB (@sesiune varchar(50), @parXML xml)
as
begin
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
--	if object_id('tempdb..#ordine') is not null drop table #ordine

	declare	@ordine int, @element_1 varchar(50), @categorie varchar(20), @o_element_1 varchar(50),
			@o_ordine int, @update bit,
			@max_ordine int, @min_ordine int, @directie int
	select	@ordine=@parXML.value('(row/row/@ordine)[1]','int'),
			@element_1=@parXML.value('(row/row/@element_1)[1]','varchar(50)'),
			@categorie=@parXML.value('(row/@codCat)[1]','varchar(50)'),
			@o_element_1=@parXML.value('(row/row/@element_1)[1]','varchar(50)'),
			@o_ordine=@parXML.value('(row/row/@o_ordine)[1]','int'),
			@update=@parXML.value('(row/row/@update)[1]','bit')
	
	if isnull(@update,0)=0
		raiserror ('Nu este permisa adaugarea! Doar elementele deja existente (generate) se pot ordona!',16,1)
	if (@element_1 <> @o_element_1)
		raiserror ('Nu este permisa modificarea elementului!',16,1)
--	select ordine, element_1, din_tabel into #ordine from fOrdineElement_1_TB(@categorie)

	--> re-populare ordonare - in cazul in care tabela de configurari nu e sincronizata cu expval:
	insert into cfgOrdineElement1(categorie, element_1, ordine)
	select @categorie, element_1, ordine from fOrdineElement_1_TB(@categorie) where din_tabel=0

	select	@min_ordine=(case when @ordine<@o_ordine then @ordine else @o_ordine end),
			@max_ordine=(case when @ordine>@o_ordine then @ordine else @o_ordine-1 end),
			@directie=(case when @ordine>@o_ordine then -1 else 1 end)
	
	--> deplasare elemente care se afla intre numerele de ordine care se inlocuiesc
	update c set ordine=ordine+@directie
	from cfgOrdineElement1 c where c.categorie=@categorie and c.ordine between @min_ordine and @max_ordine

	--> modificarea ordinii pentru elementul actual
	update c set ordine=@ordine
	from cfgOrdineElement1 c where c.categorie=@categorie and rtrim(c.element_1)=@element_1
--	if object_id('tempdb..#ordine') is not null drop table #ordine
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wScriuOrdonareElement_1_TB '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
