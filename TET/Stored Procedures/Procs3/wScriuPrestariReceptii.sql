--***
create procedure wScriuPrestariReceptii (@sesiune varchar(20),@parXML xml)
as
begin
declare @Tip varchaR(2),@Numar char(20), @Data datetime, @Tert char(13),
	@Tert_prest char(13),@Cod_prest char(20), @Valuta_prest char(3), @Curs_prest float,@Factura_prest varchar(20),@Data_fact_prest datetime,
	@Data_scad_prest datetime,@Cont_fact_prest varchar(40),@Valoare_prest float,@Cota_TVA_prest float,@Tip_TVA_prest int,@Update int,
	@ValoareFaraTVAvaluta_prest float,@ValoareFaraTVAlei_prest float,@Numar_pozitie int,@stergere int,@subtip varchar(2),@tipRepartizarePrestari int, @detalii xml,
	@Valoare_prest_in_valuta float, @cantitate float


begin try
	/* Blocheaza rau de tot tranzactia asta
	MAcar citirea / scriere liniei cu DO,POZITIE sa fie in afara ei
	BEGIN TRANSACTION prestari
	*/

	--SET Context_Info 0x55555 

	select 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@Numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@Data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
		@Tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),
		
		@Tert_prest=ISNULL(@parXML.value('(/row/row/@tert)[1]', 'varchar(13)'), ''),
		@Cod_prest=ISNULL(@parXML.value('(/row/row/@cod)[1]', 'varchar(20)'), ''),
		@Valuta_prest=ISNULL(@parXML.value('(/row/row/@valuta)[1]', 'varchar(3)'), ''),
		@Curs_prest=ISNULL(@parXML.value('(/row/row/@curs)[1]', 'float'), 0),
		@Factura_prest=ISNULL(@parXML.value('(/row/row/@factura)[1]', 'varchar(20)'), ''),
		@Data_fact_prest=ISNULL(@parXML.value('(/row/row/@data_factura)[1]', 'datetime'), '1901-01-01'),
		@Data_scad_prest=ISNULL(@parXML.value('(/row/row/@data_scadentei)[1]', 'datetime'), '1901-01-01'),
		@Cont_fact_prest=ISNULL(@parXML.value('(/row/row/@contfactura)[1]', 'varchar(40)'), ''),
		@Valoare_prest=ISNULL(@parXML.value('(/row/row/@pret_valuta)[1]', 'float'), ''),
		@Valoare_prest_in_valuta=ISNULL(@parXML.value('(/row/row/@pret_in_valuta)[1]', 'float'), ''),
		@Cota_TVA_prest=ISNULL(@parXML.value('(/row/row/@cotatva)[1]', 'float'), 0),
		@Tip_TVA_prest=ISNULL(@parXML.value('(/row/row/@tiptva)[1]', 'int'), 0),
		@Numar_pozitie=ISNULL(@parXML.value('(/row/row/@numarpozitie)[1]', 'int'), 0),
		@tipRepartizarePrestari=(case when @parXML.value('(/row/row/@tipRepartizarePrestari)[1]', 'varchar(40)')='GREUTATE' then 1 else 0 end),
		@Update=ISNULL(@parXML.value('(/row/row/@update)[1]', 'int'), 0),
		@ValoareFaraTVAvaluta_prest=ISNULL(@parXML.value('(/row/row/@ValoareFaraTVAvaluta_prest)[1]', 'float'), 0),
		@ValoareFaraTVAlei_prest=ISNULL(@parXML.value('(/row/row/@ValoareFaraTVAlei_prest)[1]', 'float'), 0),
		@subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), ''),
		@detalii=@parXML.query('(/row/row/detalii/row)[1]'),
		@cantitate=ISNULL(@parXML.value('(/row/row/@cantitate)[1]', 'float'), 1)

	--daca se introuce valoarea in valuta, nu se introduce valoare in lei si exista valuta si curs completat, se calculeaza valoarea in lei din valoarea in valuta
	if isnull(@Curs_prest,0)>0 and isnull(@Valuta_prest,'')<>''and (isnull(@Valoare_prest,0)=0 or @Update=1) and isnull(@Valoare_prest_in_valuta,0)>0
		set @Valoare_prest=@Valoare_prest_in_valuta*@Curs_prest

	/* Am tratat asa pentru cazul in care nu s-a rulat AS\+webConfig si nu s-a actualizat configurarea tipului de repartizare in detalii. */
	if @detalii.value('(/row/@rep_greutate)[1]','char(1)') is not null
		set @tipRepartizarePrestari=0
						
	declare @Sb char(9),@CodPS int,@RPGreu int,@NrPozitie int,@SumaTVA float, @DVE int,@Utilizator char(10),@CDTVA varchar(40),@CNEEXREC varchar(40),
			@ACTNOMINT int,@CtTVA varchar(40),@Ct4428LaInc varchar(40),@TipPlataTVA char(1)
			
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'CDTVA', 0, 0, @CDTVA output
	exec luare_date_par 'GE', 'CNEEXREC', 0, 0, @CNEEXREC output
	exec luare_date_par 'GE', 'CODPS', @CodPS output, 0, ''
	exec luare_date_par 'GE', 'RPGREU', @RPGreu output, 0, ''
	exec luare_date_par 'GE', 'ACTNOMINT', @ACTNOMINT output, 0, ''
	exec luare_date_par 'GE','DVE',@DVE output,0,''
	exec luare_date_par 'GE','CNTLIFURN',0,0,@Ct4428LaInc output

--	apelez validarea pentru receptiile de mijloace fixe pentru cazul in care s-a inceput amortizarea pentru acestea
	if exists (select 1 from sysobjects where [type]='P' and [name]='wValidareMFdinCG') 
		and exists (select 1 from pozdoc where Subunitate=@sb and Tip=@tip and Numar=@numar and Data=@data and subtip='MF')
		exec wValidareMFdinCG @sesiune, @parXML

	/* Cont factura prestare - daca nu s-a completat si s-a completat tert prestare, sa citeasca contul de furnizor atasat tertului */
	if @Cont_fact_prest='' and @Tert_prest<>''
		select @Cont_fact_prest=Cont_ca_furnizor
		from terti where subunitate=@Sb and tert=@Tert_prest

	/*Tva la incasare*/
	select top 1 @TipPlataTVA=tip_tva from TvaPeTerti --Verific daca este cu Tva La Incasare
		where tert is null and tipf='B' and @Data_fact_prest>=dela
	order by dela desc

	if @TipPlataTVA is null --Daca nu e (null) cu TVA la incasare se va studia furnizorul
			select top 1 @TipPlataTVA=tip_tva from TvaPeTerti 
				where tert=@Tert_prest and tipf='F' and @Data_fact_prest>=dela
				order by dela desc

	if @TipPlataTVA is null
		set @TipPlataTVA='P'

	set @CtTVA=(case when @TipPlataTVA='I' and @Tip_TVA_prest<>1 then @Ct4428LaInc else @CDTVA end)
	
	if @Valoare_prest=0 and @ValoareFaraTVAvaluta_prest<>0
		set @Valoare_prest=convert(decimal(17,4),@ValoareFaraTVAvaluta_prest*(case when @Valuta_prest<>'' then @Curs_prest else 1 end))
	
	set @SumaTVA=round(convert(decimal(17,4),(@cantitate*@Valoare_prest)*@Cota_TVA_prest/100),2)
	
	-->>>>> adaugare pozitie prestare pe receptie->se face insert in pozdoc<<<<<<---
	if @Update=0
	begin
		exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''
		set @NrPozitie=@NrPozitie+1
		
		declare @lFacturaDoc int
		set @lFacturaDoc=0
		if exists (select 1 from doc where subunitate=@sb and tip='RM' and Numar=@Numar and data=@Data and Factura=@Factura_prest and cod_tert=@Tert_prest) 
				or (isnull(@Factura_prest,'')='' and isnull(@Tert_prest,'')='' and @subtip='RP')
			set @lFacturaDoc=1

		insert pozdoc
			(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
			Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 	
			Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare,	
			Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 	
			Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI,	
			Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama,	
			Accize_cumparare, Accize_datorate, Contract, Jurnal, detalii) 
		select
			@Sb, @subtip, @Numar, @Cod_prest, @Data, Cod_gestiune, @cantitate, @Valoare_prest, @ValoareFaraTVAvaluta_prest, 0, 
			0, 0, @SumaTVA,case when @subtip='RZ' then 0 else (case when isnull(@Cota_TVA_prest,0)<>0 then @Cota_TVA_prest else cota_tva end)end, 
			isnull(@Utilizator,''),convert(datetime,convert(char(10),getdate(),104),104), RTrim(replace(convert(char(8),getdate(),108),':','')), 	
			'', '','', 0, 0, 'V', 	
			'', data, @NrPozitie, Loc_munca,Comanda, '',	
			'', (case when left(Cont_factura,3)='408' then @CNEEXREC else @CtTVA end), 0,
			case when @subtip='RZ' then '' else (case when isnull(@Tert_prest,'')<>'' then @Tert_prest else Cod_tert end) end as tert, 
			case when @subtip='RZ' then '' else (case when isnull(@Factura_prest,'')<>'' then @Factura_prest else Factura end) end as factura, '', '', 
			3, (case when isnull(@Valuta_prest,'')<>'' then convert(varchar,@SumaTVA/@Curs_prest) else '' end), 
			isnull((case when @lFacturaDoc=1 then Cont_factura else nullif(@Cont_fact_prest,'') end),'') as cont_factura, 
			(case when isnull(@Valuta_prest,'')<>'' then @Valuta_prest when @lFacturaDoc=1 then valuta else '' end), 
			(case when isnull(@Curs_prest,0)<>0 then @Curs_prest when @lFacturaDoc=1 then curs else 0 end), 
			(case when @subtip='RZ' then '1901-01-01' else case when @Data_fact_prest<>'1901-01-01' then @Data_fact_prest else Data_facturii end end), 
			isnull((case when @lFacturaDoc=1 then Data_scadentei else @Data_scad_prest end),Data_scadentei), @Tip_TVA_prest, 0, 
			0, @tipRepartizarePrestari, '', '', @detalii
		from doc
		where subunitate=@sb and tip='RM' and Numar=@Numar and data=@Data and Cod_tert=@Tert
		
		exec setare_par 'DO','POZITIE',null,null,@NrPozitie,null
		
	end
	-->>>> stop adaugare pozitie prestare pe receptie->se face insert in pozdoc<<<<---
	
	-->>> start modificare pozitie prestare pe receptie->se face update in pozdoc si se calculeaza valoarea de repartizat(diferenta)<<<<--	
	if @Update=1
	begin		
		update pozdoc set Tert=@Tert_prest,Cod=@Cod_prest,Valuta=@Valuta_prest,Curs=@Curs_prest,Factura=@Factura_prest,Data_facturii=@Data_fact_prest,
			Data_scadentei=@Data_scad_prest,Cont_factura=@Cont_fact_prest,Pret_de_stoc=@ValoareFaraTVAvaluta_prest,Pret_valuta=@Valoare_prest,Cota_TVA=@Cota_TVA_prest,
			Procent_vama=@Tip_TVA_prest, TVA_deductibil=@SumaTVA, Cont_venituri=(case when left(Cont_factura,3)='408' or @CtTVA is null then Cont_venituri else @CtTVA end),
			accize_datorate=@tipRepartizarePrestari, detalii=@detalii,
			Cantitate=@cantitate
		where Subunitate=@Sb
			and tip=@subtip
			and Numar=@Numar 
			and data=@Data 
			and Numar_pozitie=@Numar_pozitie			   
	end	
	--->>>>>stop modificaree pozitie prestare pe receptie->se face update in pozdoc si se calculeaza valoarea de repartizat(diferenta)<<<<--

	--apelare procedura pentru repartizare
	exec repartizarePrestariReceptii 'RM', @numar, @data
	/*
	Blocheza rau de tot tranzactia asta
	--COMMIT TRANSACTION prestari
	*/
		
		declare @docXMLIaPozdoc xml
		set @docXMLIaPozdoc = '<row subunitate="' + rtrim(@sb) + '" tip="' + rtrim('RM') + '" numar="' + rtrim(@numar) + '" data="' + convert(char(10), @data, 101) +'"/>'
		exec wIaPozPrestariServicii @sesiune=@sesiune, @parXML=@docXMLIaPozdoc	

end try	
begin catch 
	rollback transaction prestari
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch	
end
