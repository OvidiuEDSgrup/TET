--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- reface calculul valorilor indicatorilor dintro anumite
categorie intre datele specificate */

CREATE  procedure wOPCalcCateg  @sesiune varchar(50), @parXML XML
as
--SET DATEFORMAT dmy;
declare @dataJos datetime, @dataSus datetime, @codCat varchar(50), @ind varchar(10),@nFetch int

set	@codCat = rtrim(isnull(@parXML.value('(/parametri/@codCat)[1]', 'varchar(50)'), ''))
set	@dataJos = rtrim(isnull(@parXML.value('(/parametri/@dataJos)[1]', 'datetime'), ''))
set	@dataSus = rtrim(isnull(@parXML.value('(/parametri/@dataSus)[1]', 'datetime'),''))

begin 
	exec CalcCategInd  @pCateg=@codCat,@pDataJos=@dataJos, @pDataSus=@dataSus,@lTipSold=0
/*	declare indicatori cursor for
	select rtrim(cod_ind) as cod from compcategorii	where Cod_Categ=@codCat

	open indicatori
	fetch next from indicatori into @ind 
	set @nFetch = @@fetch_status
	while @nFetch = 0 
	begin 
		exec calculInd @ind,@dataJos,@dataSus
				
		fetch next from indicatori into @ind 
		set @nFetch = @@fetch_status
	end
	close indicatori 
	deallocate indicatori	
	*/
	select 'S-a efectuat calcul pentru categoria'+' '+rtrim(@codCat)+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
End

