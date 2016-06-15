--***  procedura pentru scriere documente de MF operate in CG, in tabelele specifice mijloacelor fixe
create procedure wScriuMFdinCG @sesiune varchar(50), @parXML xml=null
as                  

begin try
	declare @subtip varchar(2), @subunitate char(9), @tip char(2), @numar varchar(20), @data datetime, 
		@tipam char(1), @nrinv varchar(25), @tert varchar(13), @gestiune varchar(9), @tipgestiune char(1), @ptupdate int
	declare @denmf varchar(80), @seriemf varchar(20), @codcl varchar(13), @categmf int, @datapf datetime, @durata int, @nrluni int, 
		@factura varchar(20), @lm varchar(9), @comanda varchar(20), @indbug varchar(20), 
		@contmf varchar(40), @contcor varchar(40), @contam varchar(40), @contcham varchar(40), @numardvi varchar(30), @pretstoc float, @valinv float, @sumatva float, @difvalinv float, @cotatva real, 
		@o_numar varchar(20), @numarpozitie int, @nrpozitie int, @parXMLMF xml, @existaNrinv int, @idpozdoc int

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	select @subtip=isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'), '') 
		,@tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'), '')
		,@numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'), '')
		,@data=isnull(@parXML.value('(/row/@data)[1]','datetime'), '')
		,@numarpozitie=@parXML.value('(/row/row/@numarpozitie)[1]', 'int')
	--	citit idpozdoc intrucat numarpozitie nu mai este inclus in XML in momentul apelarii wScriuMFdinCG.
		,@idpozdoc=@parXML.value('(/row/row/@idpozdoc)[1]', 'int')
		,@ptupdate=isnull(@parXML.value('(/row/row/@update)[1]', 'int'),0)

	--	daca se lucreaza cu wScriuDoc
		if @idpozdoc is null or @numar=''
		Begin
			set @idpozdoc=ISNULL(@parXML.value('(/row/docInserate/row/@idPozDoc)[1]', 'INT'), 0)
			select @tip=tip, @numar=numar, @data=data, @subtip=subtip from pozdoc where idPozdoc=@idPozdoc
		End

	-- intrari de mijloace fixe operate ca RM	
	if @tip='RM' and @subtip='MF'
	begin
		declare tmpMF cursor for 
		select p.cod_intrare, p.detalii.value('(/row/@denmf)[1]', 'varchar(80)') as denmf, p.detalii.value('(/row/@seriemf)[1]', 'varchar(20)') as seriemf, 
			p.detalii.value('(/row/@codcl)[1]', 'char(13)') as codcl, p.detalii.value('(/row/@tipam)[1]', 'char(1)') as tipam, 
			p.detalii.value('(/row/@durata)[1]', 'int') as durata, p.detalii.value('(/row/@nrluni)[1]', 'int') as nrluni, 
			tert, factura, gestiune, loc_de_munca, left(comanda,20) as comanda, substring(Comanda,21,20) as indbug, 
			cont_de_stoc as contmf, cont_factura as contcor, p.detalii.value('(/row/@contam)[1]', 'varchar(40)') as contam, p.detalii.value('(/row/@contcham)[1]', 'varchar(40)') as contcham, 
			Numar_dvi as numardvi, p.pret_de_stoc as pretstoc, cantitate*pret_de_stoc as valinv, TVA_deductibil as sumatva, Cota_TVA, numar_pozitie 
		from pozdoc p
			inner join gestiuni g on g.Subunitate=p.Subunitate and g.Cod_gestiune=p.Gestiune and g.Tip_gestiune='I'
		where p.subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and subtip='MF'
			and (@numarpozitie is null or Numar_pozitie=@numarpozitie)
			and (isnull(@idpozdoc,0)=0 or idPozdoc=@idpozdoc)
	
		open tmpMF
		fetch next from tmpMF into @nrinv, @denmf, @seriemf, @codcl, @tipam, @durata, @nrluni, 
			@tert, @factura, @gestiune, @lm, @comanda, @indbug, @contmf, @contcor, @contam, @contcham, @numardvi, @pretstoc, @valinv, @sumatva, @cotatva, @nrpozitie

		While @@fetch_status = 0 
		Begin
			select @existaNrinv=(case when exists (select 1 from mfix where Numar_de_inventar=@nrinv) then 1 else 0 end)
			if @existaNrinv=1 
				set @ptupdate=1
			else
				set @ptupdate=0

			set @categmf=convert(int,(case when left(@codcl,1)='2' then left(@codcl,1)+substring(@codcl,3,1) else left(@codcl,1) end))
			if @tipam is null set @tipam=2

			set @parXMLMF=(select 'MI' as '@tip', dbo.eom(@data) as '@datal', 
				(select 'AF' as '@subtip', rtrim(@numar) as '@numar', @data as '@data', @data as '@datapf', 
					rtrim(@nrinv) as '@nrinv', @denmf as '@denmf', @seriemf as '@seriemf', @codcl as '@codcl', @categmf as '@categmf', @tipam as '@tipam', @durata as '@durata', @nrluni as '@nrluni', 
					rtrim(@tert) as '@tert', rtrim(@factura) as '@fact', rtrim(@gestiune) as '@gest', 
					rtrim(@lm) as '@lm', rtrim(@comanda) as '@comanda', rtrim(@indbug) as '@indbug', 
					rtrim(@contmf) as '@contmf', rtrim(@contcor) as '@contcor', rtrim(@contAm) as '@contamcomprim', rtrim(@contcham) as '@contcham', rtrim(@numardvi) as '@numardvi',
					convert(decimal(14,6),@pretstoc) as '@pret', convert(decimal(14,5),@valinv) as '@valinv', 
					convert(decimal(17,2),@sumatva) as '@sumatva', convert(decimal(5,2),@cotatva) as '@cotatva',
					@ptupdate as '@update', 1 as '@farapozdoc', 
					(case when @ptupdate=1 and @existaNrinv=1 then @numar end) as '@o_numar',
					(case when @ptupdate=1 and @existaNrinv=1 then @data end) as '@o_data',
					(case when @ptupdate=1 and @existaNrinv=1 then @nrinv end) as '@o_nrinv', 1 as '@procinch'
					for XML path,type) 
			for XML path,type)

			exec wScriuPozdocMF @sesiune, @parXMLMF

			update pozdoc set jurnal='MFR' where subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and Numar_pozitie=@nrpozitie and jurnal<>'MFR'

			fetch next from tmpMF into @nrinv, @denmf, @seriemf, @codcl, @tipam, @durata, @nrluni, 
				@tert, @factura, @gestiune, @lm, @comanda, @indbug, @contmf, @contcor, @contam, @contcham, @numardvi, @pretstoc, @valinv, @sumatva, @cotatva, @nrpozitie
		end
		close tmpMF
		deallocate tmpMF
	end

	-- modificari de valoare de mijloace fixe operate ca RM	(achizitii de la furnizori)
	if @tip='RM' and @subtip='MM'
	begin
		declare @existaModifNrinv int
		declare tmpMM cursor for 
		select p.cod_intrare, p.detalii.value('(/row/@durata)[1]', 'int') as durata, 
			tert, factura, gestiune, loc_de_munca, left(comanda,20) as comanda, substring(Comanda,21,20) as indbug, 
			cont_de_stoc as contmf, cont_factura as contcor, Numar_dvi as numardvi, 
			cantitate*pret_de_stoc as difvalinv, TVA_deductibil as sumatva, Cota_TVA, numar_pozitie 
		from pozdoc p
			inner join gestiuni g on g.Subunitate=p.Subunitate and g.Cod_gestiune=p.Gestiune and g.Tip_gestiune='I'
		where p.subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and subtip='MM'
			and (@numarpozitie is null or Numar_pozitie=@numarpozitie)
			and (isnull(@idpozdoc,0)=0 or idPozdoc=@idpozdoc)
	
		open tmpMM
		fetch next from tmpMM into @nrinv, @durata, @tert, @factura, @gestiune, @lm, @comanda, @indbug, @contmf, @contcor, @numardvi, @difvalinv, @sumatva, @cotatva, @nrpozitie

		While @@fetch_status = 0 
		Begin
			select @existaModifNrinv=(case when exists (select 1 from mismf where Subunitate=@subunitate and Data_lunii_de_miscare=dbo.EOM(@data) and tip_miscare='MFF' 
				and Numar_de_inventar=@nrinv and Numar_document=@numar) then 1 else 0 end)
			if @existaModifNrinv=1 
				set @ptupdate=1
			else
				set @ptupdate=0
	--	pun aici update-ul pe jurnal astfel incat la MFimportdinCG sa nu se faca importul acestor pozitii
			update pozdoc set jurnal='MFR' where subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and Numar_pozitie=@nrpozitie and jurnal<>'MFR'

			set @parXMLMF=(select 'MM' as '@tip', convert(char(10),dbo.eom(@data),101) as '@datal', 
				(select 'FF' as '@subtip', rtrim(@numar) as '@numar', convert(char(10),@data,101) as '@data', @data as '@datapf', 
					rtrim(@nrinv) as '@nrinv', @durata as '@durata', rtrim(@tert) as '@tert', rtrim(@factura) as '@fact', rtrim(@gestiune) as '@gest', 
					rtrim(@lm) as '@lm', rtrim(@comanda) as '@comanda', rtrim(@indbug) as '@indbug', 
					rtrim(@contcor) as '@contcor', rtrim(@numardvi) as '@numardvi',
					convert(decimal(14,5),@difvalinv) as '@difvalinv', convert(decimal(17,2),@sumatva) as '@sumatva', convert(decimal(5,2),@cotatva) as '@cotatva',
					@ptupdate as '@update', 1 as '@farapozdoc', 
					(case when @ptupdate=1 and @existaModifNrinv=1 then @numar end) as '@o_numar',
					(case when @ptupdate=1 and @existaModifNrinv=1 then @data end) as '@o_data',
					(case when @ptupdate=1 and @existaModifNrinv=1 then @nrinv end) as '@o_nrinv', 1 as '@procinch'
					for XML path,type) 
			for XML path,type)

			exec wScriuPozdocMF @sesiune, @parXMLMF

			fetch next from tmpMM into @nrinv, @durata, @tert, @factura, @gestiune, @lm, @comanda, @indbug, @contmf, @contcor, @numardvi, @difvalinv, @sumatva, @cotatva, @nrpozitie
		end
		close tmpMM
		deallocate tmpMM
	end

	-- transferuri spre/dinspre gestiune de tip I (imobilizari)
	if @tip='TE' and @parXML is not null
	begin
		declare @gestiunePrim varchar(9), @codclasif varchar(20), @contAmortizOB varchar(40), @cod varchar(25), @eroare varchar(2000)

		select @gestiune=isnull(@parXML.value('(/row/row/@gestiune)[1]','varchar(13)'),isnull(@parXML.value('(/row/@gestiune)[1]','varchar(13)'),'')),
			@gestiunePrim=isnull(@parXML.value('(/row/row/@gestprim)[1]','varchar(20)'),isnull(@parXML.value('(/row/@gestprim)[1]','varchar(20)'),'')),
			@tert=rtrim(isnull(@parXML.value('(/row/detalii/row/@tert)[1]', 'varchar(20)'),isnull(@parXML.value('(/row/@tert)[1]','char(13)'),''))),
			@ptupdate=isnull(@parXML.value('(/row/row/@update)[1]','int'),0), 
			@cod=rtrim(isnull(@parXML.value('(/row/row/@cod)[1]', 'varchar(25)'),'')),
			@nrinv=rtrim(isnull(@parXML.value('(/row/linie/@codiprimitor)[1]', 'varchar(25)'), @parXML.value('(/row/row/@codiprimitor)[1]', 'varchar(25)')))

	-- Lucian: pentru transferuri in CG cu gestiune primitoare tip I (Imobilizari) se genereaza in MF intrari de mijloace fixe (IAL) in scopul amortizarii lor
		if @subtip='TE' and isnull((select tip_gestiune from gestiuni where Subunitate=@subunitate and Cod_gestiune=@gestiunePrim),'')='I'
		begin
			set @tipam='2'
	/*
			update p set p.Grupa=p.Cod_intrare
			from pozdoc p
				inner join gestiuni g on g.Subunitate=p.Subunitate and g.Cod_gestiune=p.Gestiune_primitoare and g.Tip_gestiune='I'
			where p.subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and isnull(p.detalii.value('(/row/@genIAL)[1]','int'),0)=0
	*/
	--	inlocuit scriptul de mai sus cu cel primit de la Dorin (se pare ca de pe acelasi cod de intrare se fac mai multe TE-uri catre diversi terti)
			update p set p.Grupa='TE'+rtrim(convert(char(6), p.idpozdoc))
			from pozdoc p
			inner join gestiuni g on g.Subunitate=p.Subunitate and g.Cod_gestiune=p.Gestiune_primitoare and g.Tip_gestiune='I'
			where p.subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and isnull(p.detalii.value('(/row/@genIAL)[1]','int'),0)=0

			IF OBJECT_ID('tempdb..#pozdocIAL') IS NOT NULL drop table #pozdocIAL
			select p.*, isnull(p.detalii.value('(/row/@nrluni)[1]','int'),0) as nr_luni 
			into #pozdocIAL 
			from pozdoc p
				inner join gestiuni g on g.Subunitate=p.Subunitate and g.Cod_gestiune=p.Gestiune_primitoare and g.Tip_gestiune='I'
			where p.subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data 
				and (@ptupdate=1 or isnull(p.detalii.value('(/row/@genIAL)[1]','int'),0)=0)

			select @contAmortizOB=max((case when parametru='CA322' then rtrim(Val_alfanumerica) else '' end))
			from par
			where Tip_parametru='MF' and Parametru in ('CA322')
		
			if exists (select 1 from #pozdocIAL)
			begin
				select @codclasif=max((case when parametru='CODCLOB' then Val_alfanumerica else '' end))
				from par
				if @codclasif='' set @codclasif='9.'

				INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune,detalii)
				select @subunitate,o.grupa,n.denumire,@tert,@tipam,@codclasif,data, '<row cod="'+rtrim(o.cod)+'" tert="'+rtrim(@tert)+'" />'
				from #pozdocIAL o 
					left outer join nomencl n on n.Cod=o.Cod
				where not exists (select 1 from mfix where subunitate=@Subunitate and Numar_de_inventar=o.grupa)
	
				if @ptupdate=1
				begin
					update mfix set detalii='<row tert="'+rtrim(@tert)+'" cod="'+rtrim(p.cod)+'" />'
					from #pozdocIAL p
					where mfix.subunitate=p.subunitate and mfix.Numar_de_inventar=p.grupa and mfix.detalii is null

					update mfix set detalii.modify ('insert (attribute tert {sql:variable("@tert")}, attribute cod {sql:variable("@cod")}) into (/row)[1]')
					from mfix 
					where subunitate=@subunitate and mfix.Numar_de_inventar=@nrinv and detalii is not null 
						and detalii.value('(/row/@tert)[1]','varchar(25)') is null and detalii.value('(/row/@cod)[1]','varchar(25)') is null 

					update mfix set detalii.modify ('replace value of (/row/@tert)[1] with sql:variable("@tert")') 
					from mfix 
					where subunitate=@subunitate and mfix.Numar_de_inventar=@nrinv and detalii.value('(/row/@tert)[1]','varchar(25)') is not null

					update mfix set detalii.modify ('replace value of (/row/@cod)[1] with sql:variable("@cod")') 
					from mfix 
					where subunitate=@subunitate and mfix.Numar_de_inventar=@nrinv and detalii.value('(/row/@cod)[1]','varchar(25)') is not null

				end

				INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune)
				select 'DENS',grupa,'','O','',@contAmortizOB,'1901-01-01'
				from #pozdocIAL
				where not exists (select 1 from mfix where subunitate='DENS' and Numar_de_inventar=grupa)

				INSERT into mismf (Subunitate,Data_lunii_de_miscare,Numar_de_inventar,Tip_miscare,Numar_document,Data_miscarii,Tert,Factura,Pret,TVA,
					Cont_corespondent,Loc_de_munca_primitor,Gestiune_primitoare,Diferenta_de_valoare,Data_sfarsit_conservare,Subunitate_primitoare,Procent_inchiriere)
				select @subunitate,dbo.EOM(data),grupa,'IAL',numar,data,'','',cantitate,0,cont_de_stoc,'','',0,data,@contAmortizOB,6
				from #pozdocIAL
				where not exists (select 1 from mismf where subunitate=@subunitate and Numar_de_inventar=grupa and Data_lunii_de_miscare=dbo.EOM(data) and Tip_miscare='IAL')
			
				INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
					Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
					Obiect_de_inventar, Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate)
				select @subunitate,grupa,convert(int,(case when Left (@codclasif,1)='2' then Left (@codclasif,1)+substring(@codclasif,3,1) else Left (@codclasif,1) end)),
					dbo.EOM(data),'1',loc_de_munca,gestiune_primitoare,comanda,cantitate*pret_de_stoc,0,0,0,0,0,0,nr_luni/12.0,0,cont_corespondent,nr_luni,Cantitate
				from #pozdocIAL
				where not exists (select 1 from fisamf where subunitate=@subunitate and Numar_de_inventar=grupa and Felul_operatiei='1' and Data_lunii_operatiei=dbo.EOM(data))

				INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
					Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
					Obiect_de_inventar, Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate)
				select @subunitate,grupa,convert(int,(case when Left (@codclasif,1)='2' then Left (@codclasif,1)+substring(@codclasif,3,1) else Left (@codclasif,1) end)),
					dbo.EOM(data),'3',loc_de_munca,gestiune_primitoare,comanda,cantitate*pret_de_stoc,0,0,0,0,0,0,nr_luni/12,0,cont_corespondent,nr_luni,Cantitate
				from #pozdocIAL
				where not exists (select 1 from fisamf where subunitate=@subunitate and Numar_de_inventar=grupa and Felul_operatiei='3' and Data_lunii_operatiei=dbo.EOM(data))

	--	actualizare valoare de inventar din fisamf
				if @ptupdate=1 and not exists (select 1 from fisamf where subunitate=@subunitate and Numar_de_inventar in (select grupa from #pozdocIAL) and Felul_operatiei='1' and Valoare_amortizata<>0)
				Begin
					update fisaMF set Valoare_de_inventar=p.Cantitate*p.Pret_de_stoc, Durata=nr_luni/12.0, Numar_de_luni_pana_la_am_int=nr_luni, Cont_mijloc_fix=cont_corespondent, Cantitate=p.Cantitate
					from #pozdocIAL p
					where fisaMF.subunitate=@subunitate and fisaMF.Numar_de_inventar=grupa and fisaMF.Data_lunii_operatiei=dbo.EOM(p.data)
	--	actualizare pret (=cantitate) din mismf
					update mismf set Pret=p.Cantitate, Cont_corespondent=cont_de_stoc, Subunitate_primitoare=@contAmortizOB
					from #pozdocIAL p
					where mismf.subunitate=@subunitate and mismf.Numar_de_inventar=grupa and mismf.Data_lunii_de_miscare=dbo.EOM(p.data)
				End

	--	completez in detalii(xml) faptul ca s-a generat pentru pozitia de TE, IAL-ul aferent
				declare @genIAL int
				set @genIAL=1
				update p set detalii.modify ('insert (attribute genIAL {sql:variable("@genIAL")}) into (/row)[1]')
				from pozdoc p
				where subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and detalii is not null
					and isnull(p.detalii.value('(/row/@genIAL)[1]','int'),0)=0
					and exists (select 1 from #pozdocIAL p1 where p1.Subunitate=p.Subunitate and p1.Tip=p.Tip and p1.Numar=p.Numar and p1.Data=p.Data and p1.Cod=p.Cod 
						and p1.Gestiune=p.Gestiune and p1.Cod_intrare=p.Cod_intrare and p1.Numar_pozitie=p.Numar_pozitie)

				update p set detalii='<row genIAL="1" />'
				from pozdoc p
				where subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and detalii is null
					and exists (select 1 from #pozdocIAL p1 where p1.Subunitate=p.Subunitate and p1.Tip=p.Tip and p1.Numar=p.Numar and p1.Data=p.Data and p1.Cod=p.Cod 
						and p1.Gestiune=p.Gestiune and p1.Cod_intrare=p.Cod_intrare and p1.Numar_pozitie=p.Numar_pozitie)

			end
			IF OBJECT_ID('tempdb..#pozdocIAL') IS NOT NULL drop table #pozdocIAL
		end

	--	Lucian: pentru transferuri in CG cu gestiune predatoare tip I (Imobilizari) se genereaza in MF modificari de valoare (MEP-iesire partiala) - retur
	-- Ghita:... sau (EAE-alte iesiri) daca se returneaza toata cantitatea 
		if @subtip='TR' and isnull((select tip_gestiune from gestiuni where Subunitate=@subunitate and Cod_gestiune=@gestiune),'')='I'
		begin
			IF OBJECT_ID('tempdb..#pozdocMEP') IS NOT NULL drop table #pozdocMEP
			declare @cont_amortizare varchar(40), @val_amortizata decimal(18,2), @detalii xml

			select p.*, f.Valoare_de_inventar, f.Valoare_amortizata+f1.Amortizare_lunara as Valoare_amortizata, 
				round(convert(decimal(12,3),f.Valoare_de_inventar*p.cantitate/f.cantitate),2) as Diferenta_de_valoare, 
				round(convert(decimal(12,3),(f.Valoare_amortizata+f1.Amortizare_lunara)*p.cantitate/f.cantitate),2) as Diferenta_de_amortizare, 
				mf.Cod_de_clasificare as Cont_amortizare, convert(float,0) as pret_de_stoc_nou, f.cantitate-p.cantitate as cant_noua
			into #pozdocMEP
			from pozdoc p
				inner join gestiuni g on g.Subunitate=p.Subunitate and g.Cod_gestiune=p.Gestiune and g.Tip_gestiune='I'
				left outer join fisamf f on f.Subunitate=p.Subunitate and f.Numar_de_inventar=p.Grupa and f.Data_lunii_operatiei=dbo.EOM(DateADD(month,-1,data)) and f.Felul_operatiei='1'
				left outer join fisamf f1 on f1.Subunitate=p.Subunitate and f1.Numar_de_inventar=p.Grupa and f1.Data_lunii_operatiei=dbo.EOM(data) and f1.Felul_operatiei='1'
				left outer join mfix mf on mf.Subunitate='DENS' and mf.Numar_de_inventar=p.Grupa 
			where p.subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data 
				and (@ptupdate=1 or isnull(p.detalii.value('(/row/@genMEP)[1]','int'),0)=0)
		
			select @detalii=detalii, @cont_amortizare=rtrim(Cont_amortizare), @val_amortizata=convert(decimal(12,2),Diferenta_de_amortizare) from #pozdocMEP
	
			update #pozdocMEP set pret_de_stoc_nou=round(convert(decimal(12,3),(Diferenta_de_valoare-Diferenta_de_amortizare)/cantitate),3)

			if exists (select 1 from #pozdocMEP)
			begin
				INSERT into mismf (Subunitate,Data_lunii_de_miscare,Numar_de_inventar,Tip_miscare,Numar_document,Data_miscarii,Tert,Factura,Pret,TVA,
					Cont_corespondent,Loc_de_munca_primitor,Gestiune_primitoare,Diferenta_de_valoare,Data_sfarsit_conservare,Subunitate_primitoare,Procent_inchiriere)
				select @subunitate,dbo.EOM(data),grupa,(case when p.cant_noua<0.0001 then 'EAE' else 'MEP' end),numar,data,'','',-Diferenta_de_amortizare,0,cont_corespondent,'','',
					-p.Diferenta_de_valoare,data,p.Cont_amortizare,6
				from #pozdocMEP p
				where not exists (select 1 from mismf where subunitate=@subunitate and Numar_de_inventar=grupa and Data_lunii_de_miscare=dbo.EOM(data) 
					and Tip_miscare=(case when p.cant_noua<0.0001 then 'EAE' else 'MEP' end))

				INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
					Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
					Obiect_de_inventar, Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate)
				select @subunitate,grupa,f.Categoria,dbo.EOM(data),(case when p.cant_noua<0.0001 then '5' else '4' end),f.loc_de_munca,f.Gestiune,f.comanda,
					p.Valoare_de_inventar-(case when p.cant_noua<0.0001 then 0 else p.Diferenta_de_valoare end),
					p.Valoare_amortizata-(case when p.cant_noua<0.0001 then 0 else Diferenta_de_amortizare end),0
					,0,f.Amortizare_lunara,0,0,f.Durata,0,f.Cont_mijloc_fix,f.Numar_de_luni_pana_la_am_int,
					(case when p.cant_noua<0.0001 then f.cantitate else p.Cant_noua end)
				from #pozdocMEP p
					left outer join fisamf f on f.Subunitate=p.Subunitate and f.Numar_de_inventar=p.Grupa and Data_lunii_operatiei=dbo.EOM(data) and f.Felul_operatiei='1'
				where not exists (select 1 from fisamf where subunitate=@subunitate and Numar_de_inventar=grupa and Felul_operatiei=(case when p.cant_noua<0.0001 then '5' else '4' end)
					and Data_lunii_operatiei=dbo.EOM(data))

				update fisamf set 
					valoare_de_inventar=(case when p.cant_noua<0.0001 then 0 else f.Valoare_de_inventar end), Valoare_amortizata=(case when p.cant_noua<0.0001 then 0 else f.valoare_amortizata end), 
					cantitate=(case when p.cant_noua<0.0001 then 0 else f.cantitate end)
				from fisamf, #pozdocMEP p, fisamf f 
					where fisamf.Subunitate=p.Subunitate and fisamf.Numar_de_inventar=p.Grupa and fisamf.Data_lunii_operatiei=dbo.EOM(data) and fisamf.Felul_operatiei='1'
						and f.Subunitate=fisamf.Subunitate and f.Numar_de_inventar=fisamf.Numar_de_inventar and fisamf.Data_lunii_operatiei=f.Data_lunii_operatiei 
						and f.Felul_operatiei=(case when p.cant_noua<0.0001 then '5' else '4' end)
					

	--	completez in detalii(xml) faptul ca s-a generat pentru pozitia de TE, MEP-ul aferent
				declare @genMEP int
				set @genMEP=1

				if @detalii is null
					set @detalii='<row genMEP="1" />'
				if @detalii.value('(/*/@genMEP)[1]','int') IS NULL
					set @detalii.modify ('insert attribute genMEP {sql:variable("@genMEP")} into (/row)[1]')

				if @detalii.value('(/*/@contam)[1]','varchar(40)') IS NULL
					set @detalii.modify ('insert attribute contam {sql:variable("@cont_amortizare")} into (/row)[1]')
				else 
					set @detalii.modify('replace value of (/row/@contam)[1] with sql:variable("@cont_amortizare")')

				if @detalii.value('(/*/@valam)[1]','float') IS NULL
					set @detalii.modify ('insert attribute valam {sql:variable("@val_amortizata")} into (/row)[1]')
				else 
					set @detalii.modify('replace value of (/row/@valam)[1] with sql:variable("@val_amortizata")')

	--	scriu pret de stoc si detalii in pozdoc
				update p set p.Pret_de_stoc=p1.Pret_de_stoc_nou, detalii=@detalii
				from pozdoc p
					inner join #pozdocMEP p1 on p1.Subunitate=p.Subunitate and p1.Tip=p.Tip and p1.Numar=p.Numar and p1.Data=p.Data and p1.Cod=p.Cod 
						and p1.Gestiune=p.Gestiune and p1.Cod_intrare=p.Cod_intrare and p1.Numar_pozitie=p.Numar_pozitie and p1.idPozdoc=p.idPozdoc
				where p.subunitate=@subunitate and p.Tip=@tip and p.Numar=@numar and p.Data=@data 

				IF OBJECT_ID('tempdb..#pozdocMEP') IS NOT NULL drop table #pozdocMEP
			end
		end
	end
end try

begin catch
	set @eroare=ERROR_MESSAGE()+' (wScriuMFdinCG)'
	if @eroare is not null raiserror(@eroare,16,1)
end catch
	
