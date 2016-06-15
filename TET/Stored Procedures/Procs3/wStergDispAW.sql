/***--
Procedura stocata sterge documentele din AntDisp daca acestea nu contin pozitii.

param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@iddisp	->	Identificator unic al dispozitiei care se doreste sa fie stearsa
--***/
CREATE PROCEDURE wStergDispAW @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wStergDispAWSP')
begin
	declare @returnValue int
	exec @returnValue = wStergDispAWSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(100),
		@iddisp int

begin try

	/*Validare utilizator*/
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Preia parametrii XML trimisi */
	select	@iddisp = @parXML.value('(/row/@iddisp)[1]', 'varchar(50)')
	
	/*Daca documentul a fost finalizat nu se mai poate opera */
	if((select a.stare from AntDisp a where a.idDisp = @iddisp) = 'Finalizat')
		raiserror('Documentul a fost finalizat. Nu se mai poate opera.', 11, 1)
	
	/*Verifica daca dispozitia este goala si o sterge in acest caz, altfel trimite mesaj de eroare */
	if ((select COUNT(1) from PozDispOp where idDisp = @iddisp) = 0)
		delete from AntDisp where idDisp = @iddisp
	else
		begin
			set @mesaj = 'Aceasta dispozitie contine pozitii neoperate '
			raiserror(@mesaj, 11, 1)
		end

end try

begin catch
	set @mesaj = '(wStergDispAW) '+ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from AntDisp
--select * from PozDispOp
--delete from pozdispop where idpoz > 1
--select p.* from pozCon p where tip = 'fc' and subunitate = '1'
--select * from pozdoc where subunitate = '1' and tip = 'rm'
/* <tip()> <contract(numarDocumentSursa identifica unic comanda)> */
