--***
Create procedure wRUOPPreluareCompetente_p @sesiune varchar(50), @parXML xml 
as     
declare @codfunctie char(6), @denfunctie char(30), @id_evaluat int, @an_evaluat int,
@data_inceput datetime, @data_sfarsit datetime

set	@id_evaluat=isnull(@parXML.value('(/row/@id_evaluat)[1]','int'), 0)
set	@an_evaluat=isnull(@parXML.value('(/row/@an_evaluat)[1]','int'), 0)
Select @data_inceput=convert(datetime,'01/01/'+convert(char(4),@an_evaluat),101), 
	@data_sfarsit=convert(datetime,'12/31/'+convert(char(4),@an_evaluat),101)

select @codfunctie = Cod_functie from RU_persoane where ID_pers=@id_evaluat
select @denfunctie = Denumire from functii where Cod_functie=@codfunctie

select @codfunctie codfunctie, @denfunctie denfunctie, @an_evaluat an, 
@data_inceput data_inceput, @data_sfarsit data_sfarsit
for xml raw
