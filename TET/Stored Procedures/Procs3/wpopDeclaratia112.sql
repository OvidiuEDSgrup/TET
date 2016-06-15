create procedure wpopDeclaratia112 (@sesiune varchar(50), @parXML xml='<row/>')
as
begin
	set transaction isolation level read uncommitted
	declare @subunitate varchar(20), @data datetime, @utilizatorASiS varchar(50), 
		@ImpozitPlD112 int, @ImpPLFaraSal int, @LmImpStatPl int, 
		@ContCASSAgricol varchar(13),	--> Cont asigurari de sanatate retinute la achizitia de cereale 
		@ContImpozitAgricol varchar(13),	--> Cont impozit retinut la achizitia de cereale 
		@numedecl varchar(75), @prendecl varchar(75), @functiedecl varchar(75)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

	select @ImpozitPlD112=max((case when parametru='D112IMZPL' then Val_logica else 0 end))
		,@ImpPLFaraSal=max((case when parametru='D112IPLFS' then Val_logica else 0 end))
		,@LmImpStatPl=max((case when parametru='D112PLLMS' then Val_logica else 0 end))
		,@ContCASSAgricol=max((case when parametru='D112CASAA' then Val_alfanumerica else '' end))
		,@ContImpozitAgricol=max((case when parametru='D112CIMAA' then Val_alfanumerica else '' end))
		,@numedecl=max((case when parametru='NPERSAUT' then Val_alfanumerica else '' end))
		,@prendecl=max((case when parametru='PPERSAUT' then Val_alfanumerica else '' end))
		,@functiedecl=max((case when parametru='FPERSAUT' then Val_alfanumerica else '' end))
	from par where tip_parametru='PS' and parametru in ('D112IMZPL','D112IPLFS','D112PLLMS','D112CASAA','D112CIMAA','NPERSAUT','PPERSAUT','FPERSAUT')
	
	select @data=isnull(@parXML.value('(/row/@datalunii)[1]','datetime'),isnull(@parXML.value('(/row/@data)[1]','datetime'),''))

	select convert(char(10),@data,101) datalunii
		,(case when @ImpozitPlD112=1 then 1 end) as impozitpl
		,(case when @ImpPLFaraSal=1 then 1 end) as impplfarasal
		,(case when @LmImpStatPl=1 then 1 end) as lmimpstatpl
		,rtrim(@ContCASSAgricol) as contcass
		,rtrim(@ContImpozitAgricol) as contimpozit
		,rtrim(@numedecl) as numedecl
		,rtrim(@prendecl) as prendecl
		,rtrim(@functiedecl) as functiedecl
	for xml raw
end
