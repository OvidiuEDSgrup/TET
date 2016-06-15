--***
Create procedure wOPExpandNCSalariiBugLM @sesiune varchar(50), @parXML xml
as

declare @userASiS varchar(20), @err int, @mesajEroare varchar(MAX), @lm varchar(20), @stergere int, @parXMLExpand xml

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @lm = ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(20)'),'')
set @stergere = ISNULL(@parXML.value('(/row/@stergere)[1]', 'int'),0)

begin try 
	if @lm=''
		raiserror('Loc de munca necompletat!' ,16,1)
	if @stergere=1
		delete from config_nc where Loc_de_munca=@lm

	insert into config_nc (Loc_de_munca, Numar_pozitie, Denumire, Cont_debitor, Cont_creditor, Comanda, Analitic, Expresie, 
		Identificator, Cont_CAS, Cont_CASS, Cont_somaj, Cont_impozit)  
	select @lm, numar_pozitie, denumire, Cont_debitor, Cont_creditor, Comanda, analitic, Expresie, 
		Identificator, Cont_CAS, Cont_CASS, Cont_somaj, Cont_impozit
	from config_nc c
	where Loc_de_munca is null
		and not exists (select 1 from config_nc c1 where c1.Loc_de_munca=@lm and c1.Numar_pozitie=c.Numar_pozitie)
/*
	set @parXMLExpand=(select rtrim(Loc_de_munca) as lm, numar_pozitie as nrpozitie, rtrim(Denumire) as denumire, 
		rtrim(Cont_debitor) as contdebitor, rtrim(Cont_creditor) as contcreditor, rtrim(Comanda) as comanda, analitic, rtrim(Expresie) as expresie, 
		rtrim(identificator) as identificator, rtrim(Cont_CAS) as contcas, rtrim(Cont_CASS) as contcass, rtrim(Cont_somaj) as contsomaj, rtrim(Cont_impozit) as contimpozit
		from config_nc where Loc_de_munca is null for xml raw, type)
	exec wScriuConfigNCSalariiBugetari @sesiune=@sesiune, @parXML=@parXMLExpand
*/
end try

begin catch
	--ROLLBACK TRAN
	declare @eroare varchar(254)
	set @eroare=+ERROR_MESSAGE()+' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare, 16, 1)
end catch
