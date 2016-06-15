--***
create procedure [dbo].[wStergPozInt] @sesiune varchar(50), @parXML xml
as 

declare @eroare varchar(1000),@userASiS varchar(10)
set @eroare=''
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	declare @masina varchar(50), @data datetime
	select	@masina=@parXML.value('(row/@masina)[1]','varchar(50)'),
			@data=@parXML.value('(row/@data)[1]','datetime')
	if (select count(1) from activitati a where a.masina=@masina and month(data)=month(@data) and year(@data)=year(@data) and a.tip='FI')>1
		raiserror('Masina are mai multe foi de interventie pe luna curenta! Trebuie gestionate din macheta de foi de interventie!',16,1)
	
	delete ea from elemactivitati ea inner join activitati a on ea.fisa=a.fisa and ea.data=a.data and a.masina=@masina and a.tip='FI'
			and month(ea.data)=month(@data) and year(ea.data)=year(@data)
	delete pa from pozactivitati pa inner join activitati a on pa.fisa=a.fisa and pa.data=a.data	--	se va inlocui cu			pa.idActivitati=a.idActivitati
			and a.masina=@masina and a.tip='FI'
			and month(pa.data)=month(@data) and year(pa.data)=year(@data)
	delete a from activitati a where a.masina=@masina and month(data)=month(@data) and year(data)=year(@data) and a.tip='FI'
	
	exec wIaPozInt @sesiune=@sesiune, @parXML=@parXML
end try
begin catch
	set @eroare=ERROR_MESSAGE()
	if len(@eroare)>0
	set @eroare='wStergPozInt:'+
		char(10)+rtrim(@eroare)
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
