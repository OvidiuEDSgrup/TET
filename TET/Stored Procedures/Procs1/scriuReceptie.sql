--***
create procedure scriuReceptie @Tip char(2),@Numar char(8) output,@Data datetime output,
	@Tert char(13),@Fact char(20),@DataFact datetime,@DataScad datetime,@CtFact char(13),@CtTVA char(13),
	@Gest char(9),@Cod char(20),@CodIntrare char(13) output,@CtStoc char(13),@Locatie char(30),
	@Cantitate float,@Valuta char(3),@Curs float,@PretFurn float,@Discount float,@PretAmPrim float,@LM char(9),@Comanda char(40),
	@ComAprov char(20),@Jurnal char(3),@DVI char(30),@Stare int,@Barcod char(30),@TipTVA int,@DataExp datetime,
	@Utilizator char(10),@Serie char(20),@NrPozitii int output,@Valoare float output,@ValTVA float output,
	@DiscSuma float output,@ValValuta float output,@TotCant float output,@NrPozitie int=0 output,@CotaTVA float=null,@PozitieNoua int=0,@SumaTVA float=0 output
as

declare @Sb char(9),@TLit int,@TLitR int,@Accize int,@CtAccize char(13),
	@Ct378 char(13),@AnGest378 int,@AnGr378 int,@Ct4428 char(13),@AnGest4428 int,
	@Ct4426 char(13),@Ct4428AV char(13),@DVE int,@AccImpDVI int,@CodVam int,@Bug int,
	@RotPretV int,@SumaRotP float,@PAmFaraTVAnx int,@SCom int,@SFurn int,@CotaTVAGen float,
	@TipN char(1),@CotaTVAN float,@PAmN float,@GrN char(13),@GreutN float,
	@TipTert int,@PStoc float,@TVAnx float,
	@Lot char(13),@CtAdPrim char(13),@CtTVAnxPrim char(13),@Grupa char(13),
	@AccCump float,@StersPozitie int

exec luare_date_par 'GE','SUBPRO',0,0,@Sb output
exec luare_date_par 'GE','TIMBRULIT',@TLit output,0,''
exec luare_date_par 'GE','TIMBRULT2',@TLitR output,0,''
exec luare_date_par 'GE','ACCIZE',@Accize output,0,''
exec luare_date_par 'GE','CACCIZE',0,0,@CtAccize output
exec luare_date_par 'GE','CADAOS',@AnGest378 output,@AnGr378 output,@Ct378 output
exec luare_date_par 'GE','CNTVA',@AnGest4428 output,0,@Ct4428 output
exec luare_date_par 'GE','CDTVA',0,0,@Ct4426 output
exec luare_date_par 'GE','CNEEXREC',0,0,@Ct4428AV output
exec luare_date_par 'GE','DVE',@DVE output,0,''
exec luare_date_par 'GE','ACCIMP',@AccImpDVI output,0,''
exec luare_date_par 'GE','CODVAM',@CodVam output,0,''
exec luare_date_par 'GE','BUGETARI',@Bug output,0,''
exec luare_date_par 'GE','ROTPRETV',@RotPretV output,@SumaRotP output,''
exec luare_date_par 'GE','FARATVANE',@PAmFaraTVAnx output,0,''
exec luare_date_par 'GE','STOCPECOM',@SCom output,0,''
exec luare_date_par 'GE','STOCFURN',@SFurn output,0,''
exec luare_date_par 'GE','COTATVA',0,@CotaTVAGen output,''

if @Tip='RC'
	select @Tip='RM',@Discount=-convert(decimal(12,4),@CotaTVAGen*100/(@CotaTVAGen+100)),@Jurnal='RC'
if isnull(@Tip,'')='' set @Tip='RM'
exec iauNrDataDoc @Tip,@Numar output,@Data output,0
if @Stare is null set @Stare=3

select @TipN='',@CotaTVAN=0,@PAmN=0,@GrN='',@GreutN=0
select @TipN=tip,@CotaTVAN=cota_TVA,@PAmN=pret_cu_amanuntul,@GrN=grupa,@GreutN=greutate_specifica,
	@Barcod=(case when @Tip<>'RS' and @CodVam=1 and @DVI<>'' and tip<>'R' and tip<>'F' then substring(tip_echipament,2,20) else @Barcod end)
from nomencl
where cod=@Cod


set @TipTert=0
select @TipTert=zile_inc
from infotert
where subunitate=@Sb and tert=@Tert and identificator=''

if isnull(@TotCant,0)=0 
	set @TotCant=@Cantitate
set @AccCump=@TotCant


set @PStoc=convert(decimal(17,5),(@PretFurn-(case when @TLit=1 or @TLitR=1 then @GreutN else 0 end))*(1+@Discount/100)*(case when @Valuta<>'' then @Curs else 1 end))
if (@Cantitate<=-0.001) and isnull(@CodIntrare,'')=''
begin
	declare @TipGest char(1)
	set @TipGest=isnull((select tip_gestiune from gestiuni where subunitate=@Sb and cod_gestiune=@Gest),'')
	select top 1 @CodIntrare=cod_intrare,@CtStoc=(case when isnull(@CtStoc,'')='' then cont else @CtStoc end),
		@PretAmPrim=(case when isnull(@PretAmPrim,0)=0 then pret_cu_amanuntul else @PretAmPrim end)
	from stocuri
	where subunitate=@Sb and tip_gestiune=@TipGest and cod_gestiune=@Gest and cod=@Cod
	and (isnull(@CtStoc,'')='' or cont=@CtStoc) and abs(pret-@PStoc)<0.00001
	and (@TipGest<>'A' or isnull(@PretAmPrim,0)=0 or abs(pret_cu_amanuntul-@PretAmPrim)<0.00001)
	and stoc-abs(@Cantitate)>=0.001 and data<=@Data and (@SFurn=0 or furnizor='' or furnizor=@Tert)
	order by (case when @SFurn=1 and furnizor<>'' then 0 else 1 end),data
end
if isnull(@PretAmPrim,0)=0
	set @PretAmPrim=(case when @TipN='R' then 0 else @PAmN end)
if isnull(@CtStoc,'')=''
	set @CtStoc=dbo.formezContStoc(@Gest,@Cod,@LM)

if isnull(@CtFact,'')='' or left(@CtStoc,1)='8'
	set @CtFact=(case when left(@CtStoc,1)='8' then '' else isnull((select max(cont_ca_furnizor) from terti where subunitate=@Sb and tert=@Tert),'') end)

if @CotaTVA is null
	set @CotaTVA=(case when @DVE=1 and @Tip<>'RS' and @DVI<>'' or not (left(@CtStoc,1)='8' or @Tip<>'RS' and @TipTert<>0 and @DVI<>'' and @Valuta<>'') then @CotaTVAN else 0 end)
if @Valuta<>'' and (@Tip='RS' or @DVI='') and @RotPretV=1 and abs(@SumaRotP)>=0.00001 and exists (select 1 from sysobjects where type in ('FN','IF') and name='rot_pret')
	set @PStoc=dbo.rot_pret(@PStoc,@SumaRotP)

set @StersPozitie=0
if isnull(@NrPozitie,0)<>0
begin
	delete pozdoc
	where subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	set @NrPozitii=@NrPozitii+@@ROWCOUNT
	set @StersPozitie=1
end
else
	select @NrPozitie=numar_pozitie,@CodIntrare=(case when isnull(@CodIntrare,'')='' then cod_intrare else @CodIntrare end)
	from pozdoc
	where isnull(@PozitieNoua,0)=0 and subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data and gestiune=@Gest and cod=@Cod
	and (isnull(@CodIntrare,'')='' or cod_intrare=@CodIntrare)
	and pret_valuta=@PretFurn and discount=@Discount and cota_TVA=@CotaTVA and pret_cu_amanuntul=@PretAmPrim
	and cont_de_stoc=@CtStoc and cont_factura=@CtFact and loc_de_munca=@LM and comanda=@Comanda and factura=@Fact and contract=@ComAprov
	and (isnull(@Locatie,'')='' or locatie=@Locatie)

if isnull(@NrPozitie,0)=0 or @StersPozitie=1
begin
	if isnull(@CodIntrare,'')=''
		set @CodIntrare=dbo.formezCodIntrare(@Tip,@Numar,@Data,@Cod,@Gest,@CtStoc,@PStoc)
	
	set @TVAnx=(case when @PAmFaraTVAnx=1 or @TipN='R' then 0 else @CotaTVAN end)
	if @Barcod is null set @Barcod=''
	if @Lot is null set @Lot=''
	set @CtTVAnxPrim=(case when @Bug=0 and @TipN='F' then '' when @Bug=0 then RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(@Gest) else '' end) when @TipN='O' then '311' when @TipN<>'F' then '' when left(@CtStoc,2)='02' then '312' else '309' end)
	set @CtAdPrim=(case when @TipN='F' then '' else RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(@Gest) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrN) else '' end) end)
	set @CtTVA=(case when left(@CtStoc,1)='8' then '' when isnull(@CtTVA,'')='' then (case when left(@CtFact,3)='408' then @Ct4428AV else @Ct4426 end) else @CtTVA end)
	set @Grupa=(case when @DVE=1 and @Tip<>'RS' and @DVI<>'' then '' when @TLitR=1 then @CtAccize else '' end)
	set @AccCump=(case when @TipN<>'F' and (@TLit=1 or @TLitR=1) then @GreutN else @AccCump end)
	if isnull(@DataExp,'01/01/1901')<='01/01/1901'
		set @DataExp=@Data
	if @StersPozitie=0
	begin
		exec luare_date_par 'DO','POZITIE',0,@NrPozitie output,''
		set @NrPozitie=@NrPozitie+1
	end
	
	insert pozdoc
	(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,
	Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,
	Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,
	Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,
	Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,Contract,Jurnal)
	values
	(@Sb,@Tip,@Numar,@Cod,@Data,@Gest,0,@PretFurn,@PStoc,(case when @PStoc>0 then round(convert(decimal(10,3),(@PretAmPrim/(1+@TVAnx/100)/@PStoc-1)*100),2) else 0 end),
	0,@PretAmPrim,0,@CotaTVA,isnull(@Utilizator,''),'01/01/1901','',
	@CodIntrare,@CtStoc,@Lot,@TVAnx,0,(case when isnull(@TipN,'')='R' then 'V' else 'I' end),@Locatie,@DataExp,
	@NrPozitie,@LM,@Comanda,@Barcod,@CtTVAnxPrim,@CtTVA,@Discount,@Tert,@Fact,@CtAdPrim,@DVI,
	@Stare,@Grupa,@CtFact,@Valuta,@Curs,@DataFact,@DataScad,@TipTVA,0,0,0,@ComAprov,@Jurnal)
	
	if @StersPozitie=0
		exec setare_par 'DO','POZITIE',null,null,@NrPozitie,null
	set @NrPozitii=@NrPozitii+1
end

if ISNULL(@SumaTVA,0)=0
	set @SumaTVA=(case when @DVE=1 and @Tip<>'RS' and @DVI<>'' then 0 else round(convert(decimal(17,4),@PretFurn*(1+@Discount/100)*(case when @Valuta<>'' then @Curs else 1 end)*@Cantitate*@CotaTVA/100),2) end)

select @Valoare=isnull(@Valoare,0)+round(convert(decimal(17,3),@Cantitate*@PStoc),2),
	@ValTVA=isnull(@ValTVA,0)+@SumaTVA,
	@DiscSuma=isnull(@DiscSuma,0)+(case when left(@CtStoc,1)='8' then round(convert(decimal(17,3),@Cantitate*@PStoc),2) else 0 end),
	@ValValuta=isnull(@ValValuta,0)+(case when @Valuta<>'' then round(convert(decimal(17,3),@Cantitate*@PretFurn*(1+(case when @Tip='RS' or @DVI='' then @Discount else 0 end)/100)+(case when @Valuta<>'' and @Curs>0 then convert(decimal(14,2),@SumaTVA/@Curs) else 0 end)),2) else 0 end),
	--@TotCant=isnull(@TotCant,0)+@Cantitate,
	@Utilizator=isnull(@Utilizator,dbo.fIauUtilizatorCurent())

update pozdoc
set cantitate=cantitate+@Cantitate,TVA_deductibil=TVA_deductibil+@SumaTVA,
	grupa=(case when @DVE=1 and tip<>'RS' and numar_DVI<>'' or @TLitR=1 or not (valuta<>'' and (tip='RS' or numar_DVI='') and curs<>0) then grupa else convert(char(13),convert(decimal(14,2),(TVA_deductibil+@SumaTVA)/@Curs)) end),
	accize_cumparare=accize_cumparare+@AccCump,
	utilizator=@Utilizator,data_operarii=convert(datetime,convert(char(10),getdate(),104),104),ora_operarii=RTrim(replace(convert(char(8),getdate(),108),':',''))
where subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie

exec scriuPDserii @Tip,@Numar,@Data,@Gest,@Cod,@CodIntrare,@NrPozitie,@Serie,@Cantitate,''
