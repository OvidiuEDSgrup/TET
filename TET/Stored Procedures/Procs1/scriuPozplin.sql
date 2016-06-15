--***
create procedure scriuPozplin @Cont char(13), @Data datetime, @Numar char(10) output, @Plata_incasare char(2), @Tert char(13), @Factura char(20), 
	@Cont_corespondent char(13), @Suma float, @Valuta char(3), @Curs float, @Suma_valuta float, 
	@TVA11 float, @TVA22 float, @Explicatii char(50), @LM char(9), @Comanda char(40), @Utilizator char(10), 
	@Numar_pozitie int output, @Jurnal char(3), @Marca char(6)='', @DecontEfect char(13)='' output, @DataScadDecEf datetime='01/01/1901',@Ext_datadocument datetime=@Data
as 

if abs(@Suma)<0.01 and abs(@Suma_valuta)<0.01
	return

declare @Sb char(9), @CuDifCurs int, @CtCheltDifcF char(13), @CtVenDifcF char(13), @CtCheltDifcB char(13), @CtVenDifcB char(13), 
	@OpFurn int, @CuFactura int, @ValutaFactura char(3), @CursFactura float, @AtrCt int, @AtrCtC int, 
	@CuDecont int, @ValutaDecont char(3), @CursDecont float, @CuEfect int, @ValutaEfect char(3), @CursEfect float, 
	@ValutaFactDecEf char(3), @CursFactDecEf float, @AchitFact float, @CursValutaFact float, 
	@SumaDif float, @ContDif char(13), @DenCtCoresp char(80), @Nume char(50), @DenTert char(80)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
exec luare_date_par 'GE', 'DIFINR', @CuDifCurs output, 0, ''
exec luare_date_par 'GE', 'DIFCH', 0, 0, @CtCheltDifcF output
exec luare_date_par 'GE', 'DIFVE', 0, 0, @CtVenDifcF output
exec luare_date_par 'GE', 'DIFCHB', 0, 0, @CtCheltDifcB output
exec luare_date_par 'GE', 'DIFVEB', 0, 0, @CtVenDifcB output

if ISNULL(@Numar, '')=''
begin
	if @Plata_incasare in ('IB', 'IC', 'ID')
	begin
		declare @SugerChit int, @AutoChit int, @UltNrChit int
		exec luare_date_par 'GE', 'SUGERCHIT', @SugerChit output, 0, ''
		exec luare_date_par 'GE', 'AUTCH', @AutoChit output, 0, ''
		exec luare_date_par 'GE', 'ULTNRCH', 0, @UltNrChit output, ''
		if @SugerChit=1 and @AutoChit=1
		begin
			set @UltNrChit=@UltNrChit+1
			set @Numar=@UltNrChit
			exec setare_par 'GE', 'ULTNRCH', null, null, @UltNrChit, null
		end
	end
	if ISNULL(@Numar, '')=''
	begin
		declare @IncNrPlin int, @UltNrPlin int
		exec luare_date_par 'GE', 'INCNRPLIN', @IncNrPlin output, 0, ''
		exec luare_date_par 'DO', 'PLATINC', 0, @UltNrPlin output, ''
		if @IncNrPlin=1
		begin
			set @UltNrPlin=@UltNrPlin+1
			set @Numar=@UltNrPlin
			exec setare_par 'DO', 'PLATINC', null, null, @UltNrPlin, null
		end
	end
	set @Numar=isnull(@Numar, '')
end

set @OpFurn=(case when left(@Plata_incasare, 1)='P' and @Plata_incasare<>'PS' then 1 else 0 end)
set @CuFactura=(case when @Plata_incasare in ('PF','PR','PS','IB','IR','IS') then 1 else 0 end)
select @ValutaFactura='', @CursFactura=0, @ValutaDecont='', @CursDecont=0, @ValutaEfect='', @CursEfect=0

select @Cont_corespondent=(case when @Cont_corespondent='' then cont_de_tert else @Cont_corespondent end), 
	@ValutaFactura=valuta, @CursFactura=curs, 
	@LM=(case when isnull(@LM, '')='' then loc_de_munca else @LM end), 
	@Comanda=(case when isnull(@Comanda, '')='' then comanda else @Comanda end)
from facturi
where @CuFactura=1 and subunitate=@Sb and tip=(case when @OpFurn=1 then 0x54 else 0x46 end) and tert=@Tert and factura=@Factura

select @AtrCt=(case when cont=@Cont then sold_credit else @AtrCt end), 
	@AtrCtC=(case when cont=@Cont_corespondent then sold_credit else @AtrCtC end), 
	@DenCtCoresp=(case when cont=@Cont_corespondent then Denumire_cont else @DenCtCoresp end)
from conturi 
where subunitate=@Sb and (cont=@Cont or cont=@Cont_corespondent)

select @CuDecont=(case when @AtrCt=9 or @AtrCtC=9 then 1 else 0 end), 
	@CuEfect=(case when @AtrCt=8 or @AtrCtC=8 then 1 else 0 end)

if @CuDecont=1 and isnull(@DecontEfect, '')=''
	select @DecontEfect=convert(varchar(9), isnull(max(convert(decimal(12,0), decont)), 0) + 1) from deconturi where subunitate=@Sb and tip='T' and marca=@Marca and isnumeric(decont)<>0
if @CuEfect=1 and isnull(@DecontEfect, '')=''
	select @DecontEfect='BO'+convert(varchar(9), isnull(max(convert(decimal(12,0), substring(nr_efect,3,8))), 0) + 1) from efecte where subunitate=@Sb and tip=(case when @OpFurn=1 then 'P' else 'I' end) and tert=@Tert and nr_efect like 'BO%' and isnumeric(substring(nr_efect,3,8))<>0 

if @CuFactura=0 or @CuDecont=1
	set @CuDifCurs=0

select @ValutaDecont=valuta, @CursDecont=curs, 
	@LM=(case when isnull(@LM, '')='' then loc_de_munca else @LM end), 
	@Comanda=(case when isnull(@Comanda, '')='' then comanda else @Comanda end)
from deconturi
where @CuDecont=1 and subunitate=@Sb and tip='T' and marca=@Marca and decont=@DecontEfect

select @ValutaEfect=valuta, @CursEfect=curs, 
	@LM=(case when isnull(@LM, '')='' then loc_de_munca else @LM end), 
	@Comanda=(case when isnull(@Comanda, '')='' then comanda else @Comanda end)
from efecte
where @CuEfect=1 and subunitate=@Sb and tip=(case when @OpFurn=1 then 'P' else 'I' end) and tert=@Tert and nr_efect=@DecontEfect

select @AchitFact=0, @CursValutaFact=0, @SumaDif=0, @ContDif=''

if abs(@Suma_valuta)>=0.01
begin
	if @Valuta=''
		set @Valuta=(case when @CuFactura=1 then @ValutaFactura when @CuDecont=1 then @ValutaDecont when @CuEfect=1 then @ValutaEfect else @Valuta end)
	if @Valuta<>'' and abs(@Curs)<0.0001
		select top 1 @Curs=curs from curs where valuta=@Valuta and data<=@Data order by data DESC
	
	if abs(@Suma)<0.01 and @Valuta<>'' and abs(@Curs)>=0.0001
		set @Suma=round(convert(decimal(18, 5), @Suma_valuta*@Curs), 2)
	
	-- cica nu mai tratam achitarea unei facturi in alta moneda decat a facturii :))
	select @ValutaFactDecEf=(case when @CuFactura=1 then @ValutaFactura when @CuDecont=1 then @ValutaDecont when @CuEfect=1 then @ValutaEfect else '' end)
	select @CursFactDecEf=(case when @CuFactura=1 then @CursFactura when @CuDecont=1 then @CursDecont when @CuEfect=1 then @CursEfect else '' end)
	set @AchitFact=round(convert(decimal(18, 5), (case when @Valuta='' then 0 when (@CuDecont=1 and @Plata_incasare='ID' or @CuFactura=1 and @CuDifCurs=1 or @AtrCt=9 or @AtrCtC<>9) and @ValutaFactDecEf not in ('', @Valuta) and abs(@CursFactDecEf)<>0 then @Suma_valuta*@Curs/@CursFactDecEf else @Suma_valuta end)), 2)
	set @CursValutaFact=round(convert(decimal(11, 5), (case when @Plata_incasare in ('PC', 'IC') then 0 /*e de fapt tip TVA*/ when @Valuta='' then 0 when (@CuDecont=1 and @Plata_incasare='ID' or @CuFactura=1 and @CuDifCurs=1) and @ValutaFactDecEf not in ('', @Valuta) and @AchitFact<>0 then @Curs*@Suma_valuta/@AchitFact else @Curs end)), 4)
	
	if @Valuta<>'' and @CuDifCurs=1
	begin
		set @SumaDif=round(convert(decimal(18, 5), @AchitFact*(@CursValutaFact-@CursFactDecEf)), 2)
		set @ContDif=(case when left(@Plata_incasare, 1)='P' and (@Curs-@CursFactura>=0.0001 or @SumaDif>=0.01) or left(@Plata_incasare, 1)='I' and (@Curs-@CursFactura<=-0.0001 or @SumaDif<=-0.01) then (case when @CtCheltDifcB='' or @Plata_incasare in ('PF', 'PR') then @CtCheltDifcF else @CtCheltDifcB end) else (case when @CtVenDifcB='' or @Plata_incasare in ('PF', 'PR') then @CtVenDifcF else @CtVenDifcB end) end)
	end
end

if substring(@Plata_incasare, 2, 1)='C' and @TVA11<>0 and ISNULL(@TVA22, 0)=0
	set @TVA22=ROUND(convert(decimal(18, 5), @Suma*@TVA11/(100.00+@TVA11)), 2)

if @CuDecont=1
	set @ContDif=@Marca

if ISNULL(@Explicatii, '')=''
begin
	select @Nume=nume from personal where @CuDecont=1 and Marca=@Marca
	select @DenTert=denumire from terti where @CuDecont=0 and (@CuFactura=1 or @AtrCtC=8) and Subunitate=@Sb and Tert=@Tert
	set @Explicatii=isnull(left((case when @CuDecont=1 then @Nume when @CuFactura=1 or @AtrCtC=8 then @DenTert else @DenCtCoresp end), 50), '')
end

if isnull(@Numar_pozitie, 0)<>0
begin
	delete pozplin where subunitate=@Sb and cont=@Cont and data=@Data /*and numar=@Numar*/ and numar_pozitie=@Numar_pozitie
	delete extpozplin where subunitate=@Sb and cont=@Cont and data=@Data /*and numar=@Numar*/ and numar_pozitie=@Numar_pozitie
end
else
begin
	exec luare_date_par 'DO', 'POZITIE', 0, @Numar_pozitie output, ''
	set @Numar_pozitie=@Numar_pozitie+1
	
	while exists (select 1 from pozplin where subunitate=@Sb and Cont=@Cont and data=@Data and numar=@Numar and Numar_pozitie=@Numar_pozitie)
		set @Numar_pozitie=@Numar_pozitie + 1 
	
	exec setare_par 'DO', 'POZITIE', 'Ultim nr. pozitie', 0, @Numar_pozitie, ''
end

declare @Data_operarii datetime, @Ora_operarii char(6) 
set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104) 
set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')
if isnull(@Utilizator, '')='' set @Utilizator=dbo.fIauUtilizatorCurent()

if @CuDecont=1 or @CuEfect=1 or @Plata_incasare='IB'--daca se doreste introducerea datei documentului sa se scrie pozitie in extpozplin
	insert extpozplin
	(Subunitate, Cont, Data, Numar, Numar_pozitie, Tip, Cont_corespondent, Marca, Decont, Data_scadentei, Suma, Suma_achitat, Banca, Cont_in_banca, Numar_justificare, Data_document, Serie_CEC, Numar_CEC, Banca_tert, Cont_in_banca_tert, Jurnal)
	values
	(@Sb, @Cont, @Data, @Numar, @Numar_pozitie, '', '', '', @DecontEfect, @DataScadDecEf, 0, 0, '', '', '', @Ext_datadocument, '', '', '', '', '')

insert into pozplin 
(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, 
Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, 
Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, 
Cont_dif, Suma_dif, Achit_fact, Jurnal)
values 
(@Sb, @Cont, @Data, @Numar, @Plata_incasare, @Tert, @Factura, @Cont_corespondent, 
@Suma, @Valuta, @Curs, @Suma_valuta, @CursValutaFact, @TVA11, @TVA22, @Explicatii, @LM, @Comanda, @Utilizator, 
@Data_operarii, @Ora_operarii, @Numar_pozitie, @ContDif, @SumaDif, @AchitFact, @Jurnal)
