--***
create procedure [dbo].[wIaFunctiiLM] @sesiune varchar(50), @parXML xml
as  
Begin
	declare @lm varchar(9), @cautare varchar(100)

	Set @lm = @parXML.value('(/row/@lm)[1]','varchar(9)')
	set @cautare=@parXML.value('(/row/@_cautare)[1]','varchar(100)')
	set @cautare='%'+isnull(@cautare,'')+'%'

	if object_id('tempdb..#ordine') is not null drop table #ordine
--	selectez din functii_lm ultimele pozitii pentru fiecare loc de munca/functie
	select Data, Loc_de_munca, Cod_functie, RANK() over (partition by Loc_de_munca, Cod_functie order by Data Desc) as ordine
	into #ordine
	from functii_lm
	where Loc_de_munca=@lm

	select 
		rtrim(a.Loc_de_munca) as lm, rtrim(lm.Denumire) as denlm, convert(char(10),a.Data,101) as data, 
		rtrim(a.Cod_functie) as functie, rtrim(isnull(f.Denumire, '')) as denfunctie, rtrim(a.Denumire) as denpost, 
		rtrim(a.Tip_personal) as tippersonal, (case when a.Tip_personal='T' then 'TESA' when a.Tip_personal='M' then 'Muncitori' else '' end) as dentippersonal,
		convert(decimal(10),a.Salar_de_incadrare) as salarincadrare, 
		convert(decimal(7),Numar_posturi) as nrposturi, convert(decimal(5,2),a.Regim_de_lucru) as regimlucru, 
		convert(int,Pozitie_stat) as pozitiestat, (case when o.Ordine<>1 then '#808080' else '#000000' end) as culoare
	from functii_lm a
		left outer join lm lm on lm.cod=a.Loc_de_munca
		left outer join functii f on f.Cod_functie=a.Cod_functie
		left outer join #ordine o on o.Data=a.Data and o.Cod_functie=a.Cod_functie
	where a.Loc_de_munca=@lm and (@cautare='' or rtrim(a.Cod_functie) like @cautare or rtrim(f.Denumire) like @cautare)
		order by Pozitie_stat, a.Cod_functie, a.Data desc
	for xml raw

	if object_id('tempdb..#ordine') is not null drop table #ordine
End
