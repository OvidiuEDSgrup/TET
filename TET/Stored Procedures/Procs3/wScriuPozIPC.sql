--***
create procedure [dbo].[wScriuPozIPC] @sesiune varchar(50), @parXML xml 
as
declare @datal datetime,@tip char(2),@subtip char(2),@an float,@luna float,
	@indtotal float,@indmarfurialim float,@indmarfurinealim float,@indservicii float,
	@datagrp datetime,@angrp float,@lunagrp float,@userASiS char(10),@mesaj varchar(254),
	@docXMLIaPozIPC xml, @fetchstatus int

begin try
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozIPCSP')
		exec wScriuPozIPCSP @sesiune, @parXML output
 
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	--exec wValidarePozIPC @sesiune, @parXML 

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	declare cursorpozIPC cursor for
	select isnull(datal, '01/31/1901') as datal, tip, subtip, --data, 
	isnull(an, 0) as an, isnull(luna, 0) as luna, isnull(indtotal, 0) as indtotal, 
	isnull(indmarfurialim, 0) as indmarfurialim, isnull(indmarfurinealim, 0) as indmarfurinealim, 
	isnull(indservicii, 0) as indservicii
	
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		datal datetime '../@datal',
		tip char(2) '../@tip', 
		subtip char(2) '@subtip', 
		an float '@an',
		luna float '@luna',
		indtotal float '@indtotal',
		indmarfurialim float '@indmarfurialim',
		indmarfurinealim float '@indmarfurinealim',
		indservicii float '@indservicii'
	)

	open cursorpozIPC
	fetch next from cursorpozIPC into @datal,@tip,@subtip,@an,@luna,
		@indtotal,@indmarfurialim,@indmarfurinealim,@indservicii
	set @fetchstatus=@@FETCH_STATUS
	while @fetchstatus = 0
	begin
		Delete from mf_ipc where data=@datal and an=@an and Luna=@luna
		INSERT into mf_ipc (Data,An,Luna,Indice_total,Indice_mf_alim,Indice_mf_nealim,Indice_servicii,
			Utilizator,Data_operarii,Ora_operarii,Alfa1,Alfa2,Val1,Val2)
			select @datal,@an,@luna,@indtotal,@indmarfurialim,@indmarfurinealim,@indservicii,
			@userASiS,	convert(datetime,convert(char(10),getdate(),104),104), 
			RTrim(replace(convert(char(8),getdate(),108),':','')), '','',0,0

		/*if @anGrp is null */ select @anGrp=@an, @lunaGrp=@luna, @dataGrp=@datal

		fetch next from cursorpozIPC into @datal,@tip,@subtip,@an,@luna,
			@indtotal,@indmarfurialim,@indmarfurinealim,@indservicii
		set @fetchstatus=@@FETCH_STATUS
	end
	set @docXMLIaPozIPC = '<row an="' + convert(char(4),@angrp) + '" luna="' + convert(char(2),@lunaGrp) + '" datal="' + convert(char(10), @dataGrp, 101) +'"/>'
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozIPCSP2')    
		exec wScriuPozIPCSP2 '', @anGrp, @lunaGrp, @dataGrp
	exec wIaPozIPC @sesiune=@sesiune, @parXML=@docXMLIaPozIPC 
end try

begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='cursorpozIPC' 
	and session_id=@@SPID )
if @cursorStatus=1 
	close cursorpozIPC 
if @cursorStatus is not null 
	deallocate cursorpozIPC 

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
