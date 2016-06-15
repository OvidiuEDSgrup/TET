--***
Create procedure wScriuPersintr @sesiune varchar(50), @parXML xml 
as
declare @subtip varchar(2), @luna int, @o_luna int, @an int, @o_an int, @o_marca varchar(6), @marca varchar(6), 
@o_data datetime, @data datetime, @tipintr char(1), 
@o_cnp varchar(13), @cnp varchar(13), @nume varchar(50), @gradinvalid char(1), @coefded int, @datanasterii datetime, 
@dataexpded datetime, @dataexpcoasig datetime, @venitlunar decimal(10), @deducere decimal(3,2),
@coasigurat char(1), @tipintr2 char(1), @valoare decimal(12,2), @observatii varchar(50),
@tip varchar(40), @tipAntet varchar(40), @userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254), @ptupdate int

select @subtip = isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), '') 

begin try
	--BEGIN TRAN
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPersintrSP')
		exec wScriuPersintrSP @sesiune, @parXML OUTPUT
	exec wValidarePersintr @sesiune, @parXML
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crspersintr cursor for
	select 	isnull(ptupdate, 0) as ptupdate, isnull(tip, '') as tip, isnull(tipAntet, '') as tipAntet, 
	isnull(luna,0) as luna, isnull(o_luna,1) as o_luna,
	isnull(an,0) as an, isnull(o_an,1901) as o_an,
	isnull(marcapozitii,isnull(marca, '')) as marca, 
	isnull(o_marca, isnull(marca, '')) as o_marca, 
	isnull(tipintr,'1') as tipintr,
	isnull(cnp, '') as cnp, isnull(o_cnp, '') as o_cnp, 
	isnull(nume, 0) as nume, 
	isnull(gradinvalid, '0') as gradinvalid,
	isnull(coefded,1) as coefded,
	isnull(datanasterii,'01/01/1901') as datanasterii,
	isnull(dataexpded,'01/01/1901') as dataexpded
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		ptupdate int '@update',
		tip char(40) '../@tip', 
		tipAntet char(40) '@tip', 
		luna int '@luna', 
		o_luna int '@o_luna', 
		an int '@an', 
		o_an int '@o_an', 
		marca varchar(6) '../@marca', 
		o_marca varchar(6) '@o_marca', 
		marcapozitii varchar(6) '@marca', 		
		tipintr char(1) '@tipintr',
		cnp varchar(13) '@cnp', 
		o_cnp varchar(13) '@o_cnp', 
		nume varchar(50) '@nume', 
		gradinvalid char(1) '@gradinvalid',
		coefded int '@coefded',
		datanasterii datetime '@datanasterii',
		dataexpded datetime '@dataexpded'
	)
	open crspersintr
	fetch next from crspersintr into @ptupdate, @tip, @tipAntet, @luna, @o_luna, @an, @o_an, @marca, @o_marca, 
	@tipintr, @cnp, @o_cnp, @nume, @gradinvalid, @coefded, @datanasterii, @dataexpded
	while @@fetch_status=0
	begin
		select @o_data='01/01/1901', @dataexpcoasig='01/01/1901', @venitlunar=0, @deducere=0, @coasigurat='', 
		@tipintr2='', @valoare=0, @observatii=''
		exec wValidareCNP @cnp, 0, '', @datanasterii output, ''
		set @data=dbo.Eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
		if @o_luna<>0 and @o_an<>0
			set @o_data=dbo.Eom(convert(datetime,str(@o_luna,2)+'/01/'+str(@o_an,4)))

		if @ptupdate=1 and (@cnp<>@o_cnp or @data<>@o_data)
			delete from persintr where Data=@o_data and Marca=@o_marca and Cod_personal=@o_cnp

		exec scriuPersintr @Data, @Marca, @tipintr, @cnp, @nume, @gradinvalid, @coefded, @datanasterii, 
		@dataexpded, @dataexpcoasig, @venitlunar, @deducere, @coasigurat, @tipintr2, @valoare, @observatii

		fetch next from crspersintr into @ptupdate, @tip, @tipAntet, @luna, @o_luna, @an, @o_an, @marca, @o_marca, 
		@tipintr, @cnp, @o_cnp, @nume, @gradinvalid, @coefded, @datanasterii, @dataexpded
	end

	--refresh pozitii in cazul in care tipul este 'PN'-> tab de tip pozdoc
	if @tipAntet in ('S') or @subtip='PN'
	begin
		declare @docXMLIaPersintr xml
		set @docXMLIaPersintr='<row marca="'+rtrim(@marca)+ '" tip="'+(case when @subtip='PN' then 'S' else @tipAntet end)+'"/>'
		exec wIaPersintr @sesiune=@sesiune, @parXML=@docXMLIaPersintr
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
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crspersintr' and session_id=@@SPID)
if @cursorStatus=1 
	close crspersintr
if @cursorStatus is not null 
	deallocate crspersintr

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
