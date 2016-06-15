/* operatie pt. scriere inregistrare NC salarii */
Create procedure scriuNCsalarii
	@Data datetime, @ContDebitor varchar(20), @ContCreditor varchar(20), @Suma decimal(12,2), @NumarDoc varchar(10), 
	@Explicatii varchar(50), @Continuare int output, @NrPozitie int output, @Loc_de_munca varchar(9), 
	@Comanda char(20), @IndBug varchar(20), @AnaliticLm int, @Marca varchar(6), @AnaliticSomesana varchar(9), @NCticheteCM int, @idDiurna int=0, @detalii xml=null
As
Begin try
declare @Sub char(9), @NCIndBug int, @NCLMNivel int, @NCRetDecont int, @lJurnal int, @cJurnal char(9), 
	@nValidareStrictaComenzi int, @ValidareStrictaComenzi int, @ComandaGenerica varchar(20), @SomesanaMures int, @Euromedia int, @LocmDoc char(9), @LocmMures varchar(9),
	@ContDebitDoc varchar(20), @IndBugDoc char(20), @ComandaDoc char(40), @Tert varchar(13), @NumarDocFF varchar(10), @NumarDocPF varchar(10), 
	@GasitLM int, @GasitContDebitDoc int, @AnContDebitDoc int, @AtribContDebitDoc int, @GasitContCreditDoc int, @AnContCreditDoc int, @AtribContCreditDoc int,
	@Utilizator char(10), @mesajEroare varchar(254), @DateTichete char(20), @GestiuneTichete char(9), @CodTichete char(20)

select 
	@Sub=max(case when Parametru='SUBPRO' then Val_alfanumerica else '' end),
	@NCIndBug=max(case when Parametru='NC-INDBUG' then Val_logica else 0 end),
	@NCLMNivel=max(case when Parametru='N-C-NIVLM' then Val_logica else 0 end),
	@NCRetDecont=max(case when Parametru='NC-RET-M' then Val_logica else 0 end),
	@lJurnal=max(case when Parametru='JURNAL' then Val_logica else 0 end),
	@cJurnal=max(case when Parametru='JURNAL' then Val_alfanumerica else '' end),
	@nValidareStrictaComenzi=max(case when Parametru='COMANDA' then Val_numerica else 0 end),
	@ComandaGenerica=max(case when Parametru='COMANDAG' then Val_alfanumerica else '' end),
	@SomesanaMures=max(case when Parametru='NC-SMURES' then Val_logica else 0 end),
	@Euromedia=max(case when Parametru='EUROMED' then Val_logica else 0 end),
	@DateTichete=max(case when Parametru='NC-TICHM' then Val_alfanumerica else '' end)
from par 
where tip_parametru='GE' and parametru in ('SUBPRO','COMANDA','COMANDAG')
	or tip_parametru='PS' and parametru in ('NC-INDBUG','N-C-NIVLM','NC-RET-M','JURNAL','NC-SMURES','NC-TICHM')
	or tip_parametru='SP' and parametru in ('EUROMED')

set @ValidareStrictaComenzi=max(case when @nValidareStrictaComenzi=1 then 1 else 0 end)
select @cJurnal=(case when @lJurnal=1 then @cJurnal else '' end)
set @GestiuneTichete=(case when @DateTichete='' then '' else left(@DateTichete,charindex(',',@DateTichete)-1) end)
set @CodTichete=(case when @DateTichete='' then '' else substring(@DateTichete,charindex(',',@DateTichete)+1,20) end)

set @Utilizator=dbo.fIaUtilizator(null)
select @LocmDoc='', @Tert='', @NumarDocPF='', @NumarDocFF='', @GasitContDebitDoc=0, @GasitContCreditDoc=0, @mesajEroare=''
select @GasitLM=isnull((select count(1) from lm where cod=@loc_de_munca),0)
set @IndBugDoc=@IndBug
select @IndBugDoc=ltrim(rtrim(Comanda))+substring(@IndBug,9,20) from speciflm 
where @NCIndBug=1 and Loc_de_munca=@Loc_de_munca 
	and Comanda<>'' and @IndBugDoc<>''
if @ValidareStrictaComenzi=1 and @Comanda='' and @NCIndBug=0 --and 1=0
	set @Comanda=@ComandaGenerica

set @ComandaDoc=@Comanda+@IndBugDoc
--	verificare daca locul de munca este valid
if @Loc_de_munca<>'' and @Suma<>0
Begin
	set @LocmDoc=@Loc_de_munca
	if @GasitLM=0
	Begin
		select @Continuare=0
		set @mesajEroare='Locul de munca '+rtrim(@LocmDoc)+' nu este valid. Adaugati-l in macheta de locuri de munca sau corectati datele!'
		RAISERROR (@mesajEroare, 16, 1)
--		rollback transaction
		return
	End
--	formare loc de munca si indicator bugetar de completat pe document
	if @GasitLM=1 and @NCLMNivel=0
	Begin
		while not(isnull((select costuri from strlm where nivel=(select nivel from lm where cod=@LocmDoc)),0)=1 or 
		isnull((select nivel from strlm where nivel=(select nivel from lm where cod=@LocmDoc)-1),0)=0)
		Begin
			select @LocmDoc=left(@LocmDoc,isnull((select lungime from strlm where nivel=(select nivel from lm where cod=@LocmDoc)-1),0))
			select @IndBugDoc=ltrim(rtrim(Comanda))+substring(@IndBug,9,20) from speciflm where @NCIndBug=1 and Loc_de_munca=@LocmDoc
			and Comanda<>'' and @IndBugDoc<>''
			set @ComandaDoc=@Comanda+@IndBugDoc
		End		
	End
--	specific Somesana
	select @LocmDoc='10' where (@AnaliticSomesana='.5' or @AnaliticSomesana='.7') and left(@LocmDoc,1)='1'
	select @LocmMures=(case when @LocmDoc in ('41','42') then '40' when @LocmDoc='43' then '42' when @LocmDoc='46' then '44'
		when @LocmDoc='47' then '43' when @LocmDoc='48' then '45' when @LocmDoc='49' then '46'
		when @LocmDoc='50' then '47' when @LocmDoc='52' then '48' else @LocmDoc end) 
	where @SomesanaMures=1
End
if (@Loc_de_munca='' or @GasitLM=1) and @Suma<>0
Begin
--	formare cont debitor de completat pe document
	set @ContDebitDoc=rtrim(@ContDebitor)
		+(case when @AnaliticLm=1 and left(@ContDebitor,1)='6' then '.'+(case when @SomesanaMures=1 then @LocmMures else left(@LocmDoc,9) end)
		+(case when @AnaliticSomesana<>'' then @AnaliticSomesana else '' end) else '' end)
--	scriere documente
	if @ContDebitor<>'' and @ContCreditor<>'' and abs(@Suma)>=0.01
	Begin
		select @GasitContDebitDoc=(case when @ContDebitDoc=isnull(Cont,'') then 1 else 0 end), @AnContDebitDoc=isnull(convert(int,Are_analitice),0), 
			@AtribContDebitDoc=isnull((case when sold_credit>10 then 0 else sold_credit end),0) from conturi where Subunitate=@Sub and Cont=@ContDebitDoc
		select @GasitContCreditDoc=(case when @ContCreditor=isnull(Cont,'') then 1 else 0 end), @AnContCreditDoc=isnull(convert(int,Are_analitice),0), 
			@AtribContCreditDoc=isnull((case when sold_credit>10 then 0 else sold_credit end),0) from conturi where Subunitate=@Sub and Cont=@ContCreditor

		if @GasitContDebitDoc=1 and @AnContDebitDoc=0 and  @GasitContCreditDoc=1 and @AnContCreditDoc=0
		Begin
			if @NCticheteCM=0
			Begin
				if @Euromedia=1
				Begin
					select @NrPozitie=@NrPozitie+1
/*					exec scriuPozncon @Sub, 'PS', @NumarDoc, @Data, @ContDebitDoc, @ContCreditor, 
						@Suma, '', 0, 0, @Explicatii, @Utilizator, @NrPozitie, @LocmDoc, @ComandaDoc, '', @cJurnal
*/
					insert into #docPozncon (Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Explicatii, Nr_pozitie, Loc_munca, Comanda, Jurnal)
					values (@Sub, 'PS', @NumarDoc, @Data, @ContDebitDoc, @ContCreditor, @Suma, @Explicatii, @NrPozitie, @LocmDoc, @ComandaDoc, @cJurnal)
						
				End
				if @Euromedia=0 and not(@NCRetDecont=1 and (@AtribContDebitDoc=9 or @AtribContCreditDoc=9)) 
					and not(@AtribContDebitDoc=1) and not(@AtribContCreditDoc=1)
				Begin
/*					exec scriuPozncon @Sub, 'PS', @NumarDoc, @Data, @ContDebitDoc, @ContCreditor, 
						@Suma, '', 0, 0, @Explicatii, @Utilizator, @NrPozitie, @LocmDoc, @ComandaDoc, '', @cJurnal
*/
					insert into #docPozncon (Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Explicatii, Nr_pozitie, Loc_munca, Comanda, Jurnal, detalii)
					values (@Sub, 'PS', @NumarDoc, @Data, @ContDebitDoc, @ContCreditor, @Suma, @Explicatii, @NrPozitie, @LocmDoc, @ComandaDoc, @cJurnal, @detalii)

					select @NrPozitie=@NrPozitie+1
				End
				if @Euromedia=0 and @NCRetDecont=1 and (@AtribContDebitDoc=9 or @AtribContCreditDoc=9)
				Begin
/*					exec scriuPozplin @ContCreditor, @Data, @NumarDoc, 'PD', '', '', @ContDebitDoc, @Suma, 
						'', 0, 0, 0, 0, @Explicatii, @LocmDoc, @ComandaDoc, @Utilizator, @NrPozitie, @cJurnal, @Marca, @NumarDoc, '01/01/1901'
*/
					insert into #docPozplin (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma,	
						Explicatii, Loc_de_munca, Comanda, Numar_pozitie, Cont_dif, Jurnal, idDiurna)
					values (@Sub, @ContCreditor, @Data, @NumarDoc, 'PD', '', '', @ContDebitDoc, @Suma, @Explicatii, @LocmDoc, @ComandaDoc, 
						@NrPozitie, @Marca, @cJurnal, @idDiurna)

					select @NrPozitie=@NrPozitie+1
				End
				if @Euromedia=0 and @AtribContCreditDoc=1
				Begin
					select @Tert='M'+@Marca
					select @NumarDocFF=isnull((select top 1 convert(char(3),convert(int,right(rtrim(Numar_document),1))+1) from #docPozadoc --pozadoc 
					where subunitate=@Sub and tip='FF' and data=@Data and Numar_document like rtrim(@NumarDoc)+'%' order by Numar_pozitie desc),1)
					select @NumarDocFF=rtrim(@NumarDoc)+@NumarDocFF
/*					exec scriuPozadoc @NumarDocFF output, @Data, 'FF', @Tert, '', @ContDebitDoc, @NumarDoc, @ContCreditor, @Suma, 
						'', 0, 0, 0, 0, @Explicatii, @NrPozitie, '', @LocmDoc, @ComandaDoc, @Utilizator, @cJurnal, @Data, @Data, 0, '', 0, 0, 0
*/
					insert into #docPozadoc (Subunitate, Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, Cont_cred, Suma, TVA11, TVA22, 
						Numar_pozitie, Explicatii, Loc_munca, Comanda, Data_fact, Data_scad, Jurnal)
					values (@Sub, @NumarDocFF, @Data, @Tert, 'FF', '', @NumarDoc, @ContDebitDoc, @ContCreditor, @Suma, 0, 0, @NrPozitie, 
						@Explicatii, @LocmDoc, @ComandaDoc, @Data, @Data, @cJurnal)	

					select @NrPozitie=@NrPozitie+1
				End
				if @Euromedia=0 and @AtribContDebitDoc=1
				Begin
					select @Tert='M'+@Marca
					select @NumarDocPF=isnull((select top 1 convert(char(3),convert(int,right(rtrim(Numar),1))+1) from pozplin 
					where subunitate=@Sub and Cont=@ContCreditor and data=@Data and Numar like rtrim(@NumarDoc)+'%' and Plata_incasare='PF' order by Numar_pozitie desc),1)
					select @NumarDocPF=rtrim(@NumarDoc)+@NumarDocPF
/*
					exec scriuPozplin @ContCreditor, @Data, @NumarDocPF, 'PF', @Tert, @NumarDoc, @ContDebitDoc, @Suma, '', 0, 0, 0, 0, 
						@Explicatii, @LocmDoc, @ComandaDoc, @Utilizator, @NrPozitie, @cJurnal, @Marca, @NumarDoc, '01/01/1901'
*/
					insert into #docPozplin (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, Explicatii, 
						Loc_de_munca, Comanda, Numar_pozitie, Cont_dif, Jurnal, idDiurna)
					values (@Sub, @ContCreditor, @Data, @NumarDocPF, 'PF', @Tert, @NumarDoc, @ContDebitDoc, @Suma, @Explicatii, @LocmDoc, @ComandaDoc, 
						@NrPozitie, @Marca, @cJurnal, 0)

					select @NrPozitie=@NrPozitie+1
				End
			End
			Else
--				exec scriuCMTichete @Data, @NumarDoc, @ContDebitDoc, @Suma, @LocmDoc, @ComandaDoc, @cJurnal
				insert into #docPozdoc (Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Cont_corespondent, Numar_pozitie, Loc_de_munca, Comanda, Jurnal)
				values (@Sub, 'CM', @NumarDoc, @CodTichete, @Data, @GestiuneTichete, @Suma, @ContDebitDoc, @NrPozitie, @LocmDoc, @ComandaDoc, @cJurnal)

		End
		if @GasitContDebitDoc=0 or @AnContDebitDoc=1 or  @GasitContCreditDoc=0 or @AnContCreditDoc=1
		Begin
			set @Continuare=0
			if @GasitContDebitDoc=0
			Begin
				set @mesajEroare='Cont debitor '+rtrim(@ContDebitDoc)+' inexistent!'
				RAISERROR (@mesajEroare, 16, 1)
			End	
			if @AnContDebitDoc=1
			Begin
				set @mesajEroare='Cont debitor '+rtrim(@ContDebitDoc)+' are analitice!'
				RAISERROR (@mesajEroare, 16, 1)
			End	
			if @GasitContCreditDoc=0
			Begin
				set @mesajEroare='Cont creditor '+rtrim(@ContCreditor)+' inexistent!'
				RAISERROR (@mesajEroare, 16, 1)
			End	
			if @AnContCreditDoc=1
			Begin
				set @mesajEroare='Cont creditor '+rtrim(@ContCreditor)+' are analitice!'
				RAISERROR (@mesajEroare, 16, 1)
			End	
			rollback transaction
			return
		End
	End
End
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura scriuNCsalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
