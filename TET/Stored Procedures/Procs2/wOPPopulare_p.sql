--***
/* procedura pentru populare macheta tip 'operatii'  */
create procedure wOPPopulare_p @sesiune varchar(50), @parXML xml 
as  
declare @dataJos datetime, @dataSus datetime, @codCat varchar(2),  @update bit
/*
select	
	@codCat = rtrim(isnull(@parXML.value('(/parametri/@codCat)[1]', 'varchar(50)'), '')),
	@dataJos=rtrim(isnull(@parXML.value('(/parametri/@dataJos)[1]','datetime'),'01/01/2011')),
	@dataSus = rtrim(isnull(@parXML.value('(/parametri/@dataSus)[1]', 'datetime'),''))*/

/* 
	specific adaugare/modificare in cataloage:
	In general se doreste popularea de date doar la adaugare. Astfel, daca e update, 
	nu returnez nimic => initializare cu valorile din @parXML, fara alta prelucrare.

if @update=1
	return
*/
	
select  convert(varchar(20),
		dateadd(d,1-day(getdate()),dateadd(M,1-month(getdate()),getdate())),101) as dataJos, 
	    convert(varchar(20),getdate(),101) as dataSus, null as codCat
for xml raw


