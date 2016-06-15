--***
/****** Object:  StoredProcedure [dbo].[wRUIaAdresaPersoane]    Script Date: 01/05/2011 23:51:25 ******/
Create procedure wRUIaAdresaPersoane @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaAdresaPersoaneSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaAdresaPersoaneSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @userASiS varchar(20), @id_pers int,@mesaj varchar(200)
begin try
	select 
		@id_pers=ISNULL(@parXML.value('(/row/@id_pers)[1]','int'),0)
		
	select	top 100 rtrim(b.denumire) as denjudet, rtrim(c.oras) as denlocalitate, rtrim(a.strada) as strada,
		rtrim(a.numar) as numar, rtrim(a.cod_postal) as cod_postal, rtrim(a.bloc) as bloc, 
		rtrim(a.scara) as scara, rtrim(a.etaj) as etaj, rtrim(apartament) as apartament,
		Sector as sector 
	from RU_persoane a 
		left outer join judete b on a.judet=b.cod_judet 
		left outer join localitati c on a.localitate=c.cod_oras 
	where ID_pers=@id_pers
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaAdresaPersoane) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
