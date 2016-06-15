--***
/* 
*/
CREATE procedure wScriuGrupaMasini @sesiune varchar(50), @parXML XML
as
declare @grupa varchar(50), @denumire varchar(50), @o_grupa varchar(50), @tip_masina varchar(20)

set @grupa = rtrim(isnull(@parXML.value('(/row/@grupa )[1]', 'varchar(50)'), ''))
set @o_grupa = rtrim(isnull(@parXML.value('(/row/@o_grupa )[1]', 'varchar(50)'), ''))
set	@denumire = rtrim(isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(50)'), ''))
set	@tip_masina = rtrim(isnull(@parXML.value('(/row/@tip_masina)[1]', 'varchar(20)'), ''))

declare @siGrupeVechi int
set @siGrupeVechi=0
if exists (select 1 from sys.objects o where o.name='grmasini')
	set @siGrupeVechi=1

--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @modificare=1
begin
	update grupemasini set Grupa=@grupa, Denumire=@denumire, tip_masina=@tip_masina
		where Grupa =@o_grupa
	if @siGrupeVechi=1
	update grmasini set Grupa=@grupa, Denumire=@denumire
		where Grupa =@o_grupa
	return
end

--Aici incepe partea de adaugare
if exists(select Grupa from grupemasini where Grupa=@grupa )
begin
		declare @err varchar(100)
		set @err = (select 'Grupa: '+@grupa+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	

else
	insert into grupemasini (Grupa, Denumire, tip_masina, detalii)
	       VALUES (@grupa, @denumire, @tip_masina, null)
/*	if @siGrupeVechi=1 and not exists(select 1 from grmasini g where g.Grupa=@grupa)	-->Luci Maier: am exclus acest insert deoarece nu mergea bine.
	insert into grmasini (Grupa, Denumire, tip_masina)
	       VALUES (@grupa, @denumire, @tip_masina)	*/
	       
