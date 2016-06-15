/****** Object:  StoredProcedure [dbo].[wUAIaIncasariAbonati]    Script Date: 01/05/2011 23:48:11 ******/
--***
create procedure  [dbo].[wUAIaIncasariAbonati]  @sesiune varchar(30), @parXML XML
as

Declare @factura varchar(13),@data datetime,@tip varchar(2),@id int, @document varchar(10),@filtruAbonat varchar(50),
		@filtruDoc varchar(10),@datajos datetime,@datasus datetime,@utilizator char(10), @userASiS varchar(20)
select
	@document = isnull(@parXML.value('(/row/@document)[1]','varchar(10)'),''),
	@filtruAbonat = isnull(@parXML.value('(/row/@filtruAbonat)[1]','varchar(50)'),''),
	@filtruDoc = isnull(@parXML.value('(/row/@filtruDoc)[1]','varchar(10)'),''),
	@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
    @datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
	@filtruAbonat = '%'+replace(@filtruAbonat,' ','%')+'%',
	@filtruDoc = '%'+replace(@filtruDoc,' ','%')+'%'
	
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------	
	
select top 100 rtrim(max(a.abonat))as abonat, convert(decimal(12,3),Sum(a.Suma)) as suma,convert(decimal(12,3),Sum(a.Penalizari)) as penalizari,            
       convert(varchar, max(a.Data), 101)  as data,rtrim(Document) as document,rtrim(max(a.Tip_incasare))as tip_inc,RTRIM(max(a.loc_de_munca)) as loc_de_munca,
       RTRIM(max(a.Casier))as casier,RTRIM(max(a.Utilizator)) as utilizator,rtrim(max(a1.denumire)) as denAbonat,rtrim(max(t.Denumire)) as denTip_incasare,
       RTRIM(LTRIM(max(a.Tip))) as tip
from IncasariFactAbon a left outer join abonati a1 on a.Abonat=a1.abonat
	                    left outer join Tipuri_de_incasare t on a.Tip_incasare=t.ID
	                    left outer join FactAbon f on a.id_factura=f.id_factura
	                    left outer join LMFiltrare lu on lu.utilizator=@utilizator and f.loc_de_munca=lu.cod
where (a.Document=@document or @document='')
  and (a.Data between @datajos and @datasus)
  and (a.abonat like @filtruAbonat+'%' or a1.denumire like '%'+@filtruAbonat+'%' or @filtruAbonat='')
  and (a.Document like @filtruDoc+'%' or @filtruDoc='')
  --and a.Tip <>'CP'
  and (@lista_lm=0 or lu.cod is not null)
group by a.Document,a.Abonat 
order by max(a.Data) desc,a.Document desc
for xml raw

--select * from incasarifactabon
--select * from AntetFactAbon
--select * from abonati
