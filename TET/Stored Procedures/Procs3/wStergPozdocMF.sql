--***
create procedure [dbo].[wStergPozdocMF] @sesiune varchar(50), @parXML xml
as

declare @modimpl int, @sub char(9), @datal datetime, @tip char(2), @nrinv char(13), @procinch int, @tipdocCG char(2), @data datetime, @numar varchar(8), 
	@farapozdoc int, @iDoc int, @eroare xml, @binar varbinary(128) 

begin try
	exec luare_date_par 'MF', 'IMPLEMENT', @modimpl output, 0, ''
		
	set @sub=isnull(@parXML.value('(/row/row/@sub)[1]','char(9)'),'')
	set @datal=isnull(@parXML.value('(/row/@datal)[1]','datetime'),'01/01/1901')
	set @tip=isnull(@parXML.value('(/row/@tip)[1]','char(2)'),'')
	set @tipdocCG=isnull(@parXML.value('(/row/row/@tipdocCG)[1]','char(2)'),'')
	set @numar=isnull(@parXML.value('(/row/row/@numar)[1]','varchar(8)'),'')
	set @data=isnull(@parXML.value('(/row/row/@data)[1]','datetime'),'01/01/1901')
	set @nrinv=isnull(@parXML.value('(/row/row/@nrinv)[1]','char(13)'),'')
	set @procinch=isnull(@parXML.value('(/row/row/@procinch)[1]','int'),0)
	set @farapozdoc=isnull(@parXML.value('(/row/row/@farapozdoc)[1]','int'),0)

	if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPozdocMFSP')
		exec wStergPozdocMFSP @sesiune, @parXML output
	
	exec sp_xml_preparedocument @iDoc output, @parXML

	set @binar=cast('modificaredocdefinitivMF' as varbinary(128))
	set CONTEXT_INFO @binar

	update fisamf set Cantitate=isnull((select f.Cantitate from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='5' and 
	f.data_lunii_operatiei = dx.datal),0),
	Valoare_de_inventar=isnull((select f.Valoare_de_inventar from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='5' and 
	f.data_lunii_operatiei = dx.datal),0),
	Valoare_amortizata=isnull((select f.Valoare_amortizata from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='5' and 
	f.data_lunii_operatiei = dx.datal),0),
	Valoare_amortizata_cont_8045=isnull((select f.Valoare_amortizata_cont_8045 from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='5' and 
	f.data_lunii_operatiei = dx.datal),0),
	Valoare_amortizata_cont_6871=isnull((select f.Valoare_amortizata_cont_6871 from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='5' and 
	f.data_lunii_operatiei = dx.datal),0)
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  sub char(9) '@sub',
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  data datetime '@data',
	  datal datetime '@datal',
	  nrinv char(13) '@nrinv'
	 ) as dx  
	where dx.tip='ME' and fisamf.subunitate = dx.sub 
	and fisamf.numar_de_inventar = dx.nrinv and fisamf.data_lunii_operatiei = dx.datal
	and felul_operatiei='1'

	update fisamf set gestiune=isnull((select top 1 gestiune_primitoare from mismf where 
	subunitate=dx.sub and numar_de_inventar=dx.nrinv and data_lunii_de_miscare<=dx.datal and 
	tip_miscare='TSE' and data_miscarii<=dx.data-1 order by data_lunii_de_miscare desc),
	isnull((select f.gestiune from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='1' and 
	f.data_lunii_operatiei = dbo.bom(dx.datal)-1),(select fi.gestiune from fisamf fi where 
	fi.subunitate = dx.sub and fi.numar_de_inventar = dx.nrinv and fi.felul_operatiei in ('2','3')))),
	LOC_DE_MUNCA=isnull((select top 1 loc_de_munca_primitor from mismf where 
	subunitate=dx.sub and numar_de_inventar=dx.nrinv and data_lunii_de_miscare<=dx.datal and 
	tip_miscare='TSE' and data_miscarii<=dx.data-1 order by data_lunii_de_miscare desc),
	isnull((select f.loc_de_munca from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='1' and 
	f.data_lunii_operatiei = dbo.bom(dx.datal)-1),(select fi.loc_de_munca from fisamf fi where 
	fi.subunitate = dx.sub and fi.numar_de_inventar = dx.nrinv and fi.felul_operatiei in ('2','3')))),
	COMANDA=isnull((select top 1 convert(char(40),subunitate_primitoare) from mismf where 
	subunitate=dx.sub and numar_de_inventar=dx.nrinv and data_lunii_de_miscare<=dx.datal and 
	tip_miscare='TSE' and data_miscarii<=dx.data-1 order by data_lunii_de_miscare desc),
	isnull((select f.comanda from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='1' and 
	f.data_lunii_operatiei = dbo.bom(dx.datal)-1),(select fi.comanda from fisamf fi where 
	fi.subunitate = dx.sub and fi.numar_de_inventar = dx.nrinv and fi.felul_operatiei in ('2','3'))))
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  sub char(9) '@sub',
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  data datetime '@data',
	  datal datetime '@datal',
	  nrinv char(13) '@nrinv'
	 ) as dx  
	where dx.tip='MT' and dx.subtip='SE' and fisamf.subunitate = dx.sub 
	and fisamf.numar_de_inventar = dx.nrinv and fisamf.data_lunii_operatiei = dx.datal
	and felul_operatiei in ('1','A')

	update fisamf set cont_mijloc_fix=isnull((select f.cont_mijloc_fix from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='1' and 
	f.data_lunii_operatiei = dbo.bom(dx.datal)-1),(select fi.cont_mijloc_fix from fisamf fi where 
	fi.subunitate = dx.sub and fi.numar_de_inventar = dx.nrinv and fi.felul_operatiei in ('2','3')))
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  sub char(9) '@sub',
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  datal datetime '@datal',
	  nrinv char(13) '@nrinv'
	 ) as dx  
	where dx.tip='MM' and dx.subtip in ('MF','TO') and fisamf.subunitate = dx.sub 
	and fisamf.numar_de_inventar = dx.nrinv and fisamf.data_lunii_operatiei = dx.datal
	and felul_operatiei='1'/*<>'A'*/

	update mfix set cod_de_clasificare=(case when 0=0 or dx.subtip='MF' then dx.contgestprim 
	else (case when dx.contamcomprim='' then dx.tert else dx.contamcomprim end) end)
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  nrinv char(13) '@nrinv',
	  contamcomprim varchar(40) '@contamcomprim',
	  contgestprim varchar(40) '@contgestprim',
	  tert char(13) '@tert',
	  procinch int '@procinch'
	 ) as dx  
	where dx.tip='MM' and dx.subtip in ('MF','TO') and not (dx.subtip='MF' and dx.procinch=3)
	--and (dx.subtip<>'MF' or left(dx.contamcomprim,1)<>'8')
	and mfix.subunitate = 'DENS' and mfix.numar_de_inventar = dx.nrinv 

	update fisamf set obiect_de_inventar=isnull((select f.obiect_de_inventar from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='1' and 
	f.data_lunii_operatiei = dbo.bom(dx.datal)-1),(select fm.obiect_de_inventar from fisamf fm where 
	fm.subunitate = dx.sub and fm.numar_de_inventar = dx.nrinv and fm.felul_operatiei in ('2','3')))
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  sub char(9) '@sub',
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  datal datetime '@datal',
	  nrinv char(13) '@nrinv'
	 ) as dx  
	where dx.tip='MM' and dx.subtip='MF' and fisamf.subunitate = dx.sub 
	and fisamf.numar_de_inventar = dx.nrinv and fisamf.data_lunii_operatiei = dx.datal

	UPDATE fisamf set Valoare_de_inventar=Valoare_de_inventar-dx.difvalinv, 
	Valoare_amortizata=Valoare_amortizata-dx.pret, 
	Valoare_amortizata_cont_8045=Valoare_amortizata_cont_8045-(case when dx.subtip='FF' 
		then 0 else dx.sumatva end)
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  sub char(9) '@sub',
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  datal datetime '@datal',
	  nrinv char(13) '@nrinv',
	  difvalinv decimal(17,2) '@difvalinv',
	  pret decimal(17,2) '@pret',
	  sumatva decimal(17,2) '@sumatva'
	 ) as dx  
	where dx.tip='MM' and dx.sub<>'DENS' and fisamf.subunitate = dx.sub 
	and fisamf.numar_de_inventar = dx.nrinv and fisamf.data_lunii_operatiei = dx.datal
	and felul_operatiei='1' and dx.datal=ISNULL((select data_lunii_operatiei from fisamf where 
	subunitate=dx.sub and numar_de_inventar=dx.nrinv and felul_operatiei='3'),'01/01/1901')

	/*update fisamf set Durata=isnull((select f.Durata from fisamf f where 
	f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='1' and 
	f.data_lunii_operatiei = dbo.bom(dx.datal)-1),(select fm.Durata from fisamf fm where 
	fm.subunitate = dx.sub and fm.numar_de_inventar = dx.nrinv and fm.felul_operatiei in ('2','3')))
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  sub char(9) '@sub',
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  datal datetime '@datal',
	  nrinv char(13) '@nrinv'
	 ) as dx  
	where dx.tip='MM' and dx.subtip not in ('MA','TO','TP') and fisamf.subunitate = dx.sub 
	and fisamf.numar_de_inventar = dx.nrinv and fisamf.data_lunii_operatiei = dx.datal

	update fisamf set Numar_de_luni_pana_la_am_int=isnull((select f.Numar_de_luni_pana_la_am_int from 
	fisamf f where f.subunitate = dx.sub and f.numar_de_inventar = dx.nrinv and f.felul_operatiei='1' and 
	f.data_lunii_operatiei = dbo.bom(dx.datal)-1),(select fm.Numar_de_luni_pana_la_am_int from fisamf fm 
	where fm.subunitate = dx.sub and fm.numar_de_inventar = dx.nrinv and fm.felul_operatiei in ('2','3')))-1
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  sub char(9) '@sub',
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  datal datetime '@datal',
	  nrinv char(13) '@nrinv'
	 ) as dx  
	where dx.tip='MM' and dx.subtip not in ('MA','TO','TP') and fisamf.subunitate = dx.sub 
	and fisamf.numar_de_inventar = dx.nrinv and fisamf.data_lunii_operatiei = dx.datal

	update fisamf set Numar_de_luni_pana_la_am_int=0
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  sub char(9) '@sub',
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  datal datetime '@datal',
	  nrinv char(13) '@nrinv'
	 ) as dx  
	where dx.tip='MM' and dx.subtip not in ('MA','TO','TP') and fisamf.subunitate = dx.sub 
	and fisamf.numar_de_inventar = dx.nrinv and fisamf.data_lunii_operatiei = dx.datal 
	and Numar_de_luni_pana_la_am_int<0
	*/
	update mfix set serie=''
	from OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  tip char(2) '@tip',
	  subtip char(2) '@subtip',
	  nrinv char(13) '@nrinv'
	 ) as dx  
	where dx.tip='MM' and dx.subtip='TO' and mfix.subunitate = 'DENS' 
	and mfix.numar_de_inventar = dx.nrinv

	delete pozdoc
	from pozdoc p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			sub char(9) '@sub', 
			tip char(2) '@tip', 
			tipdocCG char(2) '@tipdocCG', 
			numar char(8) '@numar', 
			data datetime '@data', 
			procinch int '@procinch', 
			nrinv char(13) '@nrinv'
		) as dx
	where dx.procinch=6 and dx.tip in ('MI','MM','ME','MT') 
	and p.subunitate = dx.sub and p.Tip = (case when dx.tip='MT' then 'AI' else dx.tipdocCG end)
	and p.Numar = dx.numar and p.Data = dx.data 
	and p.Cod_intrare = dx.nrinv and p.Jurnal='MFX'

	delete doc
	from doc p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			sub char(9) '@sub', 
			tip char(2) '@tip', 
			tipdocCG char(2) '@tipdocCG', 
			numar char(8) '@numar', 
			data datetime '@data', 
			procinch int '@procinch'
		) as dx
	where dx.procinch=6 and dx.tip in ('MI','MM','ME','MT') 
	and p.subunitate = dx.sub and p.Tip = (case when dx.tip='MT' then 'AI' else dx.tipdocCG end)
	and p.Numar = dx.numar and p.Data = dx.data 
	and p.numar_pozitii=0 and p.Jurnal='MFX'

	delete mismf
	from mismf p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			tip char(2) '@tip', 
			nrinv char(13) '@nrinv'
		) as dx
	where p.subunitate = 'DENS' and right(dx.tip,1)='I' and p.Numar_de_inventar = dx.nrinv

	delete mismf
	from mismf p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			sub char(9) '@sub', 
			tip char(2) '@tip', 
			subtip char(2) '@subtip', 
			numar char(8) '@numar', 
			data datetime '@data', 
			nrinv char(13) '@nrinv'
		) as dx
	where p.subunitate = dx.sub and p.Tip_miscare = right(dx.tip,1)+dx.subtip 
	and p.Numar_document = dx.numar and p.Data_miscarii = dx.data 
	and p.Numar_de_inventar = dx.nrinv

	delete fisaMF
	from fisaMF p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			tip char(2) '@tip', 
			nrinv char(13) '@nrinv'
		) as dx
	where p.subunitate = 'DENS' and right(dx.tip,1)='I' and p.Numar_de_inventar = dx.nrinv

	delete fisamf
	from fisamf p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			sub char(9) '@sub', 
			tip char(2) '@tip', 
			datal datetime '@datal', 
			nrinv char(13) '@nrinv'
		) as dx
	where p.subunitate = dx.sub 
	and p.Numar_de_inventar = dx.nrinv
	and (dx.tip='MI' or p.Felul_operatiei = (case dx.tip when 'MM' then '4' 
	when 'ME' then '5' when 'MT' then '6' when 'MC' then '7' when 'MS' then '8' else '9' end)
	and p.Data_lunii_operatiei = dx.datal) and (dx.tip not in ('MM','MT') or not exists (select 
	1 from misMF mm where mm.subunitate=dx.sub and mm.numar_de_inventar=dx.nrinv and 
	mm.Data_lunii_de_miscare=dx.datal and left(mm.Tip_miscare,1)=RIGHT(dx.tip,1)))

	delete mfix
	from mfix p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			tip char(2) '@tip', 
			nrinv char(13) '@nrinv'
		) as dx
	where right(dx.tip,1)='I' and p.Numar_de_inventar = dx.nrinv

	delete anexadoc
	from anexadoc p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			sub char(9) '@sub', 
			tip char(2) '@tip', 
			subtip char(2) '@subtip', 
			numar char(8) '@numar', 
			data datetime '@data'
		) as dx
	where @farapozdoc=0 and right(dx.tip,1)='I' and p.subunitate = dx.sub and p.Numar = dx.numar and p.Data = dx.data 
	and p.tip=(case right(dx.tip,1)+dx.subtip when 'IAF' then '1' when 'IPF' then '2' 
	when 'IPP' then '3' when 'IDO' then '4' when 'IAS' then '5' when 'ISU' then '6' 
	when 'IAL' then '7' else right(dx.tip,1)+Left(dx.subtip,1) end)

	delete proprietati
	from proprietati p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			tip char(2) '@tip', 
			nrinv char(13) '@nrinv'
		) as dx
	where right(dx.tip,1)='I' and p.tip='MFIX' and p.cod = dx.nrinv

	IF @modimpl=0 and (@tip='MM' and @sub<>'DENS' or @tip='MT' or @tip='MC') 
		EXEC MFcalclun @datal=@datal, @nrinv=@nrinv, @categmf=0, @lm=''

	exec sp_xml_removedocument @iDoc 

	IF @tip in ('MI','MM','ME','MT') and @procinch=6 and @farapozdoc=0
	begin
		exec faInregistrariContabile @dinTabela=0,@Subunitate=@sub, @Tip=@tipDocCG, @Numar=@numar, @Data=@data
	end
				
	--select 'ok' as msg for xml raw
	if @farapozdoc=0
		exec wIaPozdocMF @sesiune=@sesiune, @parXML=@parXML

	set CONTEXT_INFO 0x00

end try
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	--if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	set @mesaj=ERROR_MESSAGE() + ' (wStergPozdocMF)'
	raiserror(@mesaj, 11, 1)
	--select @eroare FOR XML RAW
end catch
