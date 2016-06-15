--***
/* 
Procedura apartine componentei TB care afisaza graficele - aduce in dreptul fiecarui indicator, informatiile generale pt configurarea indicatorului.
*/
CREATE procedure  wIaIndicatoriTB  @sesiune varchar(50), @parXML XML 
as  
set transaction isolation level read uncommitted

if exists (select 1 from sysobjects where [type]='P' and [name]='wIaIndicatoriTBSP')
begin
	exec wIaIndicatoriTBSP @sesiune, @parXML output
	return
end

Declare @categorie varchar(50)
Declare @recalculare bit
Declare @ind varchar(50)
Declare @dataJos datetime
Declare @dataSus datetime, @nFetch int
Declare @indicator varchar(50)

Set @categorie = isnull(@parXML.value('(/row/@categorie)[1]','varchar(50)'),'')
Set @indicator= isnull(@parXML.value('(/row/@indicator)[1]','varchar(50)'),'')
Set @recalculare = ISNULL(@parXML.value('(/row/@recalculare)[1]','bit'),'0')

Set @dataJos = convert(datetime,ISNULL(@parXML.value('(/row/@dataJos)[1]','varchar(50)'),'01/01/1901'),103)
Set @dataSus = convert(datetime,ISNULL(@parXML.value('(/row/@dataSus)[1]','varchar(50)'),'01/01/1901'),103)

IF @recalculare = 1 -- s-a eliminat butonul de recalculare -> nu cred ca mai trece pe-aici vreodata
begin 
	declare indicatori cursor for
	select rtrim(cod_ind) as cod from compcategorii	where Cod_Categ=@categorie

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
End

select rtrim(compcategorii.Cod_Ind) as "@indicator",
	rtrim(indicatori.Denumire_Indicator) as "@denumire",
	indicatori.Ordine_in_raport as "@cuData", 
	indicatori.Total as "@gaugeInvers",
	(select numar as "@nivel", rtrim(Denumire) "@denumire", Procedura "@procedura", tip_filtru "@tipfiltru" , Tip_grafic "@tipgrafic"
		from colind 
		where Cod_indicator= compcategorii.Cod_Ind order by numar
		for xml path('row'),root('nivele'),type ),
	(	select nume as "@nume", pathraport as "@pathraport", procpopulare as "@procpopulare"
		from 
			(select 'Export date' as nume, '/TB/Date TB' pathraport, 'wOPExportExcel_p' procpopulare
				union all
				select 'Grafic Indicator' as nume, '/TB/Grafic Indicator' pathraport, 'wOPExportExcel_p' procpopulare
				union all
				select Nume_raport as nume, Path_raport pathraport, Procedura_populare procpopulare
					from rapIndicatori where Cod_indicator=compcategorii.Cod_Ind ) tabel
		for xml path('row'),root('rapoarte'),type )
from compcategorii
inner join indicatori on compcategorii.Cod_Ind=indicatori.Cod_Indicator
where compcategorii.Cod_Categ=@categorie and (isnull(@indicator,'')='' or indicatori.Cod_Indicator = @indicator)
group by compcategorii.Cod_Ind,indicatori.Denumire_Indicator, indicatori.Unitate_de_masura,indicatori.Ordine_in_raport,indicatori.Total,compcategorii.Rand
order by compcategorii.Rand
for xml path ('indicator'), root('Date'), type
