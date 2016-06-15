/***--
Procedura stocata permite schimbarea starii antetului documentului.

param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@tip		->	Tipul machetei curente (se citeste si trimite mai departe pentru
									identificare in Forms)
					@iddisp		->	Identificator unic al documentului pe care se lucreaza
					@stare		->	Starea in care doreste sa se treaca documentul
--***/
CREATE PROCEDURE wOPSchimbareStareAW @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPSchimbareStareAWSP')
begin
	declare @returnValue int
	exec @returnValue = wOPSchimbareStareAWSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(1000),
		@iddisp int, @idpoz int, @tip varchar(2),
		@stare varchar(10)

begin try

	/*Validare utilizator*/
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Preia parametrii XML trimisi */
	select	@iddisp = @parXML.value('(/parametri/@iddisp)[1]', 'int'),
			@tip	= @parXML.value('(/parametri/@tip)[1]', 'varchar(2)'),
			@stare	= @parXML.value('(/parametri/@stare)[1]', 'varchar(10)')
			
	/*Daca nu s-a selectat nici un document nu se poate efectua operatia. */
	if(@iddisp is null)
		raiserror('Va rugam sa selectati documentul pe care doriti sa il modificati.',11, 1)
		
	/*Daca documentul a fost finalizat nu se mai poate opera starea acestuia */
	if((select a.stare from AntDisp a where a.idDisp = @iddisp) = 'Finalizat')
		raiserror('Documentul a fost finalizat. Nu se mai poate opera starea.', 11, 1)

	if len(@stare)=0
		raiserror('Starea aleasa este invalida',11,1)
	
	update AntDisp
		set stare = @stare
	where idDisp = @iddisp
	
end try

begin catch
	set @mesaj = '(wOPSchimbareStareAW)'+ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from AntDisp
--select * from PozDispOp
--delete from pozdispop where idpoz > 1
--select p.* from pozCon p where tip = 'fc' and subunitate = '1'
--select * from pozdoc where subunitate = '1' and tip = 'rm'
/* <tip()> <contract(numarDocumentSursa identifica unic comanda)> */
