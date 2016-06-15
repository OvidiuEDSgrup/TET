/****** Object:  StoredProcedure [dbo].[wUAIaOperareIncTeren]    Script Date: 01/05/2011 23:48:11 ******/
--***
create procedure [dbo].[wUAIaOperareIncTeren] @sesiune varchar(30), @parXML XML
as

Declare @factura varchar(13),@data datetime,@tip varchar(2),@id int, @document varchar(10),@filtruCasier varchar(50),@filtruTip_inc varchar(50),
		@casier varchar(10),@tip_inc varchar(2),@utilizator char(10), @userASiS varchar(20),@datajos datetime,@datasus datetime
select
	@casier = isnull(@parXML.value('(/row/@casier)[1]','varchar(10)'),''),
	@tip_inc = isnull(@parXML.value('(/row/@tip_inc)[1]','varchar(2)'),''),
	@data = isnull(@parXML.value('(/row/@data)[1]','datetime'),'1901-01-01'),
	@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
	@datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
	@filtruCasier = isnull(@parXML.value('(/row/@filtruCasier)[1]','varchar(50)'),''),
	@filtruTip_inc = isnull(@parXML.value('(/row/@filtruTip_inc)[1]','varchar(50)'),''),
	@filtruCasier = '%'+replace(@filtruCasier,' ','%')+'%',
	@filtruTip_inc = '%'+replace(@filtruTip_inc,' ','%')+'%'
	
	

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------	
	
	select Top 100 convert(decimal(12,3),Sum(a.Suma)) as suma,convert(decimal(12,3),Sum(a.Penalizari)) as penalizari,            
	       convert(varchar, a.Data, 101)  as data,rtrim(a.Tip_incasare)as tip_inc,RTRIM(a.Casier)as casier,
	       RTRIM(max(c.casier))as denCasier,rtrim(max(t1.Denumire)) as denTip_inc,convert(int,MAX(a.document))+1 as doc_next,
	       rtrim(max(c.Nr_incasare)) as nr_incasare_c
	       
	from IncasariFactAbon a left outer join abonati a1 on a.Abonat=a1.abonat
	                        left outer join Tipuri_de_incasare t1 on a.tip_incasare=t1.ID	
	                        left outer join LMFiltrare lu on lu.utilizator=@utilizator and a1.loc_de_munca=lu.cod                        
	,Casieri c
	where (a.casier=@casier or @casier='')
		  and (a.data=@data or @data='1901-01-01')
		  and (a.Tip_incasare=@tip_inc or @tip_inc='') 
		  and (a.Casier like @filtruCasier+'%' or c.Casier like '%'+@filtruCasier+'%' or @filtruCasier='')
		  and (a.Tip_incasare like @filtruTip_inc+'%' or t1.Denumire like '%'+@filtruTip_inc+'%' or @filtruTip_inc='')
		  and c.Cod_casier=a.Casier
		  and a.Tip<>'CP'
		  and a.Teren=1 
		  and (@lista_lm=0 or lu.cod is not null)
		  and a.Data between @datajos and @datasus
group by a.Casier,a.Tip_incasare,a.Data
order by a.Data desc,a.Casier
for xml raw
--select * from incasarifactabon where casier ='casier' and tip_incasare=''
