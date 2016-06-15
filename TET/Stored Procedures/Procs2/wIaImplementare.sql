--***

create procedure wIaImplementare @sesiune varchar(50),@parXML XML      
as      

if exists(select * from sysobjects where name='wIaImplementareSP' and type='P')      
	exec wIaImplementareSP @sesiune,@parXML      
else      

begin try
	declare	@codMasina varchar(20), @searchtext varchar(30), @eroare varchar(2000)

	declare @element_km varchar(20), @element_ore varchar(20)
	--select @element_km='Kmef', @element_ore='OL'
	select @element_km='Kmbord', @element_ore='OREBORD'
set @eroare=''

select 
	@codMasina=ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(20)'), ''),
    @searchtext = rtrim(isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(30)'), ''))

	if isnull(rtrim(@codMasina),'')='' 
			  raiserror ('Nu s-a reusit identificarea masinii!',16,1)

set @searchtext='%'+REPLACE(@searchtext,' ','%')+'%'


select top 100
	rtrim(e.Tip) as tipFisa,
	RTRIM(e.Fisa) as fisa,
	convert(char(10),e.data,101) as data,
	e.Numar_pozitie as numar_pozitie,
	RTRIM(e.Element) as element,
	rtrim(e.Valoare) as valoare,
	rtrim(a.masina) as masina,
	RTRIM(a.Loc_de_munca) as loc_de_munca,
	rtrim(el.Denumire) as denumire,
	rtrim(eb.valoare) as bord
FROM elemactivitati e
	inner join activitati a on e.fisa=a.fisa and e.tip=a.tip and e.data=a.data
	inner join elemente el on e.element=el.cod
	--inner join activitati a on a.fisa=e.fisa and a.data=e.data and a.tip=e.tip
	inner join masini m on m.cod_masina=a.masina
	left join grupemasini g on m.grupa=g.Grupa
	left join tipmasini t on g.tip_masina=t.Cod
	left join elemactivitati eb on e.fisa=eb.fisa and e.data=eb.data and e.Tip=eb.Tip and e.Numar_pozitie=eb.Numar_pozitie
				and (t.tip_activitate='P' and eb.Element=@element_km or t.tip_activitate='L' and eb.Element=@element_ore)
where e.Fisa='I'+@codMasina and a.Masina=@codMasina and el.Denumire like '%'+@searchtext+'%'
	and e.element<>eb.element
    
order by e.numar_pozitie
for xml raw
end try

begin catch
	set @eroare='wIaImplementare:'+char(10)+rtrim(ERROR_MESSAGE())
end catch

if len(@eroare)>0
	raiserror(@eroare,16,1)
