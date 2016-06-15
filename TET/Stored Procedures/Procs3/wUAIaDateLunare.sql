--***
create PROCEDURE  [dbo].[wUAIaDateLunare] 
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER
AS  
set transaction isolation level READ UNCOMMITTED  
  
 Declare  @filtrucodabonat varchar(30),@filtrucontract varchar(30),@filtrudenabonat varchar(30) ,
          @datajos datetime,@datasus datetime ,@id_contract int,@utilizator char(10), @userASiS varchar(20)
select   
   @filtrucodabonat = isnull(@parXML.value('(/row/@filtrucodab)[1]','varchar(30)'),''),
   @filtrudenabonat = isnull(@parXML.value('(/row/@filtrudenab)[1]','varchar(30)'),''),
   @datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
   @datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
   @filtrucontract = isnull(@parXML.value('(/row/@filtrucontract)[1]','varchar(30)'),''),
   @id_contract = isnull(@parXML.value('(/row/@id_contract)[1]','int'),0)

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------

select top 100 c.Id_contract as id_contract,rtrim(a.abonat) as codabonat,rtrim(a.denumire) as denumireabonat,rtrim(c.zona) as zona,
		rtrim(a.centru) as centru,rtrim(a.judet) as judet,rtrim(l.oras) as oras,rtrim(z.Denumire_zona) as denzona,
		rtrim(s.Denumire_Strada)+' ,nr '+RTRIM(a.Numar)+' ,bl '+RTRIM(a.Bloc)+' ,sc '+RTRIM(a.Scara)+' ,ap '+RTRIM(a.Ap) as adresa,
		rtrim(c.contract) as contract,convert(char(10),c.data,101) as datacontract,rtrim(lm.Denumire) as denlm,rtrim(c.Loc_de_munca) as lm,
		rtrim(c.stare) as stare,(case when c.Stare='0' then 'operat' else (case when c.Stare='1' then 'definitiv' else 
		(case when c.Stare='2' then 'realizat' else (case when c.Stare='3' then 'reziliat' else 
		(case when c.Stare='4' then 'sistat' else '' end) end) end) end) end) as denstare,
		rtrim(t.Denumire) as dentip,RTRIM(c.tip) as tipcontr,c.Mod_facturare as modfact,
		(case when c.mod_Facturare=0 then 'Manual' else (case when c.mod_Facturare=1 then 'Lunar' else (case when c.mod_Facturare=2 then '2 luni' else 
		(case when c.mod_Facturare=3 then 'Trimestrial' else (case when c.mod_Facturare=4 then '4 luni' else (case when c.mod_Facturare=6 then 'Semestrial' else 
		(case when c.mod_Facturare=12 then 'anual' else '?' end) end) end) end) end) end) end) as denmodf,
		c.Luna_facturare as primaluna,c.Categorie_pret as categpret,c.Ziua_de_facturare as zifacturare,
		RTRIM(i.Descriere) as deninfo,RTRIM(c.info_contract) as info,c.Scadenta as scadenta,
		convert(char(10),c.Data_expirarii,101) as dataexpirarii,convert(char(10),c.Data_rezilierii,101) as datarezilierii,
		convert(decimal(12,0),c.categorie_penalizare) as categpen,rtrim(p.denumire) as dencategpret,@datajos as data_jos,@datasus as data_sus

from uacon c
	inner join (select distinct id_contract from UApozcon) u on u.Id_contract=c.id_contract
	left outer join lm on c.Loc_de_munca=lm.Cod
	left outer join TipContracte t on c.Tip=t.Tip
	left outer join InfoContracte i on c.info_contract=i.Cod
	left outer join UACatpret p on c.Categorie_pret=p.Categorie
	left outer join Zone z on z.zona=c.zona
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and c.loc_de_munca=lu.cod
,abonati a
	left outer join localitati l on a.Localitate=l.cod_oras
	left outer join Strazi s on a.Strada=s.Strada

where a.abonat=c.abonat
  and c.Stare in ('1','2','0')
  and (c.Id_contract=@id_contract or @id_contract=0)
  and (a.denumire like '%'+@filtrudenabonat+'%' or @filtrudenabonat='')
  and (a.abonat like '%'+@filtrucodabonat+'%' or @filtrucodabonat='')
  and (c.contract like '%'+@filtrucontract+'%' or @filtrucontract='')
  and (@lista_lm=0 or lu.cod is not null)
order by a.denumire
for xml raw
