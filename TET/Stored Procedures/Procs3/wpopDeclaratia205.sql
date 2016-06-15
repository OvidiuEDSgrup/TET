create procedure wpopDeclaratia205 (@sesiune varchar(50), @parXML xml='<row/>')
as
begin
	set transaction isolation level read uncommitted
	declare @subunitate varchar(20), @data datetime, @utilizatorASiS varchar(50), 
		@contImpozitDeseuri char(30), 	--> Cont impozit la achizitii deseuri
		@contFacturaDeseuri char(30), 	--> Cont factura la achizitii deseuri
		@contImpozitDividende char(30),	--> Cont impozit dividende
		@numedecl varchar(75), @prendecl varchar(75), @functiedecl varchar(75)

	select @contImpozitDeseuri=max((case when parametru='D205CTIMP' then Val_alfanumerica else '' end))
		,@contFacturaDeseuri=max((case when parametru='D205CTFAC' then Val_alfanumerica else '' end))
		,@contImpozitDividende=max((case when parametru='D205CTDIV' then Val_alfanumerica else '' end))
		,@numedecl=max((case when parametru='NPERSAUT' then Val_alfanumerica else '' end))
		,@prendecl=max((case when parametru='PPERSAUT' then Val_alfanumerica else '' end))
		,@functiedecl=max((case when parametru='FPERSAUT' then Val_alfanumerica else '' end))
	from par where tip_parametru='PS' and parametru in ('D205CTIMP','D205CTFAC','D205CTDIV','NPERSAUT','PPERSAUT','FPERSAUT')

	select @data=isnull(@parXML.value('(/row/@datalunii)[1]','datetime'),isnull(@parXML.value('(/row/@data)[1]','datetime'),''))

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	select convert(char(10),@data,101) datalunii, year(@data) as an
		,convert(char(10),dbo.BOY(@data),101) datajos, convert(char(10),dbo.EOY(@data),101) datasus
		,(case when @contImpozitDeseuri<>'' then @contImpozitDeseuri end) contimpozit
		,(case when @contFacturaDeseuri<>'' then @contFacturaDeseuri end) contfactura
		,(case when @contImpozitDividende<>'' then @contImpozitDividende end) contimpozitdividende
		,rtrim(@numedecl) as numedecl
		,rtrim(@prendecl) as prendecl
		,rtrim(@functiedecl) as functiedecl
	for xml raw
end
