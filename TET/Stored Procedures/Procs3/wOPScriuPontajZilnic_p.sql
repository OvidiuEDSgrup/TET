--***
Create procedure wOPScriuPontajZilnic_p @sesiune varchar(50), @parXML xml
as

declare @dataJos datetime, @dataSus datetime, @userASiS varchar(20), @marca varchar(6)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @datajos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'), '')
set @datasus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'), '1901-01-01')
set @marca = ISNULL(@parXML.value('(/row/@marca)[1]', 'varchar(6)'), '')

begin try  
	
	select rtrim(p.marca) as marca, rtrim(p.nume) as densalariat, rtrim(p.loc_de_munca) as lm, rtrim(lm.denumire) as denlm, rtrim(p.cod_functie) as functie, rtrim(f.Denumire) as denfunctie, 
	(case when exists (select 1 from PontajElectronic where marca=@marca and nullif(Data_ora_iesire,'01/01/1901') is null) then 'E' else 'I' end) as tipmiscare
	from personal p
		left outer join lm on lm.cod=p.Loc_de_munca
		left outer join functii f on f.cod_functie=p.Cod_functie
	where marca=@marca
	for xml raw
	
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPScriuPontajZilnic_p) '+ERROR_MESSAGE()
	select 1 as inchideFereastra for xml raw,root('Mesaje')	
	raiserror(@eroare, 16, 1) 
end catch
