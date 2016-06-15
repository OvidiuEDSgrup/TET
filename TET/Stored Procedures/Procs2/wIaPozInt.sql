--***
create procedure [dbo].[wIaPozInt] @sesiune varchar(50), @parXML xml
as 
set transaction isolation level READ UNCOMMITTED
declare @eroare varchar(2000)
set @eroare=''
declare @userASiS varchar(10)

declare @data_lunii datetime, @tip varchar(2)
--Dorin
, @cautare varchar(500)
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	select	@data_lunii=@parXML.value('(row/@data)[1]','datetime'),
			@tip=@parXML.value('(row/@tip)[1]','varchar(2)'),
			--Dorin
			@cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(500)'), '')
	--
	select	
		rtrim(m.denumire) as etMasina, 
		rtrim(a.Masina) as masina, 
		'IU' as subtip,
		@data_lunii as data, 
		@tip as tip,
		isnull(pa.alfa2,'') as interventie,
		isnull(pa.Explicatii,'') as explicatii
		--"se va inlocui cu"		,a.idActivitati, pa.idPozActivitati
	from activitati a
	left join pozactivitati pa on a.tip=pa.Tip and a.Fisa=pa.Fisa and a.Data=pa.Data  
		--se va inlocui cu		a.idActivitati=pa.idActivitati
	left join masini m on a.Masina=m.cod_masina
	left outer join grupemasini g on g.grupa=m.grupa
	where a.tip='FI' and month(a.Data)=month(@data_lunii) and year(a.Data)=year(@data_lunii) and isnull(a.masina,'')<>''
	--Dorin
	and isnull(m.Denumire,'') like '%'+@cautare+'%'
	--group by a.masina,pa.Numar_pozitie,pa.Alfa2
	order by a.masina,pa.Numar_pozitie,pa.Alfa2 
	for xml raw
end try
begin catch
	set @eroare=ERROR_MESSAGE()
	if len(@eroare)>0
	set @eroare='wIaPozInt:'+
		char(10)+rtrim(@eroare)
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
