--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- adauga o categorie de indicatori 
verificand unicitatea codului*/

CREATE procedure  [dbo].[wScriuOp]  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(10), @denumire varchar(50), @o_cod varchar(20), @UM varchar(50), 
		@tipoperatie varchar(50), @categorie varchar(50), @tarif varchar(50), 
		@nrpersoane varchar(50), @nrpozitii varchar(50)  
		

set @cod= rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(10)'), ''))
set @o_cod= rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(10)'), ''))
set	@denumire = rtrim(isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(50)'), ''))
set	@UM = rtrim(isnull(@parXML.value('(/row/@um)[1]', 'varchar(50)'), ''))
set	@tipoperatie = rtrim(isnull(@parXML.value('(/row/@tipoperatie)[1]', 'varchar(50)'), ''))
set	@nrpozitii = rtrim(isnull(@parXML.value('(/row/@nrpozitii)[1]', 'varchar(50)'), ''))
set	@nrpersoane = rtrim(isnull(@parXML.value('(/row/@nrpersoane)[1]', 'varchar(50)'), ''))
set	@categorie = rtrim(isnull(@parXML.value('(/row/@categorie)[1]', 'varchar(50)'), ''))
set @tarif= rtrim(isnull(@parXML.value('(/row/@tarif)[1]', 'varchar(10)'), ''))


--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @modificare=1
begin
	update catop  set Cod=@cod, Denumire=@denumire,UM=@UM, Tip_operatie=@tipoperatie, Numar_persoane=@nrpersoane,
     Numar_pozitii=@nrpozitii,Tarif=@tarif,Categorie=@categorie
		where Cod =@o_cod
	return
end

--Aici incepe partea de adaugare
if exists(select Cod from catop where Cod=@cod)
begin
		declare @err varchar(100)
		set @err = (select 'Cod: '+@cod+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	

else
	insert into catop (Cod, Denumire, UM, Tip_operatie, Numar_pozitii, Numar_persoane, Tarif, Categorie)
	       VALUES (@cod, @denumire, @um, @tipoperatie, @nrpozitii, @nrpersoane, @tarif, @categorie)
