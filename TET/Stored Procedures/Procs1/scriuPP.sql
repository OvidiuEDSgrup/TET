--***
create procedure scriuPP @Numar char(8) output, @Data datetime output, @Gestiune char(9), @Cod char(20), @Cantitate float, 
	@CtStoc char(13), @PretStoc float, @CodIntrare char(13) output, @Locatie char(30), @Valuta char(3), @Curs float, 
	@LM char(9), @Comanda char(40), @Tert char(13), @AccCump float, @Suprataxe float, 
	@Serie char(20), @Utilizator char(10), @Jurnal char(3), @Stare int, @Lot char(13), @NrPozitie int=0 output, @PozitieNoua int=0
as
begin
declare @Sb char(9), @Cont711 char(13), @AnLM711 int, @AnCtSt711 int, @DVE int, 
	@RotPretV int, @SumaRotPret float, @StocComP int, 
	@TipNom char(1), @PStocNom float, @PValutaNom float, 
	@PretValuta float, @AnCtStoc char(13), @CtCoresp char(13), 
	@AccDat float, @StersPozitie int,@Serii int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
exec luare_date_par 'GE', 'CONTP', @AnLM711 output, 0, @Cont711 output
exec luare_date_par 'GE', 'ANCTSPRD', @AnCtSt711 output, 0, ''
exec luare_date_par 'GE', 'DVE', @DVE output, 0, ''
exec luare_date_par 'GE', 'ROTPRETV', @RotPretV output, @SumaRotPret output, ''
exec luare_date_par 'GE', 'STOCPECOM', @StocComP output, 0, ''
exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''

exec iauNrDataDoc 'PP', @Numar output, @Data output, 0
if @Stare is null set @Stare=3

set @TipNom=''
set @PStocNom=0
set @PValutaNom=0
select @TipNom=tip, @PStocNom=pret_stoc, @PValutaNom=pret_in_valuta
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

if isnull(@CtStoc, '')=''
	set @CtStoc=dbo.formezContStoc(@Gestiune, @Cod, @LM)

if left(@CtStoc, 1)='8'
	set @CtCoresp=''
if @CtCoresp is null
begin
	set @AnCtStoc=isnull((select max(case when cont_parinte<>'' then substring(@CtStoc, len(cont_parinte)+1, 13) else '' end) from conturi where subunitate=@Sb and cont=@CtStoc), '')
	set @CtCoresp=RTrim(@Cont711)+(case when @AnLM711=1 then '.'+@LM when @AnCtSt711=1 and @TipNom='P' then @AnCtStoc else '' end)
end

set @StersPozitie=0
if isnull(@NrPozitie,0)<>0
begin
	delete pozdoc
	where subunitate=@Sb and tip='PP' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	set @StersPozitie=1
end
else
	select @NrPozitie=numar_pozitie, @CodIntrare=(case when isnull(@CodIntrare, '')='' then cod_intrare else @CodIntrare end)
	from pozdoc
	where isnull(@PozitieNoua,0)=0 and subunitate=@Sb and tip='PP' and numar=@Numar and data=@Data and gestiune=@Gestiune and cod=@Cod 
	and (isnull(@CodIntrare, '')='' or cod_intrare=@CodIntrare)
	and cont_de_stoc=@CtStoc and pret_de_stoc=@PretStoc and cont_corespondent=@CtCoresp 
	and pret_valuta=@PretValuta and valuta=@Valuta and loc_de_munca=@LM and comanda=@Comanda 

if isnull(@NrPozitie,0)=0 or @StersPozitie=1
begin
	if isnull(@CodIntrare, '')=''
		set @CodIntrare=dbo.formezCodIntrare('PP', @Numar, @Data, @Cod, @Gestiune, @CtStoc, @PretStoc)
	set @AccDat=(case when @DVE=1 then 100 else 0 end)
	
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
	(@Sb, 'PP', @Numar, @Cod, @Data, @Gestiune, 0, @PretValuta, @PretStoc, 0, 
	0, 0, 0, 0, isnull(@Utilizator,''), '01/01/1901', '', 
	@CodIntrare, @CtStoc, @CtCoresp, 0, 0, 'I', 
	(case when @StocComP=1 then @Comanda else @Locatie end), @Data, @NrPozitie, @LM, @Comanda, '', 
	'', '', 0, @Tert, '', '', '', 
	@Stare, @Lot, '', @Valuta, @Curs, @Data, @Data, 1, 0, 
	0, @AccDat, '', @Jurnal)
	
	if @StersPozitie=0
		exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null
end

if @Utilizator is null
	set @Utilizator=dbo.fIauUtilizatorCurent()

---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
	begin
	   exec scriuPDserii 'PP', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
	   set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='PP' and Numar=@Numar and data=@Data and Gestiune=@gestiune and cod=@Cod 
															  and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie),0)
	end
----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------

update pozdoc
set cantitate=cantitate+@Cantitate, accize_cumparare=accize_cumparare+@AccCump, suprataxe_vama=suprataxe_vama+@Suprataxe, 
	utilizator=@Utilizator, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), 
	ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
where subunitate=@Sb and tip='PP' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
end

