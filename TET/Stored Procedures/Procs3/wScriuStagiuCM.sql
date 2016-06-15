--***
Create procedure wScriuStagiuCM @sesiune varchar(50), @parXML xml 
as
declare @an int, @o_an int, @luna int, @o_luna int, @marca varchar(6), @Lm varchar(9),
	@o_data15 datetime, @data15 datetime, @zilestagiu int, @bazastagiu int, 
	@ptupdate int, @tip varchar(40), @tipAntet varchar(40), @subtip varchar(40),
	@userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254)

begin try
	--BEGIN TRAN
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuStagiuCMSP')
		exec wScriuStagiuCMSP @sesiune, @parXML OUTPUT
--	exec wValidarePersintr @sesiune, @parXML
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crsstagiucm cursor for
	select 	isnull(ptupdate, 0) as ptupdate, isnull(tip, '') as tip, isnull(tipAntet, '') as tipAntet, isnull(subtip, '') as subtip, 
	isnull(marca, '') as marca, isnull(lm, '') as lm, 
	isnull(luna,0) as luna, isnull(o_luna,0) as o_luna,
	isnull(an,0) as an, isnull(o_an,1901) as o_an,
	isnull(zilestagiu,1) as zilestagiu, isnull(bazastagiu,1) as bazastagiu
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		ptupdate int '@update',
		tip char(40) '../@tip', 
		tipAntet char(40) '@tip', 
		subtip char(40) '@subtip', 
		marca varchar(6) '../@marca', 
		lm varchar(9) '@lm', 
		luna int '@luna', 
		o_luna int '@o_luna', 
		an int '@an', 
		o_an int '@o_an', 
		zilestagiu int '@zilestagiu',
		bazastagiu decimal(12,0) '@bazastagiu'		
	)

	open crsstagiucm
	fetch next from crsstagiucm into @ptupdate, @tip, @tipAntet, @subtip, @marca, @Lm, @luna, @o_luna, @an, @o_an, @zilestagiu, @bazastagiu
	while @@fetch_status=0
	begin
		if @ptupdate=0 AND ISNULL(@Lm,'')=''
			select @Lm=loc_de_munca from personal where marca=@marca
		select @o_data15='01/01/1901'		
		set @data15=convert(datetime,str(@luna,2)+'/15/'+str(@an,4))
		if @o_an<>0 and @o_luna<>0
			set @o_data15=convert(datetime,str(@o_luna,2)+'/15/'+str(@o_an,4))
		if @ptupdate=1 and @Data15<>@o_data15
			delete from net where Data=@o_data15 and Marca=@marca

		if not exists (select Marca from istPers where marca=@Marca and Data=@Data15)
			exec scriuNet_salarii @data15, @data15, @Marca, @Lm, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 
			0, 0, @zilestagiu, 0, 0, @bazastagiu, 0, 0, 0, 0

		update net set Ded_suplim=@zilestagiu, Baza_CAS=@bazastagiu where Data=@data15 and Marca=@marca
			
		fetch next from crsstagiucm into @ptupdate, @tip, @tipAntet, @subtip, @marca, @Lm, @luna, @o_luna, @an, @o_an, @zilestagiu, @bazastagiu
	end

	--refresh pozitii in cazul in care meniu este 'S'-> tab de tip pozdoc
	if @tipAntet in ('','S')
	begin
		declare @docXMLStagiuCM xml
		set @docXMLStagiuCM='<row marca="'+rtrim(@marca)+ '" tip="'+(case when @tipAntet='' then 'S' else @tipAntet end)+'"/>'
		exec wIaStagiuCM @sesiune=@sesiune, @parXML=@docXMLStagiuCM
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
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsstagiucm' and session_id=@@SPID)
if @cursorStatus=1 
	close crsstagiucm
if @cursorStatus is not null 
	deallocate crsstagiucm

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
