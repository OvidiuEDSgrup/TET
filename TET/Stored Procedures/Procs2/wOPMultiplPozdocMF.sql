--***
create procedure wOPMultiplPozdocMF @sesiune varchar(50), @parXML xml          
as 
begin try
declare @sub varchar(9),@tip varchar(2),@subtip varchar(2),@numar varchar(8),@data datetime,
	@nrinv varchar(13), @procinch int, @lunabloc int,@anulbloc int, @databloc datetime, 
	@eroare varchar(254), @userASiS varchar(10), @cant int, @nrinv_string varchar(13), @increment int, 
	@pozitie float, @nrinv_numeric int, @nrinv_sufix varchar(13), @tipPozdoc varchar(2)

--exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPMultiplPozdocMF'
	
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

select
	@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''),  
	@subtip=ISNULL(@parXML.value('(/parametri/row/@subtip)[1]', 'varchar(2)'), ''),          
	@numar=ISNULL(@parXML.value('(/parametri/row/@numar)[1]', 'varchar(8)'), ''),     
	@data=ISNULL(@parXML.value('(/parametri/row/@data)[1]', 'datetime'), '01/01/1901'),
	@nrinv = ISNULL(@parXML.value('(/parametri/row/@nrinv)[1]', 'varchar(13)'), ''), 
	@procinch=ISNULL(@parXML.value('(/parametri/row/@procinch)[1]', 'int'), 0),  
	@cant=ISNULL(@parXML.value('(/parametri/@cant)[1]', 'int'), 0), 
	@nrinv_numeric = ISNULL(@parXML.value('(/parametri/@nrinv_start)[1]', 'int'), 0), 
	@nrinv_sufix = ISNULL(@parXML.value('(/parametri/@nrinv_sufix)[1]', 'varchar(13)'), '') 

	set @cant=ROUND(@cant,0)

set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)
set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)
if @lunabloc not between 1 and 12 or @anulbloc<=1901 
	set @databloc='01/01/1901' 
else 
	set @databloc=dbo.EOM(convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))

if isnull(@nrinv,'')=''
	raiserror('Operatia se poate da doar la nivel de pozitie document!',11,1)
		
if @data<=@databloc
	raiserror('Operatia nu se poate da pe o luna inchisa!',11,1)	
	
if @tip<>'MI' 
	raiserror('Se pot multiplica doar intrarile!',11,1)
		
if isnumeric(@nrinv)=0 --and @tip='MI' 
	and @nrinv_numeric= 0 
		raiserror('Nr. de inventar multiplicat trebuie sa contina doar cifre!',11,1)
		
if isnull(@cant,0)<1
	raiserror('Trebuie sa introduceti o cantitate semnificativa!',11,1)
begin tran multiplicMF
if 	@nrinv_numeric=0 and isnumeric(@nrinv)=1
	set @nrinv_numeric=cast(@nrinv as int)
	
set @increment=1
set @tipPozdoc=(case when @subtip='AF' then 'RM' else 'AI' end)
set @pozitie= isnull((select max(numar_pozitie) from pozdoc where subunitate=@sub and tip=@tipPozdoc and numar=@numar and data=@data),0)
WHILE @increment<=@cant
begin
	set @increment=@increment+1
	set @nrinv_string=ltrim(str(@nrinv_numeric))+@nrinv_sufix
	--VERIFIC EXISTENTA 
	while exists (select 1 from mfix where numar_de_inventar = @nrinv_string)
	begin
		set @nrinv_numeric=@nrinv_numeric+1
		set @nrinv_string=ltrim(str(@nrinv_numeric))+@nrinv_sufix
	end
	set @nrinv_numeric=@nrinv_numeric+1

	--MISMF
	insert into mismf (Subunitate,Data_lunii_de_miscare,Numar_de_inventar,Tip_miscare,Numar_document,
	Data_miscarii,Tert,Factura,Pret,TVA,Cont_corespondent,Loc_de_munca_primitor,Gestiune_primitoare,
	Diferenta_de_valoare,Data_sfarsit_conservare,Subunitate_primitoare,Procent_inchiriere)
	--values (':1',':2',ltrim(str(@nrinvnou)),':4',':5',':6',':7',':8',:9,:10,':11',':73', ':13',:14,':15',':16',:17)
	select Subunitate,Data_lunii_de_miscare,@nrinv_string,Tip_miscare,Numar_document,
	Data_miscarii,Tert,Factura,Pret,TVA,Cont_corespondent,Loc_de_munca_primitor,Gestiune_primitoare,
	Diferenta_de_valoare,Data_sfarsit_conservare,Subunitate_primitoare,Procent_inchiriere
	FROM mismf where Numar_de_inventar=@nrinv and (Tip_miscare=RIGHT(@tip,1)+@subtip --and Numar_document=@numar 
	or Data_miscarii<@data)

	--MFIX
	insert into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,Tip_amortizare,Cod_de_clasificare,
	Data_punerii_in_functiune,detalii)
	--values (':1',ltrim(str(@nrinvnou)),':18',':19',':20',':21',':22')
	select Subunitate,@nrinv_string,Denumire,Serie,Tip_amortizare,Cod_de_clasificare,
	Data_punerii_in_functiune,detalii
	FROM mfix where Numar_de_inventar=@nrinv 

	--FISAMF - tb. 2 insert-uri pt. cazul cand nr. de inv. multiplicat are modif. de val. in luna intr.
	INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,Felul_operatiei,Loc_de_munca,
	Gestiune,Comanda,Valoare_de_inventar,Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
	Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,Obiect_de_inventar, 
	Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
	--values (':1',ltrim(str(@nrinvnou)),':28',':2','3',':12',':43',':29',:30,:31,:32,:33,:34,:35,:36,:37,':38',':39',:40,:41)
	select Subunitate,@nrinv_string,Categoria,Data_lunii_operatiei,Felul_operatiei,Loc_de_munca,
	Gestiune,Comanda,Valoare_de_inventar,Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
	Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,Obiect_de_inventar, 
	Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli
	FROM fisaMF where Numar_de_inventar=@nrinv and (Felul_operatiei='3' or Data_lunii_operatiei<@data)

	INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,Felul_operatiei,Loc_de_munca,
	Gestiune,Comanda,Valoare_de_inventar,Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
	Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,Obiect_de_inventar, 
	Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
	--values (':1',ltrim(str(@nrinvnou)),':28',':2','3',':12',':43',':29',:30,:31,:32,:33,:34,:35,:36,:37,':38',':39',:40,:41)
	select Subunitate,@nrinv_string,Categoria,Data_lunii_operatiei,'1',Loc_de_munca,
	Gestiune,Comanda,Valoare_de_inventar,Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
	Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,Obiect_de_inventar, 
	Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli
	FROM fisaMF where Numar_de_inventar=@nrinv and Felul_operatiei='3' 
	--and Data_lunii_operatiei=dbo.EOM(@data)

	--POZDOC SI FACTURI - insertul in pozdoc tb. sa fie dupa insertul in mfix
	SET @pozitie=@pozitie+1
	INSERT into pozdoc (subunitate,tip,numar,cod,data,gestiune,cantitate,
	pret_valuta,pret_de_stoc,adaos,pret_vanzare,pret_cu_amanuntul,tva_deductibil,cota_tva,
	utilizator,data_operarii,ora_operarii,cod_intrare,cont_de_stoc,cont_corespondent,
	tva_neexigibil,pret_amanunt_predator,tip_miscare,locatie,data_expirarii,
	numar_pozitie,loc_de_munca,comanda,barcod,cont_intermediar,cont_venituri,
	discount,tert,factura,gestiune_primitoare,numar_dvi,stare,grupa,cont_factura, valuta, curs, data_facturii, 
	data_scadentei, procent_vama, suprataxe_vama, accize_cumparare, accize_datorate, contract, jurnal)
	select /*':1', ':74', ':5', ':44', ':6', ':43', 1, :45, :9, :46, :47, :48, :10, :49, ':50', getdate(), ':51', 
	ltrim(str(@nrinvnou)), ':39', ':11', :52, :53, 'I', ':54', ':55', @pozitie, ':12', ':29', ':56', ':57', ':58', :59, 
	':7', ':8', ':60', ':61', :62, ':63', ':11', ':64', :65, ':66', ':15', :67, :68, :69, :70, ':71', ':72' */ 
	subunitate,tip,numar,cod,data,gestiune,cantitate,
	pret_valuta,pret_de_stoc,adaos,pret_vanzare,pret_cu_amanuntul,tva_deductibil,cota_tva, @userASiS, 
	convert(datetime,convert(char(10),getdate(),104),104), RTrim(replace(convert(char(8),getdate(),108),':','')), 
	@nrinv_string,cont_de_stoc,cont_corespondent,
	tva_neexigibil,pret_amanunt_predator,tip_miscare,locatie,data_expirarii,
	@pozitie,loc_de_munca,comanda,barcod,cont_intermediar,cont_venituri,
	discount,tert,factura,gestiune_primitoare,numar_dvi,5/*stare*/,grupa,cont_factura, valuta, curs, data_facturii, 
	data_scadentei, procent_vama, suprataxe_vama, accize_cumparare, accize_datorate, contract, jurnal 
	FROM pozdoc 
	WHERE @procinch=6 and subunitate=@sub and tip=@tipPozdoc
	and numar=@numar and data=@data and cod_intrare=@nrinv --and factura=right(...
	/*UPDATE facturi set valoare=valoare+:9, tva_22=tva_22+:10, sold=sold+:9+:10 WHERE ':4'='IAF' and :17<>6 
	and tip=0x54 and factura=':8' and data=':6' and tert=':7'*/
	exec faInregistrariContabile @dinTabela=0, @subunitate=@sub, @tip=@tipPozdoc,@numar=@numar,@data=@data
end
commit tran multiplicMF
/*if exists (select Numar from pozdoc where Subunitate = @sub and pozdoc.tip=@tips and Numar = @numars and Data=@datastorno)
	select 'S-a multiplicat mijlocul fix cu nr. de inv. '+rtrim(@numars)+' din data '+convert(char(10),@datastorno,103) as textMesaj for xml raw, root('Mesaje')
else
	raiserror('Din anumite motive nu s-a multiplicat mijlocul fix! ',11,1)*/
end try 
begin catch  
	set @eroare=ERROR_MESSAGE()
	if EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'multiplicMF')
		ROLLBACK TRAN multiplicMF
	raiserror(@eroare, 11, 1) 		
end catch
