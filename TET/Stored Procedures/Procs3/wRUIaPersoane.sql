--***
/** procedura pentru citire date din RU_persoane **/
Create procedure wRUIaPersoane @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaPersoaneSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaPersoaneSP @sesiune, @parXML output
	return @returnValue
end

declare @filtruPersoana varchar(50), @filtruFunctie varchar(30), @filtruLm varchar(30), 
	@utilizator char(10), @mesaj varchar(200)
begin try
	select
		@filtruPersoana = isnull(@parXML.value('(/row/@f_persoana)[1]', 'varchar(50)'), ''),
		@filtruFunctie = isnull(@parXML.value('(/row/@f_functie)[1]', 'varchar(30)'), ''),
		@filtruLm = isnull(@parXML.value('(/row/@f_denlm)[1]', 'varchar(30)'), '')
	select @filtruPersoana = replace(@filtruPersoana,' ','%'), 
		@filtruFunctie = replace(@filtruFunctie,' ','%'),
		@filtruLm = replace(@filtruLm,' ','%')
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select	top 100 rtrim(a.ID_pers) as id_pers, rtrim(a.tip) as tip, 
		(case when a.tip='1' then 'Angajat' else 'CV' end) as dentip, 
		rtrim(a.nume) as nume, rtrim(a.marca) as marca,
		rtrim(a.id_profesie) as id_profesie, rtrim(b.denumire) as denprofesie, 
		rtrim(a.diploma) as diploma, rtrim(a.cod_functie) as codfunctie,
		rtrim(f.denumire) as denfunctie, rtrim(a.loc_de_munca) as loc_de_munca,
		convert(varchar,a.Data_inreg, 101) as data_inreg,
		rtrim(a.judet) as judet, rtrim(j.denumire) as denjudet, rtrim(a.localitate) as localitate,
		rtrim(l.oras) as denlocalitate, rtrim(a.strada) as strada,
		rtrim(a.numar) as numar, rtrim(a.cod_postal) as cod_postal, rtrim(a.bloc) as bloc, 
		rtrim(a.scara) as scara, rtrim(a.etaj) as etaj, rtrim(apartament) as apartament,
		rtrim(a.Sector) as sector,
	    rtrim(a.email) as email, rtrim(a.telefon_fix) as telefon_fix,
		rtrim(a.telefon_mobil) as telefon_mobil,
		rtrim(a.OpenID) as openid, rtrim(a.idmessenger) as idmessenger, 
		rtrim(a.idfacebook) as idfacebook, 
		rtrim(a.CNP) as cnp, rtrim(a.serie_bi) as serie_bi, rtrim(a.Numar_BI) as numar_bi,
		rtrim(lm.denumire) as denlm
	from RU_persoane a
		left outer join RU_profesii b on a.id_profesie=b.id_profesie 
		left outer join functii f on a.Cod_functie=f.Cod_functie 
		left outer join judete j on a.judet=j.cod_judet 
		left outer join localitati l on a.localitate=l.cod_oras 
		left outer join lm lm on a.loc_de_munca=lm.cod
	where a.Nume like '%' + @filtruPersoana + '%'
		and lm.Denumire like '%' + @filtruLm + '%'
		and f.Denumire like '%' + @filtruFunctie + '%'
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaPersoane) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)

