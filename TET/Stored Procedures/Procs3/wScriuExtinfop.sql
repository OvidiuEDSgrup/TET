--***
Create procedure wScriuExtinfop @sesiune varchar(50), @parXML xml 
as
declare @tip varchar(2), @tipAntet varchar(2), @subtip varchar(2), @marca varchar(6), @data datetime, @data_veche datetime, @tipinfo varchar(1), @tipinfo_vechi varchar(1), @cod varchar(20), @cod_vechi varchar(20), 
@valoare varchar(80), @valoare_veche varchar(80), @procent decimal(7,2), @procent_vechi decimal(7,2), 
@userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254), @ptupdate int, @LocIntrodCodInf int

begin try
	--BEGIN TRAN
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuExtinfopSP')
		exec wScriuExtinfopSP @sesiune, @parXML OUTPUT
	exec wValidareExtinfop @sesiune, @parXML
	if isnull(@sesiune,'')!=''
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crsExtinfop cursor for
	select 	isnull(ptupdate, 0) as ptupdate, isnull(tip, '') as tip, isnull(tipAntet, '') as tipAntet, isnull(subtip, '') as subtip, isnull(marcapozitii,isnull(marca, '')) as marca, 
	isnull(tipinfo,'') as tipinfo, isnull(o_tipinfo,'') as tipinfo_vechi, isnull(cod, '') as cod, isnull(o_cod, '') as cod_vechi, isnull(valoare, '') as valoare, isnull(o_valoare, '') as valoare_veche, 
	isnull(data, '01/01/1901') as data, isnull(o_data, '01/01/1901') as data_veche, isnull(procent, 0) as procent, isnull(o_procent, 0) as procent_vechi
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		ptupdate int '@update',
		tip char(40) '../@tip',
		tipAntet char(40) '@tip',
		subtip char(40) '@subtip',
		marca varchar(6) '../@marca',
		marcapozitii varchar(6) '@marca',
		tipinfo varchar(1) '@tipinfo',
		o_tipinfo varchar(1) '@o_tipinfo',
		cod varchar(20) '@cod',
		o_cod varchar(20) '@o_cod',
		valoare varchar(80) '@valoare',
		o_valoare varchar(20) '@o_valoare',
		data datetime '@data',
		o_data datetime '@o_data',
		procent decimal(7,2) '@procent',
		o_procent decimal(7,2) '@o_procent'
	)
	open crsExtinfop
	fetch next from crsExtinfop into @ptupdate, @tip, @tipAntet, @subtip, @marca, @tipinfo, @tipinfo_vechi, @cod, @cod_vechi, @valoare, @valoare_veche, 
	@data, @data_veche, @procent, @procent_vechi
	while @@fetch_status=0
	begin
		set @data=(case when @data='01/01/1900' or @tipinfo='1' then '01/01/1901' else @data end)
		if @ptupdate=1 and (@cod<>@cod_vechi or @valoare<>@valoare_veche or @data<>@data_veche)
			delete from extinfop where Marca=@marca and Cod_inf=@cod_vechi and Val_inf=@valoare_veche and Data_inf=@data_veche

		select @LocIntrodCodInf=pondere from Catinfop where Cod=@cod
		set @LocIntrodCodInf=(case when @LocIntrodCodInf=0 and @tipinfo='1' then 1 else @LocIntrodCodInf end)
--	@LocIntrodCodInf=1 inseamna tabul Informatii, fara completarea campului Data_inf (01/01/1901). 
--	Am tratat sa fie @LocIntrodCodInf=1 si daca @tipinfo='1'. @tiponfo provine din noua macheta Alte informatii, unde am cumulat cele 2 machete de Date personal si Informatii personal.
--	@LocIntrodCodInf=0 inseamna Date salariati cu completarea campului Data_inf
		set @LocIntrodCodInf=isnull(@LocIntrodCodInf,0)
		if @cod='PENSIIF'
			set @data=dbo.BOY(@data)
		if not exists (select Marca from extinfop where Marca=@marca and Cod_inf=@cod and (@LocIntrodCodInf=1 or @data='01/01/1901' or Val_inf=@valoare) and Data_inf=@data)
			insert into extinfop (Marca, Cod_inf, Val_inf, Data_inf, Procent)
			select @marca, @cod, @valoare, @data, @procent
		else
			update extinfop set Procent=@Procent, Val_inf=(case when @LocIntrodCodInf=1 or @data='01/01/1901' then @valoare else Val_inf end)
				where Marca=@marca and Cod_inf=@cod and (@LocIntrodCodInf=1 or @data='01/01/1901' or Val_inf=@valoare) and Data_inf=@data

		fetch next from crsExtinfop into @ptupdate, @tip, @tipAntet, @subtip, @marca, @tipinfo, @tipinfo_vechi, @cod, @cod_vechi, @valoare, @valoare_veche, 
			@data, @data_veche, @procent, @procent_vechi
	end
	--COMMIT TRAN

	--refresh pozitii in cazul in care meniu este 'S'-> tab de tip pozdoc
	if @tipAntet in ('','S')
	begin
		declare @docXMLExtinfop xml
		set @docXMLExtinfop='<row marca="'+rtrim(@marca)+ '" tip="'+@tipAntet + '" tiptab="'+@subtip +'"/>'
		exec wIaExtinfop @sesiune=@sesiune, @parXML=@docXMLExtinfop
	end

end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0)=0
		set @mesaj='(wScriuExtinfop) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
--
declare @cursorStatus int
set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crsExtinfop' and session_id=@@SPID)
if @cursorStatus=1 
	close crsExtinfop
if @cursorStatus is not null 
	deallocate crsExtinfop

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
