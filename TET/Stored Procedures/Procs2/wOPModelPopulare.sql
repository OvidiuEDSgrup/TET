--***
/* model pentru populare macheta tip 'formular' - adaugare/modificare in cataloage si operatii */
create procedure wOPModelPopulare @sesiune varchar(50), @parXML xml 
as  

declare @data datetime, @Gestiune varchar(10), @update bit

/*	
	daca e operatie pe documente, in parXML vin date despre linia asupra careia se executa operatia. 
	daca e operatie din meniu, parXML e gol.
	daca e adaugare in cataloage, parXML e gol.
	daca e modificare in cataloage se trimite linia editata si flag @update. 
*/
select	@data=isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'01/01/1901'),
		@gestiune =isnull(@parXML.value('(/parametri/@gestiune)[1]','varchar(10)'),''),
		@update=isnull(@parXML.value('(/parametri/@update)[1]','bit'),0)
		

/* 
	specific adaugare/modificare in cataloage:
	In general se doreste popularea de date doar la adaugare. Astfel, daca e update, 
	nu returnez nimic => initializare cu valorile din @parXML, fara alta prelucrare.
 */
if @update=1
	return

select '01/01/1901' datajos, '05/02/2099' datasus, @Gestiune gestiune, 1 stergere, 0 generare
for xml raw
