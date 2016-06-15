--***
create PROCEDURE [dbo].[wUAIaAbonati]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER
AS  
set transaction isolation level READ UNCOMMITTED  
  
 Declare  @filtrucodabonat varchar(30),@filtrucontract varchar(30),@filtrudenabonat varchar(30),
	@filtrugrupa varchar(30),@filtrucentru varchar(30),@filtruzona varchar(30),@filtrulocal varchar(30),
	@filtrustrada varchar(30),@utilizator char(10), @userASiS varchar(20),@filtruNr varchar(30)
	
select   
   @filtrucodabonat = isnull(@parXML.value('(/row/@filtrucodab)[1]','varchar(30)'),''),
   @filtrudenabonat = isnull(@parXML.value('(/row/@filtrudenab)[1]','varchar(30)'),''),
   @filtrucontract = isnull(@parXML.value('(/row/@filtrucontract)[1]','varchar(30)'),''),
   @filtrugrupa = isnull(@parXML.value('(/row/@filtrugrupa)[1]','varchar(30)'),''),
   @filtrucentru = isnull(@parXML.value('(/row/@filtrucentru)[1]','varchar(30)'),''),
   @filtruzona = isnull(@parXML.value('(/row/@filtruzona)[1]','varchar(30)'),''),
   @filtrulocal = isnull(@parXML.value('(/row/@filtrulocal)[1]','varchar(30)'),''),
   @filtrustrada = isnull(@parXML.value('(/row/@filtrustrada)[1]','varchar(30)'),''),
   @filtruNr = isnull(@parXML.value('(/row/@filtruNr)[1]','varchar(30)'),'')

---------
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------


select top 100 A.* ,Z.Denumire_zona,cc.denumire_centru,j.denumire as denumire_judet,l.oras as denumire_localitate,s.Denumire_Strada,lm.Denumire as denumire_lm,
		   g.Denumire as denumire_grupa,t.denumire as denumire_tert,b.denumire as denumire_banca
into #abonati 
from abonati a left outer join Strazi s on a.Strada=s.Strada
			   left outer join localitati l on a.Localitate=l.cod_oras
			   left outer join Zone z on a.zona=z.zona
			   left outer join Centre cc on a.Centru=cc.Centru
			   left outer join lm on a.Loc_de_munca=lm.Cod
			   left outer join Grabonat g on a.Grupa=g.Grupa
			   left outer join Judete j on a.Judet=j.cod_judet
			   left outer join bancibnr b on a.Banca=b.Cod
			   left outer join terti t on a.Tert_din_CG=t.Tert 
			   --------------------------
			   left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod

where (a.denumire like '%'+@filtrudenabonat+'%' or @filtrudenabonat='')
and (a.abonat like '%'+@filtrucodabonat+'%' or @filtrucodabonat='')
and (g.grupa like '%'+@filtrugrupa+'%' or @filtrugrupa='' or g.Denumire like '%'+@filtrugrupa+'%')
and (cc.Denumire_centru like '%'+@filtrucentru+'%' or @filtrucentru='' or cc.centru like '%'+@filtrucentru+'%')
and (z.Denumire_zona like '%'+@filtruzona+'%' or @filtruzona='' or z.zona like '%'+@filtruzona+'%')
and (l.oras like '%'+@filtrulocal+'%' or @filtrulocal='')
and (s.Denumire_Strada like '%'+@filtrustrada+'%' or @filtrustrada='')
and (a.Numar like '%'+@filtruNr+'%' or @filtruNr='')
-------
and (@lista_lm=0 or lu.cod is not null)
-------



select  (case when @filtrucodabonat<>'' then space(13-LEN(a.abonat))+a.abonat else '' end) as o,
rtrim(a.abonat) as codabonat,rtrim(a.denumire) as denumireabonat,--rtrim(a.inmatriculare) as inmatriculare,
rtrim(a.zona) as zona,rtrim(a.denumire_zona) as denzona,a.Platitor_tva as pltva,
rtrim(a.centru) as centru,RTRIM(a.denumire_centru) as dencentru,
rtrim(a.judet) as judet,RTRIM(a.denumire_judet) as denjudet,rtrim(a.Localitate) as localitate,rtrim(a.denumire_localitate) as denoras,
isnull(rtrim(a.Denumire_Strada),'')+' ,nr '+RTRIM(a.Numar)+' ,bl '+RTRIM(a.Bloc)+' ,sc '+RTRIM(a.Scara)+' ,ap '+RTRIM(a.Ap) as adresa,
rtrim(a.strada) as strada,rtrim(a.denumire_Strada) as denstrada,
rtrim(a.Denumire_lm) as denlm,rtrim(a.Loc_de_munca) as lm,rtrim(a.grupa) as grupa,RTRIM(a.Denumire_grupa) as dengrupa,
RTRIM(a.Numar) as nr,RTRIM(a.Bloc) as bl,RTRIM(a.Scara) as sc,RTRIM(a.Ap) as ap,RTRIM(a.Etaj) as et,
rtrim(a.inmatriculare) as inmatriculare,rtrim(a.tert_din_cg) as tert,rtrim(a.denumire_tert) as dentert,
rtrim(a.cod_fiscal) as cod_fiscal,rtrim(a.telefon) as telefon,rtrim(a.banca) as codbanca,rtrim(a.denumire_banca) as denbanca,
rtrim(a.Cont_in_Banca) as contbanca,convert(int,a.categorie) as categorie,rtrim(a.cod_postal) as codpostal,
(case when a.categorie=1 then 'agenti juridici' else (case when a.categorie=2 then 'institurii publice' else (case when a.categorie=3 then 'populatie' else 
 (case when a.categorie=4 then 'provizioane' else (case when a.categorie=5 then 'asociatii' else 'alte' end) end) end) end) end) as dencategorie,
 rtrim(ltrim(a.observatii)) as observatii,
convert(Decimal(12,2),isnull((select SUM(sold) from factabon ff where ff.abonat=a.abonat),0)) as soldtotal

from #abonati a 
order by o, patindex('%'+@filtrudenabonat+'%', a.denumire), a.denumire
for xml raw
