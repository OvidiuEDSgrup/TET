--***
Create procedure wOPGenerareD205 @sesiune varchar(50), @parXML xml
as

declare @tipdecl int, @TipVenit char(2), -- cuprinde valori din lista prevazuta in legislatie
	@ticheteInVenitBrut int, @contImpozit char(30), @contFactura char(30), @contImpozitDividende char(30), @lm char(9), 
	@cDirector varchar(254), @an int, @dataJos datetime, @dataSus datetime, @userASiS varchar(20), 
	@nume_declar varchar(200), @prenume_declar varchar(200), @functie_declar varchar(100), 
	@nrLMFiltru int, @LMFiltru varchar(9), @mesajEroare varchar(max), @dinRia int, @sirDeMarci varchar(1000)

begin try  
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareD205' 

	--	a fost la inceput parametru (dupa @TipVenit) TipImpozit=1 Plata anticipata, 2 Impozit final
	set @tipdecl = isnull(@parXML.value('(/parametri/@tipdecl)[1]', 'int'), 0)
	set @TipVenit = isnull(@parXML.value('(/parametri/@tipvenit)[1]', 'varchar(2)'), '')
	set @ticheteInVenitBrut = isnull(@parXML.value('(/parametri/@ticheteinvenitbrur)[1]', 'int'), 0)
	set @contImpozit = isnull(@parXML.value('(/parametri/@contimpozit)[1]', 'varchar(30)'), '')
	set @contFactura = isnull(@parXML.value('(/parametri/@contfactura)[1]', 'varchar(30)'), '')
	set @contImpozitDividende = isnull(@parXML.value('(/parametri/@contimpozitdividende)[1]', 'varchar(30)'), '')
	set @lm = isnull(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
	set @nume_declar = isnull(@parXML.value('(/parametri/@numedecl)[1]', 'varchar(100)'), '')
	set @prenume_declar = isnull(@parXML.value('(/parametri/@prendecl)[1]', 'varchar(100)'), '')
	set @functie_declar = isnull(@parXML.value('(/parametri/@functiedecl)[1]', 'varchar(100)'), '')
	set @sirDeMarci = @parXML.value('(/parametri/@sirmarci)[1]', 'varchar(1000)')

	set @cDirector=(select top 1 val_alfanumerica from par where Tip_parametru='AR' and Parametru='CALEFORM')
	select @nrLMFiltru=count(1), @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)
	set @an = isnull(@parXML.value('(/parametri/@an)[1]', 'int'), 0)

	set @dataJos = convert(datetime,'01/01/'+str(@an,4))
	set @dataSus = dbo.eoy(convert(datetime,'01/01/'+str(@an,4)))

	if exists (select 1 from webconfigform where meniu='DE' and tip='D2' and subtip='GD' and DataField='@datajos' and Vizibil=1)
	begin
		set @dataJos = isnull(@parXML.value('(/parametri/@datajos)[1]', 'datetime'), @dataJos)
		set @dataSus = isnull(@parXML.value('(/parametri/@datasus)[1]', 'datetime'), @dataSus)
	end
	set @dinRia=(case when @an>=2012 then 1 else 0 end)

--	BEGIN TRAN
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>0 and 1=0
		raiserror('Nu puteti genera declaratia unica 205 intrucat aveti drepturi de acces doar pe anumite locuri de munca!' ,16,1)

	if @TipVenit='17' and @contImpozit='' and @an<2012 or @TipVenit='16' and @contImpozit='' and @an>=2012
	Begin
		set @mesajEroare='Trebuie completat contul de impozit pt. a genera declaratia 205 aferent categoriei de venit '+RTRIM(@TipVenit)+'!'
		raiserror(@mesajEroare,16,1)
	End	
	if @TipVenit='17' and @contFactura='' and @an<2012 or @TipVenit='16' and @contFactura='' and @an>=2012
	Begin
		set @mesajEroare='Trebuie completat contul de factura pt. a genera declaratia 205 aferent categoriei de venit '+RTRIM(@TipVenit)+'!'
		raiserror(@mesajEroare,16,1)
	End	
	if @TipVenit='08' and @contImpozitDividende='' 
	Begin
		set @mesajEroare='Trebuie completat contul de impozit corespunzator dividendelor pt. a genera declaratia 205 aferent categoriei de venit '+RTRIM(@TipVenit)+'!'
		raiserror(@mesajEroare,16,1)
	End	

--	salvare parametrii 
	exec setare_par 'PS', 'D205CVEN', 'D205-Categorie venit', 0, 0, @TipVenit
	exec setare_par 'PS', 'D205CTIMP', 'D205-Conturi impozit deseuri', 0, 0, @contImpozit
	exec setare_par 'PS', 'D205CTFAC', 'D205-Conturi factura deseuri', 0, 0, @contFactura
	exec setare_par 'PS', 'D205CTDIV', 'D205-Conturi impozit dividende', 0, 0, @contImpozitDividende
	exec setare_par 'PS', 'NPERSAUT', 'Nume pers. autoriz. declaratii', 0, 0, @nume_declar
	exec setare_par 'PS', 'PPERSAUT', 'Prenume pers. aut. declaratii', 0, 0, @prenume_declar
	exec setare_par 'PS', 'FPERSAUT', 'Functie pers. aut. declaratii', 0, 0, @functie_declar

	exec Declaratia205
		@dataJos=@dataJos, 
		@dataSus=@dataSus,
		@tipdecl=@tipdecl, -- TipDeclaratie=0 Initiala, 1 Rectificativa
		@TipVenit='', -- @TipVenit cuprinde valori din lista prevazuta in legislatie (am renuntat in 2012 cand se genereaza un singur fisier pt. toate tipurile de venit)
		@ticheteInVenitBrut=@ticheteInVenitBrut, -- stabileste cumularea valorii tichetelor de masa in venitul brut
		@contImpozit=@contImpozit, @contFactura=@contFactura, @contImpozitDividende=@contImpozitDividende, 
		@lm=@lm, @strict=0,
		@nume_declar=@nume_declar, @prenume_declar=@prenume_declar, @functie_declar=@functie_declar, 
		@dinRia=@dinRia,
		@cDirector=@cDirector, --cale generare fisier TXT
		@sirDeMarci=@sirDeMarci

	select 'S-a efectuat generarea declaratiei 205 pentru anul '+convert(char(4),year(@dataSus))+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
--	COMMIT TRAN
end try  

begin catch  
--	ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPGenerareD205) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
