--***
create procedure wScriuDiurne @sesiune varchar(50), @parXML xml 
as 

declare @subunitate varchar(20),@eroare xml,@lmproprietate varchar(20),@utilizator varchar(50),@lm varchar(9) 
--
begin try
		
	if app_name() not like '%unipaas%'
		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT  
	else
		select top 1 @Utilizator=rtrim(utilizator) from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
		
	exec luare_date_par 'GE','SUBPRO', 0,0,@Subunitate output

	set @lmproprietate=isnull((select max(l.cod) from lmfiltrare l where l.utilizator=@utilizator),'')
		
--> citire si organizare parametri:
	if OBJECT_ID('tempdb..#diurneXML') is not null drop table #diurneXML	
CREATE TABLE [dbo].[#diurneXML](
	[Tip] [varchar](2),
	[Subtip] [varchar](2),
	[Loc_de_munca] [varchar](9),
	[Marca] [varchar](6),
	[Data_inceput] [datetime],
	[Data_sfarsit] [datetime],
	[Zile] [int],
	[Tara] [varchar](20),
	[Valuta] [varchar](3),
	[Tip_diurna] [varchar](1),
	[Curs] [float],
	[Detalii] [xml],
	[idPozitie] [int],
	_update int
) 

	declare @iDoc int,@rootDoc varchar(20),@multiDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	set @rootDoc='/parametri'

	insert into #diurneXML(tip, subtip, Marca, Data_inceput, Data_sfarsit, Zile, Tara, Valuta, Tip_diurna, Curs, Detalii, idPozitie, _update)
	select tip, subtip, marca, 
		data_inceput, data_sfarsit, 
		isnull(zile, 0) as zile, 
		isnull(tara,'') as tara,
		upper(isnull(valuta,'')) as valuta,
		isnull(tip_diurna,'') as tip_diurna,
		isnull(curs,0) as curs,
		detalii,
		idPozitie, 
		_update
	from OPENXML(@iDoc, @rootDoc)
		WITH 
		(
			tip varchar(2) '@tip', 
			subtip varchar(2) '@subtip', 
			marca varchar(6) '@marca',
			data_inceput datetime '@datainceput',
			data_sfarsit datetime '@datasfarsit',
			zile float '@zile',
			tara varchar(20) '@tara',
			valuta varchar(3) '@valuta',
			tip_diurna char(1) '@tipdiurna',
			curs float '@curs',
			detalii XML 'detalii',
			idPozitie int '@idPozitie',
			_update int '@update'
		)
		exec sp_xml_removedocument @iDoc 

--> prelucrari de date: calcul zile de diurna, daca nu s-au completat. Pot fi cazuri in care sunt jumatati de zile (care se introduc manual).
	update #diurneXML set zile=DateDiff(day,Data_inceput,Data_sfarsit)+1
	where zile=0

--> scrierea propriu-zisa:
	begin tran scdiurne
	if exists (select 1 from #diurneXML where subtip='MD') /*Se va modifica pozitia din tabela diurne*/
	begin
		if (select count(*) from #diurneXML where idPozitie is null)>0
			raiserror('Nu se poate face update fara idPozitie',16,1)

		update diurne
			set marca=isnull(#diurneXML.marca,diurne.marca),
			Data_inceput=isnull(#diurneXML.Data_inceput,diurne.Data_inceput),
			Data_sfarsit=isnull(#diurneXML.Data_sfarsit,diurne.Data_sfarsit),
			Zile=isnull(#diurneXML.zile,diurne.zile),
			Tara=isnull(#diurneXML.Tara,diurne.Tara),
			Valuta=isnull(#diurneXML.Valuta,diurne.Valuta),
			Tip_diurna=isnull(#diurneXML.Tip_diurna,diurne.Tip_diurna),
			Curs=isnull(#diurneXML.curs,diurne.Curs),
			detalii=isnull(#diurneXML.detalii,diurne.detalii)
		from #diurneXML where diurne.idPozitie=#diurneXML.idpozitie
	end
	else 
	Begin
		insert into diurne (loc_de_munca, marca, data_inceput, data_sfarsit, zile, tara, valuta, tip_diurna, curs, detalii)
		select @lm, marca, data_inceput, data_sfarsit, zile, tara, valuta, tip_diurna, curs, detalii
		from #diurneXML 
	End
	commit tran scdiurne

	if exists (select 1 from #diurneXML where subtip='AD')
	Begin
		declare @dateInitializare xml
		set @dateInitializare=@parXML
		SELECT 'Adaugare diurne' nume, 'SL' codmeniu, 'D' tipmacheta, 'DI' tip, 'AD' subtip, 'O' fel,
			(SELECT @dateInitializare ) dateInitializare
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	End
	if OBJECT_ID('tempdb..#diurneXML') is not null drop table #diurneXML
end try

begin catch
	if EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'scdiurne')
		ROLLBACK TRAN scdiurne
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
