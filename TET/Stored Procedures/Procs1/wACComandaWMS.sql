/***--
Procedura de AutoComplete care cauta in comenzile existente si sugereaza in functie de ce s-a tastat si
din ce tip de macheta se face interogarea.
	
param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@tip		->	Tipul machetei curente (se citeste si trimite mai departe pentru
									identificare in Forms)
					@searchText	->	Textul pe care se face sugestia
					@tert		->	Tertul pe care se cauta comenzile de aprovizionare
--***/
create procedure wACComandaWMS @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists(select * from sysobjects where name='wACComandaWMSSP' and type='P')      
begin
	exec wACComandaWMSSP @sesiune, @parXML
	return 0
end

declare @tip varchar(2), @searchText varchar(80), @tipContr varchar(2), @tert varchar(50), @mesaj varchar(500), @comenziOld xml, @comenziNoi xml,
		@sub varchar(50)
		
begin try
	/*Preia parametrii XML trimisi */
	select	@searchText=replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),' ','%'),
			@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
			@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(50)'), '')

	-- tratare comenzi livrare cu tabele vechi (con/pozcon)
	IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[con]') AND type in (N'U'))
	begin
		/*Seteaza tipul de comanda cautata in functie de tipul machetei din care s-a fauct interogarea.
		Nu se foloseste in Preluare Dispozitii, tipul fiind ID (Import Dispozitii) adica totdeauna 'FC'. */
		set @tipContr=(case
							when @tip='BK' then 'BF'
							when @tip='FC' then 'FA'
							when @tip in ('AP', 'AS', 'TE') then 'BK'
							else 'FC'
						end)

		/*Returneaza contractul ca element principal, tertul ca info, si explicatii ca denumire */
		set @comenziOld=
			(select rtrim(c.contract) as cod, rtrim(c.tert) as info,
					(	case
							when c.explicatii='' then 'Com. pt. '+rtrim(t.Denumire) +' din '+
									rtrim(convert(char(10),c.Data,103))
							else rtrim(c.explicatii)
						end) as denumire
				from con c
				left join terti t on t.Subunitate=c.Subunitate and  t.Tert = c.Tert
				where c.Subunitate = '1' and c.tip=@tipContr and
					(@tert = '' or c.Tert = @tert)
					and (rtrim(c.contract) like @searchText+'%'
						or rtrim(c.explicatii) like '%'+@searchText+'%'
						or rtrim(t.Denumire) like '%'+@searchText+'%')
			for xml raw)
	end
	
	-- tratare comenzi livrare cu tabele noi
	IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.contracte') AND type in (N'U'))
	begin
		exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
		/*Returneaza contractul ca element principal, tertul ca info, si explicatii ca denumire */
		set @comenziNoi=
			(select rtrim(c.idContract) as cod, rtrim(c.tert) as info,
					(	case
							when c.explicatii='' then 'Com. pt. '+rtrim(t.Denumire) +' din '+
									rtrim(convert(char(10),c.Data,103))
							else rtrim(c.explicatii)
						end) as denumire
				from Contracte c
				left join terti t on t.Subunitate=@sub and  t.Tert = c.Tert
				where c.tip='CA' and
					(@tert = '' or c.Tert = @tert)
					and (rtrim(c.numar) like @searchText+'%'
						or rtrim(c.explicatii) like '%'+@searchText+'%'
						or rtrim(t.Denumire) like '%'+@searchText+'%')
			for xml raw)
	end

	select @comenziOld, @comenziNoi
	for xml path('')
end try
begin catch
	set @mesaj = '(wOPImportDispozitiiAW)'+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch


--select * from AntDisp
--select * from PozDispOp
--delete from pozdispop where idpoz > 1
--select p.* from pozCon p where tip = 'fc' and subunitate = '1'
--select * from con where tip = 'fc'
--select * from terti
--select * from pozdoc where subunitate = '1' and tip = 'rm'
/* <tip()> <contract(numarDocumentSursa identifica unic comanda)> */
