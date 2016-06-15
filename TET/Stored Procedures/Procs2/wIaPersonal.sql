--***
Create procedure wIaPersonal @sesiune varchar(50), @parXML xml
as
declare @sub varchar(9), @tip varchar(2), @userASiS varchar(10), @filtruSalariat varchar(50), @filtruNume varchar(50), @filtruMarca varchar(6), @filtruFunctie varchar(20), @filtruLm varchar(20),
@filtruCNP varchar(13), @filtruCuPlecati varchar(20), @filtruNrContract varchar(20), @codMeniu char(2), @dataCrt datetime

set @sub=dbo.iauParA('GE','SUBPRO')

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),'')
set @filtruSalariat=isnull(@parXML.value('(/row/@f_salariat)[1]','varchar(50)'),'')
set @filtruMarca=isnull(@parXML.value('(/row/@f_marca)[1]','varchar(6)'),'')
set @filtruNume=isnull(@parXML.value('(/row/@f_nume)[1]','varchar(50)'),'')
set @filtruFunctie=isnull(@parXML.value('(/row/@f_functie)[1]','varchar(50)'),'')
set @filtruLm=isnull(@parXML.value('(/row/@f_lm)[1]','varchar(50)'),'')
set @filtruCNP=isnull(@parXML.value('(/row/@f_cnp)[1]','varchar(13)'),'')
set @filtruCuPlecati=isnull(@parXML.value('(/row/@f_cuplecati)[1]','varchar(20)'),'')
set @filtruNume=Replace(@filtruNume,' ','%')
set @codMeniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(2)'),'')
set @dataCrt=convert(datetime,convert(char(10),GETDATE(),101),101)

select top 100 
	rtrim(p.marca) as marca,rtrim(p.nume) as nume,rtrim(p.nume) as densalariat,
	rtrim(p.cod_functie) as functie,rtrim(f.denumire) as denfunctie,
	rtrim(p.loc_de_munca) as lm,rtrim(lm.denumire) as denlm,
	rtrim(p.banca) as banca,rtrim(p.cont_in_banca) as contbanca,rtrim(p.mod_angajare) as modangaj,
	convert(varchar(10),p.Data_angajarii_in_unitate,101) as dataangajarii,
	convert(char(1),p.loc_ramas_vacant) as plecat,convert(varchar(10),data_plec,101) as dataplec,
	rtrim(p.Cod_numeric_personal) as cnp,rtrim(p.copii) as buletin,
	rtrim(localitate) as localitate,
	rtrim((case when charindex(',',p.Judet)=0 then p.Judet else left(p.Judet,charindex(',',p.Judet)-1) end)) as judet,
	rtrim((case when charindex(',',p.Judet)=0 then p.Judet else left(p.Judet,charindex(',',p.Judet)-1) end)) as denjudet,
	rtrim(strada) as strada,rtrim(numar) as numar,rtrim(bloc) as bloc,
	rtrim(scara) as scara,rtrim(etaj) as etaj,rtrim(apartament) as apart,rtrim(convert(decimal(10),cod_postal)) as codpostal,
	(case when isnull(p.fictiv,0)=0 then 0 else 1 end) as fictiv, (case when isnull(p.fictiv,0)=0 then 'Nu' else 'Da' end) as denfictiv, 
	(case when loc_ramas_vacant=1 then '#808080' when isnull(p.fictiv,0)=1 then '#FF8040' else '#000000' end) as culoare,
	ISNULL(RTRIM(i.Observatii),'') observatii,
	p.detalii detalii
from personal p
	left join functii f on p.cod_functie=f.cod_functie
	left join lm on p.loc_de_munca=lm.cod
	left join infopers i on i.marca=p.marca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
where (@filtruMarca='' or p.marca like @filtruMarca+'%')
	and (@filtruNume='' or p.nume like '%'+@filtruNume+'%')
	and (@filtruSalariat='' or p.marca like @filtruSalariat+'%' or p.nume like '%'+@filtruSalariat+'%')
	and (@filtruFunctie='' or p.Cod_functie like @filtruFunctie+'%' or f.Denumire like '%'+@filtruFunctie+'%') 
	and (@filtruLm='' or p.Loc_de_munca like @filtruLm+'%')-- or lm.Denumire like '%'+@filtruLm+'%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	and (@filtruCNP='' or p.Cod_numeric_personal like '%'+@filtruCNP+'%')
	and (p.loc_ramas_vacant=0 and upper(@filtruCuPlecati)<>'DOAR'	--	doar activi
		or upper(@filtruCuPlecati)='DA' and p.loc_ramas_vacant=1	--	si salariatii plecati
		or upper(@filtruCuPlecati)='DOAR' and p.loc_ramas_vacant=1	--	doar salariatii plecati
		or fictiv=1)	--	si salariatii fictivi
order by p.marca,p.cod_functie
for xml raw,root ('Date')

select '1' as areDetaliiXml
for xml raw, root('Mesaje')
