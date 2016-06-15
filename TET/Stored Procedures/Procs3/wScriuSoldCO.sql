--***
Create
procedure wScriuSoldCO @sesiune varchar(50), @parXML xml 
as
declare @an int, @o_an int, @marca varchar(6), @datajos datetime,
@o_data datetime, @data datetime, @zilecoram int, @ptupdate int, @tip varchar(40), @tipAntet varchar(40), @subtip varchar(40), 
@userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254)

begin try
	--BEGIN TRAN
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuSoldCOSP')
		exec wScriuSoldCOSP @sesiune, @parXML OUTPUT
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crssoldco cursor for
	select 	isnull(ptupdate, 0) as ptupdate, isnull(tip, '') as tip, isnull(tipAntet, '') as tipAntet, isnull(subtip, '') as subtip, 
	isnull(an,0) as an, isnull(o_an,1901) as o_an,
	isnull(marca, '') as marca, isnull(zilecoram,1) as zilecoram
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		ptupdate int '@update',
		tip char(40) '../@tip', 
		tipAntet char(40) '@tip', 
		subtip char(40) '@subtip', 
		an int '@an', 
		o_an int '@o_an', 
		marca varchar(6) '../@marca', 
		zilecoram int '@zilecoram'
	)

	open crssoldco
	fetch next from crssoldco into @ptupdate, @tip, @tipAntet, @subtip, @an, @o_an, @marca, @zilecoram
	while @@fetch_status=0
	begin
		select @o_data='01/01/1901'		
		set @data=dbo.EOY(convert(datetime,'01/01/'+str(@an,4)))
		if @o_an<>0
			set @o_data=dbo.Eom(convert(datetime,'01/01/'+str(@o_an,4)))

		set @datajos=dbo.bom(@data)
		if not exists (select Marca from istPers where marca=@Marca and Data=@Data)
			exec scriuistPers @datajos, @data, @Marca, '', 0, 1

		update istPers set coef_invalid=@zilecoram where Data=@data and Marca=@marca
			
		fetch next from crssoldco into @ptupdate, @tip, @tipAntet, @subtip, @an, @o_an, @marca, @zilecoram
	end

	--refresh pozitii in cazul in care meniu este 'S1'-> tab de tip pozdoc
	if @tipAntet in ('','S')
	begin
		declare @docXMLSoldCO xml
		set @docXMLSoldCO='<row marca="'+rtrim(@marca)+ '" tip="'+(case when @tipAntet='' then 'S' else @tipAntet end)+'"/>'
		exec wIaSoldCO @sesiune=@sesiune, @parXML=@docXMLSoldCO
	end

	--COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0)=0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crssoldco' and session_id=@@SPID)
if @cursorStatus=1 
	close crssoldco
if @cursorStatus is not null 
	deallocate crssoldco

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
