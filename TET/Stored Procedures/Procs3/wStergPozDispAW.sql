/***--
Procedura stocata sterge pozitia selectata din documentul curent.

param:	@sesiune:varchar(50)	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML:XML				Parametru xml in care vin datele. Se citeste:
								@idpoz	->	Identificator unic al pozitiei care se doreste sa fie stearsa
								@iddisp	->	Identificator unic al documentului in care s-a efectuat stergerea
--***/
CREATE PROCEDURE wStergPozDispAW @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPozDispAWSP')
begin
	declare @returnValue int
	exec @returnValue = wStergPozDispAWSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(100),
		@idpoz int, @iddisp int

begin try

	/*Validare utilizator*/
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Preia parametrii XML trimisi */
	select	@idpoz	= isnull(@parXML.value('(/row/row/@idpoz)[1]', 'int'), -1),
			@iddisp = @parXML.value('(/row/row/@iddisp)[1]', 'int')
	
	if(@idpoz = -1)
		raiserror('Va rugam selectati pozitia care se doreste stearsa.', 11, 1)
	
	/*Daca documentul a fost finalizat nu se mai poate opera */
	if((select a.stare from AntDisp a where a.idDisp = @iddisp) = 'Finalizat')
		raiserror('Documentul a fost finalizat. Nu se mai poate opera.', 11, 1)
	
	/*Sterge pozitia selectata din PozDispOp*/
	delete from PozDispOp where idPoz = @idpoz
	
	/*Trebuie chemata din nou procedura de populare pozitii pentru refresh grid */	
	declare @xml xml
	set @xml = (select @iddisp iddisp for xml raw)
	exec wIaPozDispAW @sesiune = @sesiune, @parXML = @xml

end try

begin catch
	set @mesaj = '(wStergPozDispAW) '+ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from AntDisp
--select * from PozDispOp
--delete from pozdispop where idpoz > 1
--select p.* from pozCon p where tip = 'fc' and subunitate = '1'
--select * from pozdoc where subunitate = '1' and tip = 'rm'
/* <tip()> <contract(numarDocumentSursa identifica unic comanda)> */
