--***
create procedure yso_wpopRapFormAvizBon @sesiune varchar(50), @parxml xml
as
set transaction isolation level read uncommitted
declare @eroare varchar(1000)

set @eroare=''

begin try
	declare @utilizatorASiS varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	
	declare @sub varchar(9), @DetaliereBonuri int
	select	@sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@sub,'') end),
		@DetaliereBonuri=(case when Parametru='DETBON' then Val_logica else isnull(@DetaliereBonuri, 0) end)
	from par
	where Tip_parametru='GE' and Parametru in ('SUBPRO')
		or Tip_parametru='PO' and Parametru in ('DETBON') 
	
	declare @idantetbon int, @tip varchar(2), @numar varchar(50), @data datetime
	
	set @idantetbon= @parXML.value('(/*/@idantetbon)[1]','int')
	
	if @idantetbon is null
		raiserror('Nu s-a putut identifica bonul! Selectati un bon din tabel !',16,1)
	
	select top 1
		@tip=ISNULL(a.Bon.value('(/date/document/@tipdoc)[1]','varchar(2)'), (case when a.Chitanta=1 then 'AC' else 'AP' end)),
		@numar= ISNULL(a.Bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(20)'), 
			(case when a.chitanta=0 then LTrim(a.Factura) 
				when @DetaliereBonuri=1 then RTrim(CONVERT(varchar(4),a.Casa_de_marcat))+right(replace(str(a.Numar_bon),' ','0'),4) 
				else 'B'+LTrim(str(day(a.Data_bon)))+'G'+rtrim(a.Gestiune) end)),
		@data=--ISNULL(a.Bon.value('(/date/document/@data)[1]','datetime'), 
			Data_bon
	from antetBonuri a where IdAntetBon=@idantetbon
	
	select @tip as tip, @numar as numar, convert(varchar(20),@data,101) as data,1 as nrExemplare for xml raw
end try
begin catch
	set @eroare='yso_wpopRapFormAvizBon:'+
		char(10)+rtrim(ERROR_MESSAGE())
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)