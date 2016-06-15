--***
Create procedure wOPGenerareD112 @sesiune varchar(50), @parXML xml
as

declare @tipdecl int, @tiprectificare int, @ImpozitPL int, @ImpPLFaraSal int, @LmImpStatPl int, @ContCASSAgricol varchar(20), @ContImpozitAgricol varchar(20),
@numedecl varchar(75), @prendecl varchar(75), @functiedecl varchar(75), 
@OptiuniGenerare int, @lm char(9), @dinRia int, @cDirector varchar(254), @datalunii datetime, @lunaalfa varchar(15), @luna int, @an int, 
@dataJos datetime, @dataSus datetime, @userASiS varchar(20), @nrLMFiltru int, @LMFiltru varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareD112' 

set @tipdecl = ISNULL(@parXML.value('(/parametri/@tipdecl)[1]', 'int'), 0)
set @tiprectificare = ISNULL(@parXML.value('(/parametri/@tiprectificare)[1]', 'int'), 0)
set @ImpozitPL = ISNULL(@parXML.value('(/parametri/@impozitpl)[1]', 'int'), 0)
set @ImpPLFaraSal = ISNULL(@parXML.value('(/parametri/@impplfarasal)[1]', 'int'), 0)
set @LmImpStatPl = ISNULL(@parXML.value('(/parametri/@lmimpstatpl)[1]', 'int'), 0)
set @ContCASSAgricol = ISNULL(@parXML.value('(/parametri/@contcass)[1]', 'varchar(20)'), '')
set @ContImpozitAgricol = ISNULL(@parXML.value('(/parametri/@contimpozit)[1]', 'varchar(20)'), '')
set @OptiuniGenerare = ISNULL(@parXML.value('(/parametri/@optiunigenerare)[1]', 'int'), 0)
set @numedecl = ISNULL(@parXML.value('(/parametri/@numedecl)[1]', 'varchar(75)'), '')
set @prendecl = ISNULL(@parXML.value('(/parametri/@prendecl)[1]', 'varchar(75)'), '')
set @functiedecl = ISNULL(@parXML.value('(/parametri/@functiedecl)[1]', 'varchar(75)'), '')
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')

set @dinRia=1
set @cDirector=(select top 1 val_alfanumerica from par where Tip_parametru='AR' and Parametru='CALEFORM')

select @nrLMFiltru=count(1), @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)
set @datalunii = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @datalunii=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @dataJos = dbo.bom(@datalunii)
set @dataSus = dbo.eom(@datalunii)
select @lunaalfa=LunaAlfa from fCalendar(@dataSus,@dataSus)

begin try  
	--BEGIN TRAN
--	am scos eroarea de mai jos pt. a putea genera/verifica D112 cei de la APE la nivel de SGA
/*
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>0
		raiserror('Nu puteti genera declaratia unica 112 intrucat aveti drepturi de acces doar pe anumite locuri de munca!' ,16,1)
*/		
--	salvare parametrii (@ImpPLFaraSal si @LmImpStatP sunt scrisi in par si apoi sunt cititi in functi fDeclaratia112Impozit)
	exec setare_par 'PS', 'D112IMZPL', 'D112-Impozit pe pct. de lucru', @ImpozitPL, 0, ''
	exec setare_par 'PS', 'D112IPLFS', 'D112-impozit pt. PL fara sal.', @ImpPLFaraSal, 0, ''
	exec setare_par 'PS', 'D112PLLMS', 'D112-PL=loc munca stat plata', @LmImpStatPl, 0, ''
	exec setare_par 'PS', 'D112CASAA', 'D112-cont sanatate activ.agr.', 0, 0, @ContCASSAgricol
	exec setare_par 'PS', 'D112CIMAA', 'D112-cont impozit activ.agr.', 0, 0, @ContImpozitAgricol
	exec setare_par 'PS', 'NPERSAUT', 'Numele pers.pt. declaratia 112', 1, 0, @numedecl
	exec setare_par 'PS', 'PPERSAUT', 'Prenume pers.pt. declaratia 112', 1, 0, @prendecl
	exec setare_par 'PS', 'FPERSAUT', 'Funct. pers. pt. declaratia 112', 1, 0, @functiedecl

	exec Declaratia112 
		@dataJos, 
		@dataSus, 
		@tipdecl, --TipDeclaratie=0 Standard, 1 Rectificativa
		@ImpozitPL, --ImpozitPePuncteDeLucru 0 = Nu, 1=Da
		@numedecl, 
		@prendecl, 
		@functiedecl, 
		@dinRia, 
		@cDirector,	--cale generare fisier XML
		@OptiuniGenerare,	--Generare declaratie=0 (completare date ASIS sau import fisiere XML)+generare XML, 1-Import Fisiere XML, 2-Editare tabele declaratie, 3-Generare XML
		@lm,	--pentru filtrare loc de munca like (ANAR-pt. verificare 112 la nivel de SGA)
		@ContCASSAgricol,	--> Cont asigurari de sanatate retinute la achizitia de cereale 
		@ContImpozitAgricol,	--> Cont impozit retinut la achizitia de cereale 
		@tiprectificare	--> Tip declaratie rectificativa

	select 'S-a efectuat generarea declaratiei 112 pt. luna '+rtrim(@lunaalfa)+', anul '+convert(char(4),year(@dataSus))+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='Procedura wOPGenerareD112 (linia '+convert(varchar(20),ERROR_LINE())+'): '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
