--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- adauga o categorie de indicatori 
verificand unicitatea codului*/

CREATE procedure  [dbo].[wScriuPosturiLucru]  @sesiune varchar(50), @parXML XML
as
declare @postlucru varchar(50), @locmunca varchar(50),  @denumire varchar(50),  @consilier varchar(50)
		

set @consilier= rtrim(isnull(@parXML.value('(/row/@consilier)[1]', 'varchar(10)'), ''))
set @postlucru= rtrim(isnull(@parXML.value('(/row/@postlucru)[1]', 'varchar(10)'), ''))
set	@locmunca = rtrim(isnull(@parXML.value('(/row/@locmunca)[1]', 'varchar(50)'), ''))
set	@denumire = rtrim(isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(50)'), ''))


--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)
if @modificare=1
begin
	update Posturi_de_lucru set Postul_de_lucru=@postlucru, Loc_de_munca=@locmunca,
	Consilier_responsabil=@consilier, Denumire=@denumire				
		where Postul_de_lucru =@postlucru
	return
end

--Aici incepe partea de adaugare
if exists(select Postul_de_lucru from Posturi_de_lucru where Postul_de_lucru=@postlucru)
begin
		declare @err varchar(100)
		set @err = (select 'Postul_de_lucru: '+@postlucru+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	

else
	insert into Posturi_de_lucru (Postul_de_lucru, Loc_de_munca, Consilier_responsabil, Denumire)
	       VALUES (@postlucru,@locmunca,@consilier,@denumire)
