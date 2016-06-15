--***
Create 
procedure wIaZilieri @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wIaZilieriSP' and type='P')
	exec wIaZilieriSP @sesiune, @parXML 
else 
begin
	set transaction isolation level READ UNCOMMITTED
	declare @userASiS varchar(20), @filtruZilier varchar(50), @filtruNume varchar(50), @filtruMarca varchar(6), @filtruFunctie varchar(20), @filtruLm varchar(20),
	@filtruCNP varchar(13), @filtruCuPlecati varchar(2), @codMeniu char(2)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	set @filtruZilier=isnull(@parXML.value('(/row/@f_salariat)[1]','varchar(50)'),'')
	set @filtruMarca=isnull(@parXML.value('(/row/@f_marca)[1]','varchar(6)'),'')
	set @filtruNume=isnull(@parXML.value('(/row/@f_nume)[1]','varchar(50)'),'')
	set @filtruFunctie=isnull(@parXML.value('(/row/@f_functie)[1]','varchar(50)'),'')
	set @filtruLm=isnull(@parXML.value('(/row/@f_lm)[1]','varchar(50)'),'')
	set @filtruCNP=isnull(@parXML.value('(/row/@f_cnp)[1]','varchar(13)'),'')
	set @filtruCuPlecati=isnull(@parXML.value('(/row/@f_cuplecati)[1]','varchar(2)'),'')
	set @filtruNume=Replace(@filtruNume,' ','%')
	set @codMeniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(2)'),'')

	select top 100 
		rtrim(z.Marca) as marca,rtrim(z.Nume) as nume,rtrim(z.Cod_functie) as codfct,
		rtrim(z.Loc_de_munca) as lm,rtrim(lm.Denumire) as denlm,convert(decimal(10),z.Salar_de_incadrare) as salinc,convert(decimal(10),z.Salar_orar) as salor,
		rtrim(z.Tip_salar_orar) as tipsal,rtrim(f.denumire) as denfct, rtrim(z.Comanda)as comanda,
		convert(varchar(10),z.Data_angajarii,101) as dataangajarii, z.Plecat as plecat, convert(varchar(10),z.Data_plecarii,101) as dataplecarii, RTRIM(z.Banca) as banca,
		RTRIM(z.Cont_in_banca)as contbanca, rtrim(z.Cod_numeric_personal) as cnp, convert(varchar(10),z.Data_nasterii,101) as datanasterii,
		z.Sex as sex, RTRIM(z.Buletin) as buletin, convert(varchar(10),z.Data_eliberarii,101) as dataeliberarii, RTRIM(z.Localitate) as localitate,
		RTRIM(z.Judet) as judet, RTRIM(z.Strada) as strada, RTRIM(z.Numar) as numar, z.Cod_postal as codpostal,
		RTRIM(z.Bloc) as bloc, RTRIM(z.Scara) as scara, RTRIM(z.Etaj) as etaj, RTRIM(z.Apartament) as apartament, z.Sector as sector, rtrim(cm.descriere) as dencomanda
		from Zilieri z
			left join functii f on z.Cod_functie=f.Cod_functie
			left join lm on z.Loc_de_munca=lm.cod
			left join comenzi cm on cm.Comanda= z.comanda
			left outer join LMFiltrare lu on lu.utilizator=@userASiS and z.Loc_de_munca=lu.cod
		where (z.marca like @filtruMarca+'%') and (z.nume like '%'+@filtruNume+'%')
			and (z.Cod_functie like @filtruFunctie+'%' or f.Denumire like '%'+@filtruFunctie+'%') 
			and (z.Loc_de_munca like @filtruLm+'%' or lm.Denumire like '%'+@filtruLm+'%')
			and (z.Cod_numeric_personal like '%'+@filtruCNP+'%')
			and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
		order by z.marca, z.cod_functie
		for xml raw
End
