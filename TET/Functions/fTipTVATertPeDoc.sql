--***
create function fTipTVATertPeDoc (@parXML xml)
returns char(1)
as
begin
	declare @TipPlataTVA char(1), @tert varchar(13), @factura varchar(20), @tip char(3), @tipf char(1), @DataFact datetime
	select	@tert=isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'),''),
			@factura=isnull(@parXML.value('(/row/@factura)[1]', 'varchar(20)'),''),
			@tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(3)'),'')	,
			@DataFact=isnull(@parXML.value('(/row/@datafact)[1]', 'datetime'),'')

--	stabilire tip factura: F=Furnizori, B=Beneficiari
	if @tip=''  or @tip in ('FF','RM','RS','SF','AF')
		set @tipf='F'	
	else 
		set @tipf='B'

	select top 1 @TipPlataTVA=tip_tva from TvaPeTerti --Verific daca este cu Tva La Incasare factura
		where tert=@Tert and tipf=@tipf and factura=@factura
	order by dela desc

	select top 1 @TipPlataTVA=tip_tva	--Verific daca firma este cu Tva La Incasare
	from TvaPeTerti 
		where tipf='B' and tert is null and tip_tva='I' and dela<=@DataFact
	order by dela desc

--	Daca nu e (null sau P) cu TVA la incasare se va studia furnizorul; @tert<>'' inseamna ca se apeleaza functia din intrari
--	Se verifica furnizorul doar pt. facturile de la furnizori
	if isnull(@TipPlataTVA,'P')='P' and @tert<>'' and @tipf='F' 
		select top 1 @TipPlataTVA=tip_tva from TvaPeTerti 
			where tert=@Tert and tipf='F' and dela<=@DataFact and factura is null
				order by dela desc

	if @TipPlataTVA is null
		set @TipPlataTVA='P'

	return @TipPlataTVA
end