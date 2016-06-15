--***
Create procedure wRUOPPreluareCompetente @sesiune varchar(50), @parXML xml                
as              
declare @id_evaluare int, @tip char(2), @numarfisa char(20), @id_evaluat int, @id_evaluator int, @an int, @data datetime, @data_inceput datetime, @data_sfarsit datetime, @data_evaluare datetime, 
	@userASiS varchar(20), @err int, @codfunctie varchar(6), @denfunctie varchar(30)

set @id_evaluare = ISNULL(@parXML.value('(/row/@id_evaluare)[1]', 'int'), 0)
set @tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
set @numarfisa = ISNULL(@parXML.value('(/row/@nrfisa)[1]', 'varchar(20)'), '')
set @id_evaluat = ISNULL(@parXML.value('(/row/@id_evaluat)[1]', 'int'), 0)
set @data = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '')
set @an = @parXML.value('(/row/@an_evaluat)[1]', 'int')
set @data_inceput = ISNULL(@parXML.value('(/row/@data_inceput)[1]', 'datetime'), '')
set @data_sfarsit = ISNULL(@parXML.value('(/row/@data_sfarsit)[1]', 'datetime'), '')
set @data_evaluare = ISNULL(@parXML.value('(/row/row/@data_evaluare)[1]', 'datetime'), '')
set @id_evaluator = ISNULL(@parXML.value('(/row/row/@id_evaluator)[1]', 'int'), 0)

if @an is not null
	Select @data_inceput=convert(datetime,'01/01/'+convert(char(4),@an),101), 
		@data_sfarsit=convert(datetime,'12/31/'+convert(char(4),@an),101)

select @codfunctie=Cod_functie from RU_persoane where ID_pers=@id_evaluat
select @denfunctie=Denumire from functii where Cod_functie=@codfunctie

if isnull(@tip,'')=''
	set @tip = 'CO'
exec wIaUtilizator @sesiune=@sesiune,@utilizator=@userASiS

begin try 
    if 1=0
		raiserror('Momentan nu este finalizata operatia de preluare competente!' ,16,1)
    if @id_evaluat=0
		raiserror('Persoana evaluata necompletata!' ,16,1)
    if not exists (select 1 from RU_competente_functii where Cod_functie=@codfunctie)
		raiserror('Functia persoanei evaluate nu are atasate competente!',16,1)
    if exists (select 1 from RU_poz_evaluari where ID_evaluare=@id_evaluare)
		raiserror('Aceasta evaluare are deja introduse competente! Operatia este anulata!',16,1)
--	creez tabela temporara ce contine competentele parinte atasate pe functii 
--	si competentele copii ce tin de competentele parinte
	select cf.ID_competenta, cf.ID_competenta as ID_competenta_parinte, cf.Pondere as procent, 'PC' as subtip  
	into #tmpcompetente
	from RU_competente_functii cf
	where cf.Cod_functie=@codfunctie 
	union all 
	select c.ID_competenta, c.ID_competenta_parinte, c.Procent as procent, 'EC' as subtip 
	from RU_competente c
	where c.ID_competenta_parinte in (select ID_competenta from RU_competente_functii cf
	where cf.Cod_functie=@codfunctie)
--	formez XML pt. apelare procedura wRUScriuPozEvaluari
	declare @input XMl
	set @input=
	(select @tip as '@tip', @id_evaluare as '@id_evaluare',  rtrim(@numarfisa) as '@nrfisa', @data as '@data', @id_evaluat as '@id_evaluat', @an as '@an_evaluat', 
		(select rtrim(ID_competenta) as '@id_competenta', subtip as '@subtip', convert(char(10),@data_inceput,101) as '@data_inceput',
			convert(char(10),@data_sfarsit,101) as '@data_sfarsit', @id_evaluator as '@id_evaluator', convert(char(10),@data_evaluare,101) as '@data_evaluare',
			convert(decimal(5,2),procent) as '@procent'
		from #tmpcompetente
		Order by ID_competenta_parinte, ID_competenta
		for XML path,type
		)
	for xml Path,type)

	exec wRUScriuPozEvaluari @sesiune=@sesiune, @parXML=@input

	select 'S-au preluat competentele de pe functia: '+rtrim(@codfunctie)+' - '+rtrim(@denfunctie)+' !' as textMesaj for xml raw, root('Mesaje')
end try        

begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
