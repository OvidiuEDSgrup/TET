--***
CREATE procedure  [dbo].[wIaRaport]  @sesiune varchar(50), @parXML xml
as
declare @angajat varchar(30), @dataj datetime, @datas datetime, @codsesizare varchar(10),
		@ore_realizate varchar(8)


select 
	@dataj = rtrim(isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '')),
	@datas = rtrim(isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '')),
	@angajat = rtrim(isnull(@parXML.value('(/row/@f_angajat)[1]', 'varchar(30)'), ''))

	
set @angajat= '%'+REPLACE(@angajat,' ','%')+'%'

select top 100
i.Descriere as angajat,( case when CONVERT(VARCHAR(10),MONTH(data_start)) = '1' then 'Ianuarie'  +' ' +convert (varchar(4),YEAR(Data_start)) when CONVERT(VARCHAR(10),MONTH(data_start)) = '2' then 'Februarie' +' ' +convert (varchar(4),YEAR(Data_start))
						when CONVERT(VARCHAR(10),MONTH(data_start)) = '3' then 'Martie' +' ' +convert (varchar(4),YEAR(Data_start)) when CONVERT(VARCHAR(10),MONTH(data_start)) = '4' then 'Aprilie' +' ' +convert (varchar(4),YEAR(Data_start))
						when CONVERT(VARCHAR(10),MONTH(data_start)) = '5' then 'Mai' +' ' +convert (varchar(4),YEAR(Data_start)) when CONVERT(VARCHAR(10),MONTH(data_start)) = '6' then 'Iunie' +' ' +convert (varchar(4),YEAR(Data_start))
						when CONVERT(VARCHAR(10),MONTH(data_start)) = '7' then 'Iulie' +' ' +convert (varchar(4),YEAR(Data_start)) when CONVERT(VARCHAR(10),MONTH(data_start)) = '8' then 'August' +' ' +convert (varchar(4),YEAR(Data_start))
						when CONVERT(VARCHAR(10),MONTH(data_start)) = '9' then 'Septembrie' +' ' +convert (varchar(4),YEAR(Data_start)) when CONVERT(VARCHAR(10),MONTH(data_start)) = '10' then 'Octombrie' +' ' +convert (varchar(4),YEAR(Data_start))
						when CONVERT(VARCHAR(10),MONTH(data_start)) = '11' then 'Noiembrie' +' ' +convert (varchar(4),YEAR(Data_start)) when CONVERT(VARCHAR(10),MONTH(data_start)) = '12' then 'Decembrie' +' ' +convert (varchar(4),YEAR(Data_start)) end ) as luna,

convert(int,sum (convert(int,SUBSTRING(ore_lucrate,1,2))) + sum (convert(int,SUBSTRING(ore_lucrate,3,2)))/60 + 1 ) as ore

from Raport_activitate r
inner join infotert i on i.Identificator=r.ID_angajat 

where data_start  between @dataj and @datas
and data_stop between @dataj and @datas
and i.Descriere like @angajat

group by  i.Descriere, MONTH(data_start), YEAR(data_start)

for xml raw
