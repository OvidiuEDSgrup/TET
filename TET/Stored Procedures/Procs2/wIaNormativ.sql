--***
create procedure wIaNormativ @sesiune varchar(50),@parXML XML      
as      

if exists(select * from sysobjects where name='wIaNormativSP' and type='P')      
	exec wIaNormativSP @sesiune,@parXML      
else      

begin try
	declare	@codMasina varchar(20), @searchtext varchar(30), @tipMasina varchar(20), @grupa varchar(3), @eroare varchar(2000)

set @eroare=''

select 
	@codMasina=ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(20)'), ''),
    @searchtext = rtrim(isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(30)'), ''))

	if isnull(rtrim(@codMasina),'')='' 
			  raiserror ('Nu s-a reusit identificarea masinii!',16,1)

set @searchtext='%'+REPLACE(@searchtext,' ','%')+'%'

set @grupa=(select max(grupa) from masini m where m.cod_masina=@codMasina)
set @tipMasina=(select max(g.tip_masina) from grupemasini g where g.Grupa=@grupa)
	if isnull(rtrim(@tipMasina),'')='' 
			 raiserror ('Nu s-a reusit identificarea tipului masinii!',16,1)

insert into coefmasini (Masina, Coeficient, Valoare, Interval)
		select @codmasina, et.element, et.valoare, et.valoare
			   from elemtipm et
			   inner join elemente e on e.Cod=et.Element
		where tip_masina=@tipMasina
		and not exists( select 1 from coefmasini c where et.element=c.Coeficient and c.Masina=@codMasina)
		and e.Tip='I'

select top 100
rtrim(e.Cod) as cod,
rtrim(e.Denumire) as denumire,
rtrim(e.Tip) as tip,
rtrim(c.Valoare) as valoare,
(case	when e.UM2 = 'D' then 'Data'
		else 'Activitate' end) as tipInterval,
rtrim(c.interval) as interval,
  (case	when isnull(e.UM2,'')='D' then 'Luni'
		when tm.Tip_activitate='L' and isnull(e.UM2,'')<>'D' then 'Ore'
		when tm.Tip_activitate='P' and isnull(e.UM2,'')<>'D' then 'Km'
		else '?' end) um
FROM elemente e
	left outer join coefmasini c on e.Cod=c.Coeficient and c.Masina=@codMasina
	left join masini m on m.cod_masina=@codMasina
	left join grupemasini g on g.Grupa=m.grupa
	left join tipmasini tm on tm.Cod=g.tip_masina
where tip ='I' and c.Masina=@codMasina 
      and e.Denumire like '%'+@searchtext+'%'
    
order by e.cod
for xml raw
end try

begin catch
	set @eroare='wIaNormativ:'+char(10)+rtrim(ERROR_MESSAGE())
end catch

if len(@eroare)>0
	raiserror(@eroare,16,1)
