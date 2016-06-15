--***

create procedure [dbo].[wOPGenerareInterventii] @sesiune varchar(50), @parXML xml                
as              
-- procedura de generare interventii cu functia fIaInterventii din recomandari 
declare @subunitate char(9),@userASiS varchar(20), @Data_operarii datetime, @Ora_operarii char(6),  
		@err int,@datasus datetime,@dataInterventii datetime, @mesajeroare varchar(1000), 
		@tipfisa int -- 0=genereaza FI, 1=genereaza PI (planificare interventii) 
--
set @datasus = ISNULL(@parXML.value('(/parametri/@datasus)[1]', 'datetime'), '')  
set @dataInterventii = ISNULL(@parXML.value('(/parametri/@dataInterventii)[1]', 'datetime'), '')  
set @tipfisa = ISNULL(@parXML.value('(/parametri/@tipfisa)[1]', 'int'), 0)  
exec wIaUtilizator @sesiune,@userASiS
if isnull(@userASiS, '')='' set @userASiS=dbo.fIauUtilizatorCurent()
set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104) 
set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')
--   	
begin try 
    if exists (select 1 from activitati where data=@dataInterventii)
		begin
			set @mesajeroare='Exista interventii pe data '+convert(char(10),@dataInterventii,103)+' ! Nu mai puteti genera altele pana nu le stergeti!'
			raiserror(@mesajeroare,16,1)
		end
	--
	select *,IDENTITY(int,1,1) as nrPozitie into #tmpInterventii from dbo.fIaInterventii(@sesiune,@parXML) where tip='R' and scadenta=1 --and masina='30172'
	declare @masina varchar(20)
	select top 1 @masina=masina from #tmpInterventii group by masina having COUNT(1)>1
	if ISNULL(@masina,'')<>''
			select 'NU s-au generat interventii pentru total ore lucrate la data '+convert(char(10),@datasus,103)+' pentru data '+convert(char(10),@dataInterventii,103)+'! Exista cel putin un utilaj (cod '+RTRIM(@masina)+') cu normativ gresit! (Vezi Masini-Normativ: intervale identice)' as textMesaj for xml raw, root('Mesaje')
	else
		begin
			declare @idActivitati int, @idPozactivitati int
			insert into activitati (Tip,Fisa,Data,Masina,Comanda,Loc_de_munca,Comanda_benef,lm_benef,Tert,Marca,Marca_ajutor,Jurnal) select 
			'FI',rtrim(cast(DAY(@dataInterventii) as CHAR(2)))+rtrim(cast(month(@dataInterventii) as CHAR(2)))+substring(RTRIM(cast(nrPozitie as CHAR(20))),1,6),
			@dataInterventii,Masina,'','','','','','','','' 
			from #tmpInterventii
			select @idActivitati=IDENT_CURRENT('activitati')
			--
			insert into pozactivitati (Tip,Fisa,Data,Numar_pozitie,Traseu,Plecare,Data_plecarii,Ora_plecarii,Sosire,Data_sosirii,Ora_sosirii,Explicatii,Comanda_benef,Lm_beneficiar,Tert,Marca,Utilizator,Data_operarii,Ora_operarii,Alfa1,Alfa2,Val1,Val2,Data1--"se va inlocui cu"			, idActivitati
			) select 
			'FI',rtrim(cast(DAY(@dataInterventii) as CHAR(2)))+rtrim(cast(month(@dataInterventii) as CHAR(2)))+substring(RTRIM(cast(nrPozitie as CHAR(20))),1,6),
			@dataInterventii,1,
			'','',@dataInterventii,'0000','',@dataInterventii,'2300','GENERAT AUTOMAT','','','','',@userASiS,@Data_operarii,@Ora_operarii,'FI',Element,0,0,@dataInterventii 
			--"se va inlocui cu"			, @idActivitati
			from #tmpInterventii
			select @idPozactivitati=IDENT_CURRENT('pozactivitati')
			
			--
			insert into elemactivitati (Tip,Fisa,Data,Numar_pozitie,Element,Valoare,Tip_document,Numar_document,Data_document--"se va inlocui cu"			, idPozActivitati
			) select 
			'FI',rtrim(cast(DAY(@dataInterventii) as CHAR(2)))+rtrim(cast(month(@dataInterventii) as CHAR(2)))+substring(RTRIM(cast(nrPozitie as CHAR(20))),1,6),
			@dataInterventii,1,
			'OREBORD',bord,
			'','',@dataInterventii--"se va inlocui cu"			, @idPozactivitati
			from #tmpInterventii
			--
			insert into elemactivitati (Tip,Fisa,Data,Numar_pozitie,Element,Valoare,Tip_document,Numar_document,Data_document--"se va inlocui cu"			, idPozActivitati
			) select 
			'FI',rtrim(cast(DAY(@dataInterventii) as CHAR(2)))+rtrim(cast(month(@dataInterventii) as CHAR(2)))+substring(RTRIM(cast(nrPozitie as CHAR(20))),1,6),
			@dataInterventii,1,
			element,0,'','',@dataInterventii--"se va inlocui cu"			, @idPozactivitati
			from #tmpInterventii
			--	
			declare @total int
			set @total=ISNULL((select sum(1) from activitati where data=@dataInterventii and tip='FI'),0)					
			select 'S-au generat '+rtrim(CAST(@total as varchar(8)))+' interventii pentru total ore lucrate la data '+convert(char(10),@datasus,103)+' pentru data '+convert(char(10),@dataInterventii,103) as textMesaj for xml raw, root('Mesaje')
		end
	drop table #tmpInterventii
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
