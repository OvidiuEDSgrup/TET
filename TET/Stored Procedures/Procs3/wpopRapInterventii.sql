--***
create procedure wpopRapInterventii @sesiune varchar(50) ,@parXML xml
as

declare @eroare varchar(1000)
begin try
	declare @masina varchar(50)
	select	@masina=@parXML.value('(row/@masina)[1]','varchar(50)')
	select upper(t.Tip_activitate) as 'tip_activitate', @masina as Masina
		from masini m
		inner join grupemasini g on m.grupa=g.Grupa
		inner join tipmasini t on g.tip_masina=t.Cod
	where m.cod_masina=@masina
	for xml raw
end try
begin catch
	set @eroare='wpopRapInterventii:'
		+char(10)+ERROR_MESSAGE()
	
end catch

if (@eroare is not null)
	raiserror(@eroare,16,1)
