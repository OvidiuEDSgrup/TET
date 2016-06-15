--***
create procedure wStergIndicatorTB (@sesiune varchar(50), @parXML xml)
as
begin
--set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20), @indicator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	select @indicator=@parxml.value('(row/@cod)[1]','varchar(20)')
	
--> validari
	if (@indicator is null) raiserror('Indicatorul nu a fost identificat! Nu s-a modificat nimic!',16,1)
	
	declare @indicatorInExpresie varchar(100)
	select @indicatorInExpresie='['+rtrim(@indicator)+']'

	select @eroare='Indicatorul e folosit in expresia indicatorului cu codul '+i.Cod_Indicator+' ("'+i.Denumire_Indicator+'")! Nu este permisa stergerea in aceasta situatie!'
		from indicatori i
		where charindex(@indicatorInExpresie,i.expresia)>0 and i.Cod_Indicator<>@indicator
	if @eroare is null
	select @eroare='Indicatorul e folosit in categoria cu codul '+c.Cod_Categ+' ('+isnull('"'+a.Denumire_categ+'"','<nedefinita>')+')! Nu este permisa stergerea in aceasta situatie!'
		from compcategorii c left join categorii a on c.cod_categ=a.Cod_categ
		where c.Cod_Ind=@indicator
		
	if @eroare is not null raiserror(@eroare,16,1)

--> stergere:
	delete Expval where cod_indicator=@indicator
	delete indicatori where Cod_Indicator=@indicator

--> confirmarea operatiei:	
	SELECT @indicator+
		' a fost sters din baza de date. Au fost sterse si eventualele valori calculate asociate lui!' AS textMesaj, 
		'Notificare' AS titluMesaj
	FOR XML raw, root('Mesaje')
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wStergIndicatorTB '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
