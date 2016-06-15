--
CREATE procedure [dbo].[wStergElemTipuri] @sesiune varchar(50),@parXML XML
as
declare @eroare varchar(1000),@utilizatorASiS varchar(50)
set @eroare=''
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	declare @element varchar(20), @tip_masina char(20)
	select	@element=isnull(@parXML.value('(row/row/@element)[1]','varchar(20)'),''), @tip_masina=isnull(@parXML.value('(row/row/@tipMasina)[1]','varchar(20)'),'') 

	-->	verificari consistenta parametri
		if ((@element='') or (@tip_masina='')) raiserror('Nu s-a identificat elementul de sters! Verificati configurarea machetei si procedura!',16,1)
	
	-->	verificari mentinere consistenta date
		--> corelatia elemente pe tipuri - elemente pe masini
		declare @masina_db varchar(50), @denmasina_db varchar(200)
		set @masina_db=''
			select top 1 @masina_db=rtrim(m.cod_masina), @denmasina_db=rtrim(m.denumire) from 
				masini m 
				inner join activitati a on m.cod_masina=a.Masina
				inner join elemactivitati ea on ea.tip=a.tip and ea.fisa=a.fisa and ea.data=a.data 
			where m.tip_masina=@tip_masina and ea.element=@element 
		if (len(@masina_db)>0) 
			begin
				set @eroare='Elementul "'+@element+'" este folosit (cel putin la masina "'+@masina_db+'" ("'+@denmasina_db+'")) ; nu este permisa stergerea!'
				raiserror(@eroare,16,1)
			end

	-->	stergerea elementului pe tipuri
		delete e from elemtipm e where tip_masina=@tip_masina and e.element=@element

end try
begin catch
	set @eroare='wStergElemTipuri'+
		char(10)+ERROR_MESSAGE()
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
