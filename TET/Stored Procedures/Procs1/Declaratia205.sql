--***
Create procedure Declaratia205
	@dataJos datetime, 
	@dataSus datetime,
	@tipdecl int,	-- TipDeclaratie=0 Initiala, 1 Rectificativa
	@tipVenit char(2),	-- cuprinde valori din lista prevazuta in legislatie
	@ticheteInVenitBrut int,	-- stabileste cumularea valorii tichetelor de masa in venitul brut
	@contImpozit char(30), @contFactura char(30), @contImpozitDividende char(30), 
	@lm char(9), @strict int,
	@nume_declar varchar(200), @prenume_declar varchar(200), @functie_declar varchar(100), 
	@dinRia int=1,	-->	par care determina modul de scriere pe harddisk
	@cDirector varchar(254), --cale generare fisier TXT
	@sirDeMarci varchar(1000)=null --filtrare dupa sir de marci, pentru cazul declaratiei rectificative
as  
Begin try
--	a fost la inceput parametru (dupa @tipVenit) TipImpozit=1 Plata anticipata, 2 Impozit final
--	(am renuntat in 2012 cand se genereaza un singur fisier pt. toate tipurile de venit)
	declare @continutXml xml, @continutXmlChar varchar(max), @an int, 
	@numeFisier varchar(max), @cFisier varchar(254), @raspunsCmd int, @msgeroare varchar(1000), @parXML xml, 
	@cui varchar(13), @den varchar(200), @adresa varchar(1000), @telefon varchar(15), @fax varchar(15), @mail varchar(200)

	select 
		@den=max(case when parametru='NUME' then rtrim(val_alfanumerica) else '' end),
		@telefon=max(case when parametru='TELFAX' then rtrim(val_alfanumerica) else '' end),
		@fax=max(case when parametru='FAX' then rtrim(val_alfanumerica) else '' end),
		@mail=max(case when parametru='EMAIL' then rtrim(val_alfanumerica) else '' end)
	from par where tip_parametru='GE' and parametru in ('NUME','TELFAX','FAX','EMAIL')
	select @fax=@telefon where @fax=''
--	citesc cod fiscal salarii, daca este necompletat il citesc pe cel general
	select @cui=dbo.iauParA('PS','CODFISC')
	if @cui=''
		set @cui=dbo.iauParA('GE','CODFISC')
	set @cui=rtrim(ltrim(replace(replace(@cui,'RO',''),'R','')))
	
	select @adresa=max(case when rtrim(val_alfanumerica)<>'' and parametru='LOCALIT' then 'Localitatea '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='STRADA' then 'str '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='NUMAR' then 'nr '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='BLOC' then 'bl '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='SCARA' then 'sc '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='ETAJ' then 'etaj '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='APARTAM' then 'ap '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='JUDET' then 'jud '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_numerica)<>0 and parametru='CODPOSTAL' then 'cod postal '+rtrim(convert(char(20),val_numerica))+' ' else '' end)
		+max(case when rtrim(val_numerica)<>0 and parametru='SECTOR' then 'sector '+rtrim(convert(char(20),val_numerica))+' ' else '' end)
	from par where tip_parametru='PS' and parametru in ('LOCALIT','STRADA','NUMAR','BLOC','SCARA','ETAJ','APARTAM','JUDET','CODPOSTAL','SECTOR')
	
	select @an=year(@dataSus)

--	salvare declaratie ca fisier XML pt. an >= 2012 / TXT pt. an < 2012
	set @numeFisier = 'D205_'+convert(char(4),@an)+'_'+(case when @tipdecl=0 then 'I' else 'R' end)+'_'+@cui+(case when @an>=2012 then '.xml' else '.txt' end)
	set @cFisier=rtrim(@cDirector)+@numeFisier

	if object_id('tempdb..#date') is not null drop table #date
	if object_id('tempdb..#tipvenit') is not null drop table #tipvenit
	if object_id('tempdb..##tmpdeclTXT') is not null drop table ##tmpdeclTXT
	if object_id('tempdb..##tmpdeclXML') is not null drop table ##tmpdeclXML
	if object_id('tempdb..#net') is not null drop table #net

	select top 0 Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
		Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
		CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
		VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec
	into #net from net where data between @datajos and @datasus
	create unique index [Data_Marca] ON #net (Data, Marca)
	set @parXML=(select @dataJos datajos, @dataSus datasus, 'LR' lunaApelare, @lm lm for xml raw)
--	insert into #net
--	tabela #net se completeaza in procedura NetCuRectificari
	exec NetCuRectificari @parXML

--	inserez datele returnate de procedura rapDeclaratia205
	create table #date
		(data datetime, tip_venit char(2), denumire varchar(1000), nr_ben int, tip_salar char(1), tip_impozit char(1), CNP varchar(13), nume varchar(200), tip_functie char(1), 
		venit_brut decimal(10), deduceri_personale decimal(10), deduceri_alte decimal(10), baza_impozit decimal(10), impozit decimal(10), venit_net decimal(10), 
		detalii varchar(max), ordonare varchar(100))
	insert into #date
	exec rapDeclaratia205 @dataJos=@dataJos, @dataSus=@dataSus, @tipdecl=@tipdecl, @tipVenit=@tipVenit, @ticheteInVenitBrut=@ticheteInVenitBrut, 
		@contImpozit=@contImpozit, @contFactura=@contFactura, @contImpozitDividende=@contImpozitDividende, @lm=@lm, @strict=@strict, @sirDeMarci=@sirDeMarci
	
	select tip_venit, count(0) as nrben, sum(baza_impozit) as baza_impozit, sum(impozit) as impozit
	into #tipvenit
	from #date
	group by Tip_venit
	
	if @an>=2012
	Begin	
		select @continutXml=(
			select 'mfp:anaf:dgti:d205:declaratie:v1' as [@ptxmlns]
				,12 as [@luna], @an as [@an], @tipdecl as [@d_rec]
				,rtrim(@nume_declar) [@nume_declar], rtrim(@prenume_declar) [@prenume_declar], rtrim(@functie_declar) [@functie_declar]
				,@cui [@cui], rtrim(@den) [@den], rtrim(@adresa) [@adresa], @telefon [@telefon], @fax [@fax], (case when @mail<>'' then rtrim(@mail) end) [@mail]
				,(select sum(nrben+baza_impozit+impozit) from #tipvenit) [@totalPlata_A]
				,(select tip_venit [@tip_venit], nrben [@nrben], 0 [@Tcastig], 0 [@Tpierd], 
					baza_impozit [@Tbaza], impozit [@Timp] from #tipvenit for xml path('sect_II'),type)
				,(select (case when @an>=2013 then ROW_NUMBER() over (order by nume) end) as [@id_inreg]
					,tip_venit [@tip_venit1], rtrim(nume) [@den1], cnp [@cif1]
					,(case when @an>=2013 and tip_venit='07' then (case when tip_salar='' then 1 else tip_salar end) end) as [@tip_salAB]
					,tip_impozit [@tip_plata], (case when tip_functie<>'' then tip_functie end) [@tip_functie]
					,(case when tip_venit='07' then venit_brut end) [@vbrut], (case when tip_venit='07' then deduceri_personale end) [@dedu_pers]
					,(case when tip_venit='07' then deduceri_alte end) [@dedu_alte] 
					,baza_impozit [@baza1], impozit [@imp1] from #date for xml path('benef'),type)
			for xml path('declaratie205'), type)
		select @continutXmlChar='<?xml version="1.0"?>'+char(10)+replace(convert(varchar(max),@continutXml),'ptxmlns','xmlns')
--	salvez declaratia ca si continut in tabela declaratii
		if exists (select * from sysobjects where name ='scriuDeclaratii' and xtype='P')
			exec scriuDeclaratii @cod='205', @tip=@tipdecl, @data=@dataSus, @continut=@continutXmlChar
	End
	else
	Begin
		set @continutXmlChar=''
		select @continutXmlChar=@continutXmlChar+rtrim(Detalii)+char(10) from #date
	End

	if @dinRia=1 /* daca @dinRia trimit fisierul pt. salvarea lui din Flex/AIR */
	begin 
		exec SalvareFisier @continutXmlChar, @cDirector, @numeFisier
	--	select @continutXmlChar as document, @numeFisier as fisier, '' as nrFactura, 'wTipFormular' as numeProcedura for xml raw 
	end 
	else 
	begin /* altfel, il salvez in tabela temporara si apoi cu bcp in un fisier pe disk */
		if @an>=2012
			select @continutXmlChar as coloana into ##tmpdeclXML
		else
			select Detalii as Coloana into ##tmpdeclTXT from #date
			
		declare @nServer varchar(1000), @comandaBCP varchar(4000) /* comanda trebuie sa ramana varchar(4000) sau mai mica... */
		set @nServer=convert(varchar(1000),serverproperty('ServerName'))
		if @an>=2012
			set @comandaBCP='bcp "select rtrim(coloana) from ##tmpdeclXML'+'" queryout "'+@cFisier+'"  -T -c -r -t -C UTF-8 -S '+@nServer
		else	
			set @comandaBCP='bcp "select rtrim(coloana) from ##tmpdeclTXT'+'" queryout "'+@cFisier+'" -T -c -t -C ACP -S '+@nServer	

		exec @raspunsCmd = xp_cmdshell @comandaBCP
--	select @raspunsCmd, @comandaBCP
		if @raspunsCmd != 0 /* xp_cmdshell returneaza 0 daca nu au fost erori, sau altfel, codul de eroare */
		begin
			set @msgeroare = 'Eroare la scrierea formularului pe hard-disk in locatia: '+ ( 
				case len(@cFisier) when 0 then 'NEDEFINIT' else @cFisier end )
			raiserror (@msgeroare ,11 ,1)
		end
		else	/* trimit numele fisierului generat */ 
		begin
			select @numeFisier as fisier, 'wTipFormular' as numeProcedura for xml raw -- legacy, de eliminat in timp
			select @numeFisier as fisier, 'wTipFormular' as numeProcedura for xml raw, root('Mesaje')
		end
	end
	if object_id('tempdb..#date') is not null drop table #date
	if object_id('tempdb..#tipvenit') is not null drop table #tipvenit
	if object_id('tempdb..##tmpdeclTXT') is not null drop table ##tmpdeclTXT
	if object_id('tempdb..##tmpdeclXML') is not null drop table ##tmpdeclXML
	if object_id('tempdb..#net') is not null drop table #net	
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura Declaratia205 (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec Declaratia205 '01/01/2012', '12/31/2012', 0, '', 1, Null, Null, Null, 0, 'TONCA', 'MARIA', 'DIRECTOR ECONOMIC', 0, 'D:\Fisiere\'
*/
