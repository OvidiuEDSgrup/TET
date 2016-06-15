--***
/**	functie pt. evidentierea modificarii normei de lucru/fractiunii de norma a contractului de munca */
Create function fEvolutieNormaCM 
	(@dataJos datetime, @dataSus datetime, @pMarca char(6)) 
returns @NormaCM table
	(Data datetime, Marca char(6), Data_inceput datetime, Data_sfarsit datetime, Norma_zi int, Norma_saptamina int)
as
Begin
	declare @Data datetime, @Marca char(6), @Data_inceput datetime, @Data_sfarsit datetime, 
	@NormaZi int, @ZileCalend int, @Term char(8)
	Set @Term=isnull((select convert(char(8), abs(convert(int, host_id())))),'')
--	Set @Term='5492'
	if @dataJos is Null
		Select @dataJos=Data_facturii from avnefac where Terminal=@Term and tip='AD'
	if @dataSus is Null
		Select @dataSus=Data from avnefac where Terminal=@Term and tip='AD'
	if @pMarca is Null
		Select @pMarca=Numar from avnefac where Terminal=@Term and tip='AD'

	insert into @NormaCM
	select max(i.Data), i.Marca, (case when dbo.eom(max(p.Data_angajarii_in_unitate))=min(i.Data) then max(p.Data_angajarii_in_unitate) else min(i.Data) end), 
	(case when max(convert(int,p.Loc_ramas_vacant))=1 and dbo.eom(max(p.Data_plec))=max(i.Data) then max(p.Data_plec) else max(i.Data) end),
	(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end) as NormaZi, 
	(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end)*5 as NormaSaptamina
	from istPers i
		left outer join personal p on p.Marca=i.Marca
	where i.Data between (case when 1=0 then @dataJos when p.Data_angajarii_in_unitate<='01/01/2011' then '01/01/2011' else p.Data_angajarii_in_unitate end) and @dataSus 
		--and exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@pMarca)
		and i.Marca=@pMarca
	Group by i.Marca, (case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end)

	return
End

/*
	select * from fEvolutieNormaCM (Null, Null, Null) 
*/
