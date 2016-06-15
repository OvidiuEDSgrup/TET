--***
create procedure scriuPrestariReceptii (@sesiune varchar(20),@parXML xml)
as
begin
declare @Tip varchaR(2),@Numar char(8), @Data datetime, @Tert char(13),
		@Tert_prest char(13),@Cod_prest char(20), @Valuta_prest char(3), @Curs_prest float,@Factura_prest varchar(20),@Data_fact_prest datetime,
		@Data_scad_prest datetime,@Cont_fact_prest varchar(13),@Valoare_prest float,@Cota_TVA_prest float,@Tip_TVA_prest int,@Update int,
		@ValoareFaraTVAvaluta_prest float,@ValoareFaraTVAlei_prest float,@Numar_pozitie int,@stergere int,
		@Tert_prest_o char(13),@Cod_prest_o char(20), @Valuta_prest_o char(3), @Curs_prest_o float,@Factura_prest_o varchar(20),@Data_fact_prest_o datetime,
		@Data_scad_prest_o datetime,@Cont_fact_prest_o varchar(13),@Valoare_prest_o float,@Cota_TVA_prest_o float,@Tip_TVA_prest_o int

begin try
BEGIN TRANSACTION 
--SET Context_Info 0x55555 
select 
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
	@Numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(8)'), ''),
	@Data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
	@Tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),
	
	@Tert_prest=ISNULL(@parXML.value('(/row/row/@tert_prest)[1]', 'varchar(13)'), ''),
	@Cod_prest=ISNULL(@parXML.value('(/row/row/@cod_prest)[1]', 'varchar(20)'), ''),
	@Valuta_prest=ISNULL(@parXML.value('(/row/row/@valuta_prest)[1]', 'varchar(3)'), ''),
	@Curs_prest=ISNULL(@parXML.value('(/row/row/@curs_prest)[1]', 'float'), 0),
	@Factura_prest=ISNULL(@parXML.value('(/row/row/@factura_prest)[1]', 'varchar(20)'), ''),
	@Data_fact_prest=ISNULL(@parXML.value('(/row/row/@data_fact_prest)[1]', 'datetime'), ''),
	@Data_scad_prest=ISNULL(@parXML.value('(/row/row/@data_scad_prest)[1]', 'datetime'), ''),
	@Cont_fact_prest=ISNULL(@parXML.value('(/row/row/@contfactura_prest)[1]', 'varchar(13)'), ''),
	@Valoare_prest=ISNULL(@parXML.value('(/row/row/@pret_valuta_prest)[1]', 'float'), ''),
	@Cota_TVA_prest=ISNULL(@parXML.value('(/row/row/@cotatva_prest)[1]', 'float'), 0),
	@Tip_TVA_prest=ISNULL(@parXML.value('(/row/row/@tiptva_prest)[1]', 'int'), 0),
	@Numar_pozitie=ISNULL(@parXML.value('(/row/row/@numarpozitie)[1]', 'int'), 0),
	@Update=ISNULL(@parXML.value('(/row/row/@update)[1]', 'int'), 0),
	@Stergere=ISNULL(@parXML.value('(/row/row/@stergere)[1]', 'int'), 0),
	@ValoareFaraTVAvaluta_prest=ISNULL(@parXML.value('(/row/row/@ValoareFaraTVAvaluta_prest)[1]', 'float'), 0),
	@ValoareFaraTVAlei_prest=ISNULL(@parXML.value('(/row/row/@ValoareFaraTVAlei_prest)[1]', 'float'), 0)
	
	if @Update=1
		begin
		select
			@Tert_prest_o=ISNULL(@parXML.value('(/row/row/@o_tert_prest)[1]', 'varchar(13)'), ''),
			@Cod_prest_o=ISNULL(@parXML.value('(/row/row/@o_cod_prest)[1]', 'varchar(20)'), ''),
			@Valuta_prest_o=ISNULL(@parXML.value('(/row/row/@o_valuta_prest)[1]', 'varchar(3)'), ''),
			@Curs_prest_o=ISNULL(@parXML.value('(/row/row/@o_curs_prest)[1]', 'float'), 0),
			@Factura_prest_o=ISNULL(@parXML.value('(/row/row/@o_factura_prest)[1]', 'varchar(20)'), ''),
			@Data_fact_prest_o=ISNULL(@parXML.value('(/row/row/@o_data_fact_prest)[1]', 'datetime'), ''),
			@Data_scad_prest_o=ISNULL(@parXML.value('(/row/row/@o_data_scad_prest)[1]', 'datetime'), ''),
			@Cont_fact_prest_o=ISNULL(@parXML.value('(/row/row/@o_contfactura_prest)[1]', 'varchar(13)'), ''),
			@Valoare_prest_o=ISNULL(@parXML.value('(/row/row/@o_pret_valuta_prest)[1]', 'float'), 0),
			@Cota_TVA_prest_o=ISNULL(@parXML.value('(/row/row/@o_cotatva_prest)[1]', 'float'), 0),
			@Tip_TVA_prest_o=ISNULL(@parXML.value('(/row/row/@o_tiptva_prest)[1]', 'int'), 0)
		end	
			
declare @Sb char(9),@CodPS int,@RPGreu int,@NrPozitie int,@SumaTVA float, @DVE int,@Utilizator char(10),@CDTVA varchar(13),@CNEEXREC varchar(13),
		@ACTNOMINT int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
exec luare_date_par 'GE', 'CDTVA', 0, 0, @CDTVA output
exec luare_date_par 'GE', 'CNEEXREC', 0, 0, @CNEEXREC output
exec luare_date_par 'GE', 'CODPS', @CodPS output, 0, ''
exec luare_date_par 'GE', 'RPGREU', @RPGreu output, 0, ''
exec luare_date_par 'GE', 'ACTNOMINT', @ACTNOMINT output, 0, ''
exec luare_date_par 'GE','DVE',@DVE output,0,''

-->>>>> start daca suntem pe adaugare pozitie prestare pe receptie->se face insert in pozdoc<<<<<<---

if @Update=0 and @stergere<>1
begin
	exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''
	set @NrPozitie=@NrPozitie+1
	
	set @SumaTVA=round(convert(decimal(17,4),@Valoare_prest*(case when @Valuta_prest<>'' then @Curs_prest else 1 end)*@Cota_TVA_prest/100),2)
		
	if @Utilizator is null
		set @Utilizator=dbo.fIauUtilizatorCurent()

	insert pozdoc
		(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
		Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 	
		Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare,	
		Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 	
		Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI,	
		Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama,	
		Accize_cumparare, Accize_datorate, Contract, Jurnal) 
	select
		@Sb, 'RP', @Numar, @Cod_prest, @Data, Cod_gestiune, 1, @Valoare_prest, @ValoareFaraTVAvaluta_prest, 0, 
		0, 0, @SumaTVA,(case when isnull(@Cota_TVA_prest,0)<>0 then @Cota_TVA_prest else cota_tva end), isnull(@Utilizator,''),convert(datetime,convert(char(10),getdate(),104),104), RTrim(replace(convert(char(8),getdate(),108),':','')), 	
		'', '','', 0, 0, 'V', 	
		'', data, @NrPozitie, Loc_munca,Comanda, '',	
		'', (case when Cont_factura='408' then @CNEEXREC else @CDTVA end), 0,(case when isnull(@Tert_prest,'')<>'' then @Tert_prest else Cod_tert end), (case when isnull(@Factura_prest,'')<>'' then @Factura_prest else Factura end), '', '', 
		3, (case when isnull(@Valuta_prest,'')<>'' then convert(varchar,@SumaTVA/@Curs_prest) else '' end), isnull((case when @Factura_prest=Factura then Cont_factura else @Cont_fact_prest end),Cont_factura), 
		(case when isnull(@Valuta_prest,'')<>'' then @Valuta_prest else valuta end), (case when isnull(@Curs_prest,0)<>0 then @Curs_prest else curs end), 
		(case when @Data_fact_prest=Data_facturii then Data_facturii else @Data_fact_prest end), (case when @Data_scad_prest=Data_scadentei then Data_scadentei else @Data_scad_prest end), @Tip_TVA_prest, 0, 
		0, 0, '', ''	
	from doc
	where tip=@Tip and Numar=@Numar and data=@Data and Cod_tert=@Tert
	exec setare_par 'DO','POZITIE',null,null,@NrPozitie,null
	
end
-->>>> stop daca suntem pe adaugare pozitie prestare pe receptie->se face insert in pozdoc<<<<---
--select * from doc
-->>> start daca suntem pe modificare pozitie prestare pe receptie->se face update in pozdoc si se calculeaza valoarea de repartizat(diferenta)<<<<--	
if @Update=1 and @stergere<>1
	begin
	update pozdoc  set Tert=@Tert_prest,Cod=@Cod_prest,Valuta=@Valuta_prest,Curs=@Curs_prest,Factura=@Factura_prest,Data_facturii=@Data_fact_prest,
					  Data_scadentei=@Data_scad_prest,Cont_factura=@Cont_fact_prest,Pret_valuta=@Valoare_prest,Cota_TVA=@Cota_TVA_prest,
					  Procent_vama=@Tip_TVA_prest
	where tip='RP'
	  and Numar=@Numar 
	  and data=@Data 
	  and Subunitate=@Sb	
	  and Numar_pozitie=@Numar_pozitie			   
	
	set @Valoare_prest=@Valoare_prest-@Valoare_prest_o
	end	
--->>>>>stop daca suntem pe modificaree pozitie prestare pe receptie->se face update in pozdoc si se calculeaza valoarea de repartizat(diferenta)<<<<--

--->>>>>start daca suntem pe stergere pozitie prestare pe receptie-> se sterge pozitia de prestare se calculeaza valoarea de repartizat(diferenta)<<<<--
if @stergere=1
	begin	
	delete from pozdoc 
	where tip='RP' 
		and Numar=@Numar 
	    and data=@Data 
		and Subunitate=@Sb	
		and Numar_pozitie=@Numar_pozitie	--stergere si pozitie din pozdoc
	set @Valoare_prest=@Valoare_prest*(-1)
--select 'stergere', @Valoare_prest,@stergere
	end
--->>>>>stop daca daca suntem pe stergere pozitie prestare pe receptie-> se sterge pozitia de prestare se calculeaza valoarea de repartizat(diferenta)<<<<--

--->>>>>strat repartizare valoare prestare pe pozitii receptie<<<<----
if @Valoare_prest<>0
	begin	
	declare @valLeiFaraTaxe float,@greutate_totala float, @cantitate_totala float
	
	select @valLeiFaraTaxe=sum(p.Cantitate*(case when isnull(p.Numar_DVI,'')='' then p.Pret_de_stoc else p.Pret_valuta end)*(1+p.Discount/100)),
		   @greutate_totala=sum(p.Cantitate*n.Greutate_specifica),
		   @cantitate_totala=sum(p.Cantitate)
	from pozdoc p,nomencl n
	where p.tip='RM' 
	  and p.Numar=@Numar 
	  and p.data=@Data 
	  and p.Subunitate=@Sb 
	  and p.Cod=n.Cod
	  and (p.Cod=@Cod_prest or isnull(@Cod_prest,'')='')
	 group by numar 
--select 	@valLeiFaraTaxe,@greutate_totala,@cantitate_totala,'valori calculate',@Numar,@Data,@Tert
	
	 declare @nrDVi_c varchar(25),@pretStoc_c float,@pretValuta_c float,@discount_c real,@valuta_c varchar(3),@curs_c float,
			 @greutateSP_c float,@numar_pozitie_c int,@cantitate_c float,@cod_c varchar(13), 
			 @pret_stoc_anterior float,@pret_stoc_nou float,@procent_greutate float,@dif_pret_stoc float,@val_comisionar float,@ultim_nr_pozitie int
	 select @pret_stoc_anterior=0,@pret_stoc_nou=0,@procent_greutate=0,@dif_pret_stoc=0,@val_comisionar=0,@ultim_nr_pozitie=0
	 
	 declare prestari cursor for
	 select p.numar_DVI,p.pret_de_stoc,p.Pret_valuta,p.Discount,p.Valuta,p.Curs,n.Greutate_specifica,p.numar_pozitie,p.cantitate,p.cod
	 from pozdoc p, nomencl n,gestiuni g
	 where p.Subunitate=@Sb
	   and p.Numar=@Numar
	   and p.Data=@Data
	   and p.cod=n.cod
	   and p.gestiune=g.cod_gestiune
	   and p.Tip='RM'
	   and (p.Cod=@Cod_prest or isnull(@Cod_prest,'')='')
	   
	open prestari                     
	fetch next from prestari 
              into @nrDVi_c,@pretStoc_c,@pretValuta_c,@discount_c,@valuta_c,@curs_c,@greutateSP_c ,@numar_pozitie_c ,@cantitate_c,@cod_c         
  
    while  @@fetch_status = 0     
    begin      		
    if @pretValuta_c>0
		begin
			set @pret_stoc_anterior=(case when isnull(@nrDVi_c,'')='' then @pretStoc_c else @pretValuta_c end)*(1+@discount_c/100)*
									(case when isnull(@valuta_c,'')<>'' then @curs_c else 1 end)		
	
			if @RPGreu=0--daca se face repartizare valorica
			begin
			set @pret_stoc_nou=round(@pret_stoc_anterior+(@pret_stoc_anterior*@Valoare_prest/@valLeiFaraTaxe),5)	
--select 'pretstoc',@pret_stoc_nou as pret_nou,@pret_stoc_anterior as pret_ant,@Valoare_prest as val_prest,	@valLeiFaraTaxe as valleifarataxe							 
			end		
			
			if @RPGreu=1--daca se face repartizare pe greutate
			begin 
				if @greutateSP_c<=0 
					begin
					raiserror('Pentru repartizarea pe greutate trebuie ca toate pordusele de pe receptie sa aiba completat in nomenclator greutatea specifica!!',11,1)
					end
			    set @procent_greutate=(@greutateSP_c*@cantitate_c*100)/@greutate_totala
				set @pret_stoc_nou=round(@pret_stoc_anterior+@procent_greutate*@Valoare_prest/100/@cantitate_c,5)
			end
--select 'UPDATE',	@pret_stoc_nou		
			if @pret_stoc_nou is null 
				raiserror('Pretul de stoc optinut este null,exista probleme de date!!!',11,1)
				
			update pozdoc set Pret_de_stoc=@pret_stoc_nou
			where tip='RM' and Numar=@Numar and data=@Data and Numar_pozitie=@numar_pozitie_c			
			
			set @dif_pret_stoc=@pret_stoc_nou-@pret_stoc_anterior
			
		end						    
		
		if @valLeiFaraTaxe=0 and (@Valoare_prest<>0 or @cantitate_totala<>0)
			update pozdoc set Pret_de_stoc=@Valoare_prest/@cantitate_totala,Accize_datorate=Cantitate*@Valoare_prest/@cantitate_totala
			where tip='RM' and Numar=@Numar and data=@Data and Numar_pozitie=@numar_pozitie_c	
			
		if @ACTNOMINT=1
			update nomencl set Pret_in_valuta=@pret_stoc_nou/(case when @valuta_c<>'' then @curs_c else 1 end),
							   Pret_stoc=@pret_stoc_nou
			where cod=@cod_c	
			
		if @pretValuta_c>0
			update pozdoc set Accize_datorate=Accize_datorate+Cantitate*@dif_pret_stoc
			where tip='RM' and Numar=@Numar and data=@Data and Numar_pozitie=@numar_pozitie_c
		
		set @val_comisionar=@val_comisionar+(select accize_datorate from pozdoc where Numar=@numar and data=@data and Numar_pozitie=@numar_pozitie_c)					   	
		
		if not(@RPGreu=1 and @greutateSP_c=0)
			set @ultim_nr_pozitie=@numar_pozitie_c
	
	fetch next from prestari 
               into @nrDVi_c,@pretStoc_c,@pretValuta_c,@discount_c,@valuta_c,@curs_c,@greutateSP_c ,@numar_pozitie_c,@cantitate_c,@cod_c                            
	end                     
    close prestari                   
    deallocate prestari
    
    if @CodPS =1 
		update pozdoc  set Cod_intrare=Pret_de_stoc
		where Subunitate=@Sb and Numar=@numar and data=@Data 
		  and (Cod=@Cod_prest or isnull(@Cod_prest,'')='')
		  and (select n.tip from nomencl n where n.cod=cod)<>'F'
		  
	update pozdoc set Accize_datorate=Accize_datorate+(@Valoare_prest-@val_comisionar)
	where Subunitate=@Sb and Numar=@numar and data=@Data and tip='RM'
      and (Cod=@Cod_prest or isnull(@Cod_prest,'')='')
	
	end	  
	--SET Context_Info 0x55556
	COMMIT TRANSACTION 
--->>>>>stop repartizare valoare prestare pe pozitii receptie<<<<<---
	declare @docXMLIaPozdoc xml
	set @docXMLIaPozdoc = '<row subunitate="' + rtrim(@sb) + '" tip="' + rtrim('RM') + '" numar="' + rtrim(@numar) + '" data="' + convert(char(10), @data, 101) +'"/>'
	exec wIaPozdoc @sesiune=@sesiune, @parXML=@docXMLIaPozdoc	

end try

begin catch
	declare @mesaj varchar(255)
		set @mesaj=ERROR_MESSAGE() 
		raiserror(@mesaj, 11, 1)
end catch
end