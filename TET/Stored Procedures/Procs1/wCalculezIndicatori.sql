--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- reface calculul valorilor indicatorilor dintro anumite
categorie intre datele specificate */

CREATE  procedure wCalculezIndicatori  @sesiune varchar(50), @parXML XML
as
declare @dataJos datetime, @dataSus datetime, @codCat varchar(20), @ind varchar(20),@nFetch int

set	@codCat = rtrim(isnull(@parXML.value('(/*/@codCat)[1]', 'varchar(50)'), ''))
set	@ind = rtrim(isnull(@parXML.value('(/*/@cod)[1]', 'varchar(50)'), ''))
set	@dataJos = rtrim(isnull(@parXML.value('(/*/@dataJos)[1]', 'datetime'), ''))
set	@dataSus = rtrim(isnull(@parXML.value('(/*/@dataSus)[1]', 'datetime'),''))
select @dataSus=dbo.eom(@dataSus)

Declare @cHostID char(8)
set @cHostID = convert(char(8),abs(convert(int, host_id())))
delete from tmp_calculat where hostid=@cHostid

if @ind!='' -- pentru un indicator 
begin
	exec calculInd @ind,@dataJos,@dataSus
	select 'S-a efectuat calcul pentru indicatorul '+' '+rtrim(@ind)+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	return
end

if @codCat!='' -- pentru o categorie 
begin
	exec CalcCategInd @pCateg=@codCat,@pDataJos=@dataJos,@pDataSus=@dataSus,@lTipSold=0,@lFaraStergere=0  
	select 'S-a efectuat calcul pentru categoria'+' '+rtrim(@codCat)+'!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')	
	return
end

-- pentru toti indicatorii ce apar in Tabloul de Bord
declare categTB cursor for
select rtrim(cod_categ) as cod_categ 
	from categorii 
	where categ_tb>0
open categTB
fetch next from categTB into @codCat 
set @nFetch = @@fetch_status
while @nFetch = 0 
begin 
	print 'Calculez pentru categoria:'+@codCat
	exec CalcCategInd @pCateg=@codCat,@pDataJos=@dataJos,@pDataSus=@dataSus,@lTipSold=0,@lFaraStergere=0  
	fetch next from categTB into @codCat 
	set @nFetch = @@fetch_status
end
close categTB 
deallocate categTB	
--*/
select 'S-a efectuat calcul pentru categoriile tabloului de bord!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
