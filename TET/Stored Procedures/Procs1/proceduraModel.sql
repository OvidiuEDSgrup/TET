--***
/* Procedura model care exemplifica aranjarea codului si metode recomandate de lucru. */
create procedure proceduraModel @sesiune varchar(50), @parXML xml
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='proceduraModelSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	-- momentan nu tratam return value de la proceduri, dar poate sa fie de folos pe viitor 
	-- recomand folosirea ei, impreuna cu return -1 daca au fost erori...
	exec @returnValue = proceduraModelSP @sesiune, @parXML output
	return @returnValue
end

declare @iDoc int, @Sub char(9), @mesaj varchar(200), @userASiS varchar(50), @gestutiliz varchar(50),
	@tert char(13), @referinta int, @tabReferinta int, @mesajEroare varchar(100), @pretCuAmanuntul bit, @FltStocPred bit

begin try -- folositi try/catch pentru a opri firul de executie a procedurii, daca au fost erori.

	/*luare date din parametri*/
	-- model simplificat pentru citire o singura variabila
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
	
	-- citire date din par folosind metoda CROSS-TAB
	select	@pretCuAmanuntul = (case when parametru='PRETAM' then Val_logica else @pretCuAmanuntul end), 
			@FltStocPred = (case when parametru='FNOMPRED' then Val_logica else @FltStocPred end)
	from par
	where (Tip_parametru='GE' and Parametru='FNOMPRED') or (Tip_parametru='AM' and Parametru='PRETAM')
	
	/* luarea utilizatorului ASiS logat - cu validare (daca folositi try/catch, 
		va sari automat in catch cand nu e bun utilizatorul) */
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	/* luarea utilizatorului ASiS logat - fara validare, nerecomandat */
	set @userASiS = dbo.fIaUtilizator(@sesiune)

	/* pt. luare proprietate utilizator logat - in acest exemplu se va returna doar o gestiune, 
	chiar daca ar mai multe configurate */
	set @gestutiliz= dbo.wfProprietateUtilizator('GESTIUNE',@userASiS)

	/* verificare existenta tabele temporare */
	IF OBJECT_ID('tempdb..#xmlterti') IS NOT NULL
		drop table #xmlterti

	/* cand se folosesc proceduri de validare (obligatoriu cu try/catch!) */
	exec proceduraValidareModel @sesiune=@sesiune, @parXML=@parXML
	
	/* 
		
	cod specific fiecarei proceduri
	*/
		
	/*daca se doreste trimiterea unui mesaj*/
	select 'Mesaj model' as textMesaj, 'Titlu mesaj' as titluMesaj for xml raw, root('Mesaje')
end try
begin catch
	/*se foloseste try/catch pentru ca la prima eroare, sa nu se execute restul comenzilor - 
	alegeti in functie de nevoie. Alternativa, folositi return -1 . */
	set @mesaj = '(proceduraModel)'+ERROR_MESSAGE()
	-- nu facem raiserror aici, ci dupa inchiderea cursorarelor, si stergerea tabelelor temporare.
end catch

/* daca se foloseste cursor, asa se recomanda stergerea.
In felul acesta nu va strica tranzactia (daca se executa procedura din alta procedura cu tranzactie) */
declare @cursorStatus int
set @cursorStatus=(select max(convert(int,is_open)) from sys.dm_exec_cursors(0) where name='cursorModel' and session_id=@@SPID )
if @cursorStatus=1
	close cursorModel
if @cursorStatus is not null
	deallocate cursorModel

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
