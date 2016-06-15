--***
create procedure scriuAI @Numar char(8) output, @Data datetime output, @Gestiune char(9), @Cod char(20), @Cantitate float, 
	@CodIntrare char(13) output, @CtStoc char(13), @CtCoresp char(13), @PretStoc float, @Valuta char(3), @Curs float, 
	@PretAm float, @CotaTVA float, @Tert char(13), @Locatie char(30), @LM char(9), @Comanda char(40), @Explicatii char(16), 
	@Serie char(20), @Utilizator char(10), @Jurnal char(3), @Stare int, @DataExp datetime, @NrPozitie int=0 output, @PozitieNoua int=0, @Furnizor char(13)='', @TVAnx float=null, @Lot char(13)='', @CantUM2 float=0
as

declare @Sb char(9), @RotPretV int, @SumaRotPret float, @Ct378 char(13), @AnGest378 int, @AnGr378 int, 
	@Ct4428 char(13), @AnGest4428 int, @CtCorespAI char(13), @CuCtIntermAI int, @CtIntermAI char(13), 
	@CtIntermTEVal char(13), @Cust35 int, @Cust8 int, @StocComP int, 
	@TipNom char(1), @PStocNom float, @PValutaNom float, @CotaTVANom float, @PretAmNom float, @GrNom char(13), 
	@PretValuta float, @SumaTVA float, @CtAdaosPrim char(13), @CtTVAnxPrim char(13), 
	@TipMiscare char(1), @CtInterm char(13), @StersPozitie int,@Serii int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
exec luare_date_par 'GE', 'ROTPRETV', @RotPretV output, @SumaRotPret output, ''
exec luare_date_par 'GE', 'CADAOS', @AnGest378 output, @AnGr378 output, @Ct378 output
exec luare_date_par 'GE', 'CNTVA', @AnGest4428 output, 0, @Ct4428 output
exec luare_date_par 'GE', 'CCORAI', 0, 0, @CtCorespAI output
exec luare_date_par 'GE', 'CONT_AI?', @CuCtIntermAI output, 0, ''
exec luare_date_par 'GE', 'CONT_AI', 0, 0, @CtIntermAI output
exec luare_date_par 'GE', 'CALTE', 0, 0, @CtIntermTEVal output
exec luare_date_par 'GE', 'STCUST35', @Cust35 output, 0, ''
exec luare_date_par 'GE', 'STCUST8', @Cust8 output, 0, ''
exec luare_date_par 'GE', 'STOCPECOM', @StocComP output, 0, ''
exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''

exec iauNrDataDoc 'AI', @Numar output, @Data output, 0
if @Stare is null set @Stare=3

set @TipNom=''
set @PStocNom=0
set @PValutaNom=0
set @CotaTVANom=0
set @PretAmNom=0
set @GrNom=''
select @TipNom=tip, @PStocNom=pret_stoc, @PValutaNom=pret_in_valuta, @CotaTVANom=cota_TVA, 
	@PretAmNom=pret_cu_amanuntul, @GrNom=grupa
from nomencl
where cod=@Cod

--daca primim valuta si cursul este diferit de 0, calculam pretul valuta din pret stoc
if isnull(@PretValuta,0)=0 and ISNULL(@PretStoc,0)<>0 and isnull(@Curs,0)>0 and ISNULL(@valuta,'')<>''
	set @PretValuta=@PretStoc/@Curs
else	
	set @PretValuta=(case when @Valuta<>'' then @PValutaNom else 0 end)

if isnull(@PretStoc, 0)=0
begin
	set @PretStoc=(case when @Valuta='' then @PStocNom else round(convert(decimal(18,5), @PretValuta*@Curs), 5) end)
	if @Valuta<>'' and @RotPretV=1 and abs(@SumaRotPret)>=0.00001 and exists (select 1 from sysobjects where type in ('FN', 'IF') and name='rot_pret') 
		set @PretStoc=dbo.rot_pret(@PretStoc, @SumaRotPret) 
end

if isnull(@PretAm, 0)=0
	set @PretAm=@PretAmNom
set @TVAnx=isnull(@TVAnx, @CotaTVANom)
set @SumaTVA=round(convert(decimal(17,4), @PretStoc*@Cantitate*@CotaTVA/100), 2)
set @TipMiscare=(case when @TipNom in ('R', 'S') then 'V' else 'I' end)
set @Lot=isnull(@Lot, '')

if isnull(@CtStoc, '')=''
	set @CtStoc=dbo.formezContStoc(@Gestiune, @Cod, @LM)

set @CtTVAnxPrim=(case when @TipNom='F' then '' else RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(@Gestiune) else '' end) end)
set @CtAdaosPrim=(case when @TipNom='F' then '' else RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(@Gestiune) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end) end)

if isnull(@CtCoresp, '')=''
	set @CtCoresp=(case when @CtCorespAI<>'' then @CtCorespAI when @CuCtIntermAI=1 then @CtIntermAI when @CtIntermTEVal<>'' then RTrim(@CtIntermTEVal)+(case when left(@CtIntermTEVal, 3)='482' then '.'+@Gestiune else '' end) else '7588' end)
set @CtInterm=(case when abs(@SumaTVA)<0.01 then '' when @CuCtIntermAI=1 then @CtIntermAI else @CtTVAnxPrim end)

if @Tert is null or isnull(@Tert, '')<>'' and not (@Cust35=1 and left(@CtCoresp, 2)='35' or @Cust8=1 and left(@CtCoresp, 1)='8' or @TipNom='F')
	set @Tert=''
	
-- de aici
declare @binar varbinary(128)
set @binar=cast('modificarescriuintrare' as varbinary(128))
--set CONTEXT_INFO @binar

set @StersPozitie=0 
if isnull(@NrPozitie, 0)<>0 
begin

	delete pozdoc
	where subunitate=@Sb and tip='AI' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	set @StersPozitie=1
end
else
	select @NrPozitie=numar_pozitie, @CodIntrare=(case when isnull(@CodIntrare, '')='' then cod_intrare else @CodIntrare end)
	from pozdoc
	where isnull(@PozitieNoua,0)=0 and subunitate=@Sb and tip='AI' and numar=@Numar and data=@Data and gestiune=@Gestiune and cod=@Cod 
	and (isnull(@CodIntrare, '')='' or cod_intrare=@CodIntrare)
	and cont_de_stoc=@CtStoc and pret_de_stoc=@PretStoc and cont_corespondent=@CtCoresp 
	and tert=@Tert and pret_valuta=@PretValuta and valuta=@Valuta and loc_de_munca=@LM and comanda=@Comanda 

if isnull(@NrPozitie, 0)=0 or @StersPozitie=1
begin
	if isnull(@CodIntrare, '')=''
		set @CodIntrare=dbo.formezCodIntrare('AI', @Numar, @Data, @Cod, @Gestiune, @CtStoc, @PretStoc)
	if isnull(@DataExp, '01/01/1901')<='01/01/1901'
		set @DataExp=@Data
	
	if @StersPozitie=0
	begin
		exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''
		set @NrPozitie=@NrPozitie+1
	end
	
	insert pozdoc
	(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
	Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
	Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, 
	Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 
	Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
	Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
	Accize_cumparare, Accize_datorate, Contract, Jurnal) 
	values
	(@Sb, 'AI', @Numar, @Cod, @Data, @Gestiune, 0, @PretValuta, @PretStoc, 0, 
	0, @PretAm, 0, @CotaTVA, isnull(@Utilizator,''), '01/01/1901', '', 
	@CodIntrare, @CtStoc, @CtCoresp, @TVAnx, 0, @TipMiscare, 
	(case when @StocComP=1 then @Comanda else @Locatie end), @DataExp, @NrPozitie, @LM, @Comanda, '', 
	@CtInterm, @Furnizor, 0, @Tert, left(@Explicatii, 8), @CtAdaosPrim, '', 
	@Stare, @Lot, @CtTVAnxPrim, @Valuta, @Curs, @Data, @Data, 0, 0, 
	0, 0, substring(@Explicatii, 9, 8), @Jurnal)
	
	if @StersPozitie=0
		exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null
end
--set CONTEXT_INFO 0x00
-- pana aici

if @Utilizator is null
	set @Utilizator=dbo.fIauUtilizatorCurent()
	
---->>>>>>>>start cod specific lucrului pe serii<<<<<<----------------
if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
	begin
	   exec scriuPDserii 'AI', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
	   set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='AI' and Numar=@Numar and data=@Data and Gestiune=@gestiune and cod=@Cod 
															  and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie),0)
	end
----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------	

update pozdoc
set cantitate=cantitate+@Cantitate, TVA_deductibil=TVA_deductibil+@SumaTVA, suprataxe_vama=suprataxe_vama+@CantUM2, 
	accize_cumparare=accize_cumparare+(case when @TipNom='F' then 0 else @Cantitate end), 
	utilizator=@Utilizator, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
where subunitate=@Sb and tip='AI' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie


