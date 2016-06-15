/** procedura pentru scriere planificare\evaluare competente\obiective **/
Create procedure wRUScriuPozEvaluari @sesiune varchar(50), @parXML XML  
as
begin try
declare 
	--Date antet
	@numarfisa varchar(20), @data datetime, @id_evaluare int, @tip varchar(2), @id_evaluat int, @an_evaluat int, @media decimal(5,2), @gid_evaluare int, @gnumarfisa varchar(20), 
	--Date pozitie
	@id_poz_evaluare int, @id_competenta int, @id_obiectiv int, @id_indicator int, @data_inceput datetime, @data_sfarsit datetime, 
	@id_evaluator int, @data_evaluare datetime, @nota decimal(5,2), @id_calificativ int, @procent float, @data_operarii datetime, @ora_operarii char(6), @utilizator char(10),
	--Altele
	@subtip varchar(2), @update bit, @eroare varchar(200), @id_calificativ_parinte int, @calificativ_parinte int, @nota_parinte decimal(8,2), 
	--Parinte (modificari/adaugari pozitii)
	@id_competentaLinie int, @id_obiectivLinie int, @id_indicatorLinie int, @parinteTopLinie int, @tip_evaluatLinie varchar(2), @idpozLinie int, @grupareLinie varchar(20), 
	@Tip_evaluat varchar(2)

	set @gid_evaluare=0
declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
select @subtip=@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)')
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

if @subtip='PR'
	exec wRUOPPreluareCompetente @sesiune, @parXML
else
Begin	
	declare crsPozEval cursor for
	select id_evaluare, tip, numarfisa, data, id_evaluat, an_evaluat, media, isnull(id_poz_evaluare,0), id_competenta, id_obiectiv, id_indicator, 
	data_inceput, data_sfarsit, nota, id_calificativ, procent, id_evaluator, data_evaluare, id_competentaLinie, id_obiectivLinie, id_indicatorLinie, tip_evaluatLinie, idpozLinie, 
	isnull(ptupdate,0), subtip
	from OPENXML(@iDoc, '/row/row') 
	WITH 
	(
--		Antet
		id_evaluare int '../@id_evaluare',
		tip varchar(2) '../@tip',
		numarfisa varchar(20) '../@nrfisa',
		data datetime '../@data',
		id_evaluat int '../@id_evaluat',
		an_evaluat int '../@an_evaluat',
		media decimal(5,2) '../@media',
--		Pozitie
		id_poz_evaluare int '@id_poz_evaluare',
		id_competenta int '@id_competenta',
		id_obiectiv int '@id_obiectiv',
		id_indicator int '@id_indicator',
		data_inceput datetime '@data_inceput',
		data_sfarsit datetime '@data_sfarsit',
		nota decimal(8,2) '@nota',
		id_calificativ int '@id_calificativ',
		procent float '@procent',
		id_evaluator int '@id_evaluator',
		data_evaluare datetime '@data_evaluare',
		ptupdate int '@update',
		subtip varchar(2) '@subtip',
--		Linie
		id_competentaLinie int '../linie/@id_competenta',
		id_obiectivLinie int '../linie/@id_obiectiv',
		id_indicatorLinie int '../linie/@id_indicator',
		tip_evaluatLinie varchar(2) '../linie/@subtip',
		idpozLinie int '../linie/@id_poz_evaluare'	
	)
	open crsPozEval
	fetch next from crsPozEval into @id_evaluare, @tip, @numarfisa, @data, @id_evaluat, @an_evaluat, @media, @id_poz_evaluare, @id_competenta, @id_obiectiv, @id_indicator, 
	@data_inceput, @data_sfarsit, @nota, @id_calificativ, @procent, @id_evaluator, @data_evaluare, @id_competentaLinie, @id_obiectivLinie, @id_indicatorLinie, @tip_evaluatLinie, 
	@idpozLinie, @update, @subtip
	while @@fetch_status=0
	begin
--		Determinare tip evaluare pozitie
		set @Tip_evaluat=@subtip
--		determin calificativul functie de nota
		if @id_calificativ is null or isnull(@nota,0)<>0
		Select @id_calificativ=ID_calificativ 
			from RU_calificative where @nota between Nota_inferioara and Nota_superioara and year(Data_sfarsit)=@an_evaluat and year(Data_sfarsit)=@an_evaluat
		
		if @id_calificativ is null and @nota is not null
		begin
			raiserror('Nota introdusa nu este cuprinsa in catalogul de "Nivele de performanta"!',11,1)
			return -1
		end
						
		if @update=0
--		Adaugare date (nu modificare)
		begin
			if @id_evaluare = 0 and @gid_evaluare=0
--		Adaugare evaluare
			begin
				exec wRUiauNrFisa @Tip=@Tip, @Numar=@numarfisa output, @Data=@Data output
				set @gnumarfisa=@numarfisa
				if @numarfisa = ''
				begin
					raiserror('Numar fisa necompletat!',11,1)
					return -1
				end
				if @id_evaluat is null
				begin
					raiserror('Persoana evaluata necompletata!',11,1)
					return -1
				end
				create table #id_evaluare (id_evaluare int)
				insert into RU_evaluari (Tip, Numar_fisa, Data, ID_evaluat, ID_evaluator, An_evaluat, ID_calificativ, Media)
					output inserted.ID_evaluare into #id_evaluare
					values (@tip, @numarfisa,@data,@id_evaluat,@id_evaluator,@an_evaluat,Null,0)
			End
--		Insert
--		determin id_evaluare la adaugare prima pozitie pe document
			if @id_evaluare=0
				select @id_evaluare=id_evaluare, @gid_evaluare=id_evaluare from #id_evaluare
--				select @id_evaluare=id_evaluare from RU_evaluari where Numar_fisa=@numarfisa and Data=@data
			
			if @tip_evaluatLinie in ('PO','EO') and @tip_evaluat='EO'
				select @id_competenta=@id_competentaLinie, @id_obiectiv=@id_obiectivLinie, @id_indicator=@id_indicatorLinie 

			if @tip_evaluatLinie in ('PC','EC') and @tip_evaluat='EC'
				select @id_competenta=@id_competentaLinie

			insert into RU_poz_evaluari (ID_evaluare, Tip_evaluat, ID_competenta, ID_obiectiv, ID_indicator, Data_inceput, Data_sfarsit, ID_evaluator, Data_evaluare, ID_calificativ, Procent, Nota,
			Data_operarii, Ora_operarii, Utilizator)
				values (@id_evaluare, @Tip_evaluat, @id_competenta, @id_obiectiv, @id_indicator, @data_inceput, @data_sfarsit, @id_evaluator, @data_evaluare, @id_calificativ, @procent, @nota, 
					convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', '')), @utilizator)
		end
--		Gata adaugari
		else
			update RU_poz_evaluari set ID_obiectiv=(case when @subtip ='PO' then @id_obiectiv else ID_obiectiv end), ID_indicator=(case when @subtip ='PO' then @id_indicator else ID_indicator end), 
			ID_competenta=(case when @subtip in ('PC','EC') then @id_competenta else ID_competenta end), Procent=(case when @subtip in ('PC','EC') then @procent else Procent end), 
			Data_inceput=(case when @subtip in ('PO','PC') then @data_inceput else Data_inceput end), Data_sfarsit=(case when @subtip in ('PO','PC') then @data_sfarsit else Data_sfarsit end), 
			ID_evaluator=(case when @subtip in ('EO','EC') then @id_evaluator else ID_evaluator end), ID_calificativ=(case when @subtip in ('EO','EC') then @id_calificativ else ID_calificativ end), 
			Data_evaluare=(case when @subtip in ('EO','EC') then @data_evaluare else Data_evaluare end), nota=(case when @subtip in ('EO','EC') then @nota else Nota end),
			Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')), Utilizator=@utilizator
			where ID_poz_evaluare= @id_poz_evaluare

--	calcul calificativ pe competente
		if @subtip ='EC'
		Begin 
			declare @id_competenta_parinte int
--	stabilesc competenta parinte
			select @id_competenta_parinte=ID_competenta_parinte from RU_competente where ID_competenta=@id_competenta
--	calculez media calificativelor (aceasta a fost varianta initiala)/media notelor (aceasta a fost varianta dupa introducerea plajelor de note pe calificative) 
--	de pe competentele copii functie de tipul de calcul introdus pe calificativul parinte
			select 
				@calificativ_parinte=round((case when max(d.Tip_calcul_calificativ)=1 then sum(c.Calificativ)/convert(float,count(1)) else sum(c.Calificativ*e.Procent/100) end),0), 
				@nota_parinte=round((case when max(d.Tip_calcul_calificativ)=1 then sum(e.Nota)/convert(float,count(1)) else sum(e.Nota*e.Procent/100) end),2)
			from RU_poz_evaluari e
				left outer join RU_calificative c on c.ID_calificativ=e.ID_calificativ  and year(c.Data_sfarsit)=@an_evaluat
				left outer join RU_competente p on p.ID_competenta=e.ID_competenta
				left outer join RU_competente d on d.ID_competenta=@id_competenta_parinte
			where ID_evaluare=@id_evaluare and isnull(e.ID_calificativ,0)<>0 and e.Tip_evaluat='EC'
			and e.ID_competenta in (select ID_competenta from RU_competente where ID_competenta_parinte=@id_competenta_parinte)
--	stabilesc ID calificativ parinte tinand cont de media calificativelor de pe competentele copii
			Select @id_calificativ_parinte=ID_calificativ 
				from RU_calificative where Calificativ=@calificativ_parinte and year(Data_sfarsit)=@an_evaluat and year(Data_sfarsit)=@an_evaluat
--	stabilesc ID calificativ parinte tinand cont de nota parinte
			Select @id_calificativ_parinte=ID_calificativ 
				from RU_calificative where @nota_parinte between Nota_inferioara and Nota_superioara and year(Data_sfarsit)=@an_evaluat and year(Data_sfarsit)=@an_evaluat

			update RU_poz_evaluari set Nota=@nota_parinte, ID_calificativ=@id_calificativ_parinte, 
				Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')), Utilizator=@utilizator
			where ID_evaluare=@id_evaluare and ID_competenta=@id_competenta_parinte
			
			update RU_evaluari set Media=a.Media, ID_calificativ=c.ID_calificativ
			from (select ID_evaluare, round(sum(p.Nota*p.Procent/100),2)  as Media, round(sum(c.Calificativ*p.Procent/100),2)  as Calificativ
					from RU_poz_evaluari p 
						left outer join RU_calificative c on c.ID_calificativ=p.ID_calificativ and year(c.Data_sfarsit)=@an_evaluat
					where ID_evaluare=@id_evaluare and p.Tip_evaluat='PC' and isnull(p.ID_calificativ,0)<>0 Group by p.ID_evaluare) a
			left outer join RU_calificative c on c.Calificativ=round(a.Calificativ,0) and year(c.Data_sfarsit)=@an_evaluat
			where RU_evaluari.ID_evaluare=@id_evaluare
		End	
--	calcul calificativ pe obiectiv/indicator planificat functie de calificativul ultimei evaluari; calcul calificativ pe evaluare
		if @subtip ='EO'
		Begin 
			select @nota_parinte=e.Nota, @id_calificativ_parinte=e.ID_calificativ 
			from RU_poz_evaluari e
			where ID_evaluare=@id_evaluare and isnull(e.ID_calificativ,0)<>0 and e.Tip_evaluat='EO'
				and e.ID_obiectiv=@id_obiectiv and e.ID_indicator=@id_indicator 
				and e.Data_evaluare in (select top 1 Data_evaluare from RU_poz_evaluari where ID_evaluare=@id_evaluare and isnull(ID_calificativ,0)<>0 and Tip_evaluat='EO'
					and ID_obiectiv=@id_obiectiv and ID_indicator=@id_indicator order by Data_evaluare desc)

			Select @id_calificativ_parinte=ID_calificativ 
				from RU_calificative where @nota_parinte between Nota_inferioara and Nota_superioara and year(Data_sfarsit)=@an_evaluat and year(Data_sfarsit)=@an_evaluat

			update RU_poz_evaluari set Nota=@nota_parinte, ID_calificativ=@id_calificativ_parinte, 
				Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')), Utilizator=@utilizator
			from RU_poz_evaluari e 
			where ID_evaluare=@id_evaluare and e.Tip_evaluat='PO' and e.ID_obiectiv=@id_obiectiv and e.ID_indicator=@id_indicator

			update RU_evaluari set Media=a.Media, ID_calificativ=c.ID_calificativ
			from (select ID_evaluare, round(sum(p.Nota)/convert(float,count(1)),2)  as Media, round(sum(c.Calificativ)/convert(float,count(1)),2)  as Calificativ
					from RU_poz_evaluari p 
						left outer join RU_calificative c on c.ID_calificativ=p.ID_calificativ and year(c.Data_sfarsit)=@an_evaluat
					where ID_evaluare=@id_evaluare and p.Tip_evaluat='PO' and isnull(p.ID_calificativ,0)<>0 Group by p.ID_evaluare) a
			left outer join RU_calificative c on c.Calificativ=round(a.Calificativ,0) and year(c.Data_sfarsit)=@an_evaluat
			where RU_evaluari.ID_evaluare=@id_evaluare
		End

		fetch next from crsPozEval into @id_evaluare, @tip, @numarfisa, @data, @id_evaluat, @an_evaluat, @media, @id_poz_evaluare, @id_competenta, @id_obiectiv, @id_indicator, 
			@data_inceput, @data_sfarsit, @nota, @id_calificativ, @procent, @id_evaluator, @data_evaluare, @id_competentaLinie, @id_obiectivLinie, @id_indicatorLinie, 
			@tip_evaluatLinie, @idpozLinie, @update, @subtip
	End
	declare @docXMLIaPozEvaluari xml
	set @docXMLIaPozEvaluari ='<row id_evaluare="'+rtrim(convert(varchar(6),@id_evaluare))+'" tip="'+rtrim(@tip)+'"/>'
	exec wRUIaPozEvaluari @sesiune=@sesiune, @parXML=@docXMLIaPozEvaluari
end
end try

begin catch
	set @eroare='(wRUScriuPozEvaluari) '+char(10)+rtrim(ERROR_MESSAGE())
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsPozEval' and session_id=@@SPID )
if @cursorStatus=1 
	close crsPozEval 
if @cursorStatus is not null 
	deallocate crsPozEval

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
--
if len(@eroare)>0
	raiserror(@eroare,16,1)
