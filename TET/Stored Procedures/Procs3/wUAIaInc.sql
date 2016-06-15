--***
create procedure  [dbo].[wUAIaInc]  @sesiune varchar(50), @parXML XML    
as   
begin 
set transaction isolation level READ UNCOMMITTED

 Declare  @abonat varchar(13),@denumire varchar(50),@adresa varchar(200),@zona varchar(8),@centru varchar(8),@sold float,@de_incasat float,
          @filtruAbonat varchar(50),@filtruLocalitate varchar(50),@filtruStrada varchar(50),@filtruNumar varchar(10),
          @filtruBloc varchar(10),@doc varchar(8),@utilizator char(10), @userASiS varchar(20)
 --citire date din xml
 select 
   @abonat = isnull(@parXML.value('(/row/@abonat)[1]','varchar(13)'),''),
   @filtruAbonat = isnull(@parXML.value('(/row/@filtruAbonat)[1]','varchar(50)'),''),
   @filtruLocalitate = isnull(@parXML.value('(/row/@filtruLocalitate)[1]','varchar(50)'),''),
   @filtruStrada = isnull(@parXML.value('(/row/@filtruStrada)[1]','varchar(50)'),''),
   @filtruNumar = isnull(@parXML.value('(/row/@filtruNumar)[1]','varchar(10)'),''),
   @filtruBloc = isnull(@parXML.value('(/row/@filtruBloc)[1]','varchar(10)'),''), 
   @filtruAbonat = '%'+replace(@filtruAbonat,' ','%')+'%',
   @filtruStrada = '%'+replace(@filtruStrada,' ','%')+'%',
   @filtruLocalitate = '%'+replace(@filtruLocalitate,' ','%')+'%',
   @filtruNumar = '%'+replace(@filtruNumar,' ','%')+'%',
   @filtruBloc = '%'+replace(@filtruBloc,' ','%')+'%'
   

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)
---------

select Top 100 a.*, l.oras as denLocalitate,s.Denumire_Strada as denStrada, z.Denumire_zona as denZona,c.Denumire_centru as denCentru
into #abonati
from abonati a
     left outer join Localitati l on l.cod_oras=a.Localitate
     left outer join Strazi s on s.Strada=a.Strada
     left outer join Zone z on z.Zona=a.Zona
     left outer join Centre c on c.Centru=a.Centru
     left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod
where (a.abonat=@abonat or @abonat='')
  and (a.abonat like @filtruAbonat+'%' or a.denumire like '%'+@filtruAbonat+'%' or @filtruAbonat='')
  and (l.oras like '%'+@filtruLocalitate+'%' or a.Localitate like @filtruLocalitate+'%' or  @filtruLocalitate='')
  and (s.Denumire_Strada like '%'+@filtruStrada+'%' or a.Strada like @filtruStrada+'%' or  @filtruStrada='')
  and (a.Numar like '%'+@filtruNumar+'%' or @filtruNumar='')
  and (a.Bloc like '%'+@filtruBloc+'%' or @filtruBloc='')
  and (@lista_lm=0 or lu.cod is not null)
order by abonat


select rtrim(a.abonat)as abonat,ltrim(rtrim(a.denumire))as denumire,
       rtrim(ltrim(a.denLocalitate))+(case when a.Strada<>'' then ', str. '+rtrim(ltrim(a.denStrada)) else ''end)+
        (case when a.numar<>'' then ', nr. '+rtrim(a.numar) else ''end)+ (case when a.bloc<>'' then ', bl. '+rtrim(a.bloc) else ''end) as adresa,
        ltrim(rtrim(a.centru)) as centru,ltrim(rtrim(a.zona)) as zona, ltrim(rtrim(a.denCentru))as dencentru,
        ltrim(rtrim(a.denZona))as denzona,
        (isnull(convert(decimal(12,3),(select SUM(sold) from FactAbon where abonat=a.abonat)),0)) as sold, 
        (isnull(convert(decimal(12,3),(select SUM(sold_penalizari) from FactAbon where abonat=a.abonat)),0)) as penalizari,
        (isnull(convert(decimal(12,3),(select SUM(sold) from FactAbon where abonat=a.abonat)),0)) as de_incasat

from #abonati a     
order by a.denumire
for xml raw  
end
--select * from factabon
--select * from antetfactabon
--select * from pozitiifactabon
