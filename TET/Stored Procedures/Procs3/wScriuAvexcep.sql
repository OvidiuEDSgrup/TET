--***
Create 
procedure wScriuAvexcep @sesiune varchar(50), @parXML xml 
as
declare @o_marca varchar(6), @marca varchar(6), @data datetime, @tip varchar(40), @lmantet varchar(9), 
@ore_lucrate_la_avans int, @suma_avans float, @premiu_la_avans float, @densalariat varchar(50), 
@denlmantet varchar(30), @denfunctie varchar(30), @salarincadrare float, @userASiS varchar(20), 
@docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254), @ptupdate int

begin try
	--BEGIN TRAN
	select @lmantet=xA.row.value('@lmantet', 'varchar(9)') from @parXML.nodes('row') as xA(row) 	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuAvexcepSP')
		exec wScriuAvexcepSP @sesiune, @parXML OUTPUT
	exec wValidareAvexcep @sesiune, @parXML
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crsavexcep cursor for
	select isnull(tip, '') as tip, isnull(o_marca, isnull(marca, '')) as o_marca, 
	(case when isnull(marca, '')='' then isnull(marca_poz, '') else isnull(marca, '') end) as marca, 
	isnull(data, '01/01/1901') as data, 
	isnull(ore_lucrate_la_avans, 0) as ore_lucrate_la_avans, 
	isnull(suma_avans, 0) as suma_avans, 
	isnull(premiu_la_avans, 0) as premiu_la_avans,
	isnull(densalariat,'') as densalariat, 
	isnull(denlmantet,'') as denlmantet,
	isnull(denfunctie,'') as denfunctie,
	isnull(salarincadrare,0) as salarincadrare, 
	isnull(ptupdate, 0) as ptupdate
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip char(40) '../@tip', 
		o_marca varchar(6) '@o_marca', 
		marca varchar(6) '../@marca', 
		marca_poz varchar(6) '@marca', 
		data datetime '../@data', 
		ore_lucrate_la_avans decimal(5) '@oreavans', 
		suma_avans float '@sumaavans', 
		premiu_la_avans float '@premiuavans',
		densalariat varchar(50) '../@densalariat', 
		denlmantet varchar(30) '../@denlmantet', 
		denfunctie varchar(30) '../@denfunctie', 
		salarincadrare float '../@salarincadrare', 
		ptupdate int '@update'
	)

	open crsavexcep
	fetch next from crsavexcep into @tip, @o_marca, @marca, @data, @ore_lucrate_la_avans, @suma_avans, 
	@premiu_la_avans, @densalariat, @denlmantet, @denfunctie, @salarincadrare, @ptupdate
	while @@fetch_status=0
	begin
		if @ptupdate=1 and @marca<>@o_marca
			delete from avexcep where Data=@Data and Marca=@o_marca
		
		exec scriuAvexcep @Data, @Marca, @Ore_lucrate_la_avans, @Suma_avans, @premiu_la_avans
	
		fetch next from crsavexcep into @tip, @o_marca, @marca, @data, @ore_lucrate_la_avans, @suma_avans, @premiu_la_avans,
		@densalariat, @denlmantet, @denfunctie, @salarincadrare, @ptupdate
	end
	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" marca="'+rtrim(@marca)+'" lmantet="' +rtrim(@lmantet)+'" data="'+convert(char(10),@data,101)+'" densalariat="'+ rtrim(@densalariat)+'" denlmantet="'+rtrim(@denlmantet)+'" denfunctie="'+rtrim(@denfunctie)+'" salarincadrare="'+ rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'"/>'
	exec wIaPozSalarii @sesiune=@sesiune, @parXML=@docXMLIaDLSalarii 
	--COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0)=0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
--
declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsavexcep' and session_id=@@SPID )
if @cursorStatus=1 
	close crsavexcep 
if @cursorStatus is not null 
	deallocate crsavexcep 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
