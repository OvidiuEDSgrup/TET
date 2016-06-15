create procedure [dbo].[DescarcBon] @CasaBon int,@VanzBon char(10),@DataBon datetime,@NumarBon int,@GestBon char(9),@PtTE int,@Corel int,@PrefixAC char(3)
as
declare @nF int,@Sb char(9),@Serii int,
	@DetBon int,@Gestiuni char(202),@AreListaGestiuni int, @NuTEAC int,@IgnStGest int,@CodINouTE int,
	@Cust8 int,@Excep8 int,@OrdGest int,@TipG char(1),
	
	@Incas int,@Casa int,@Data datetime,@NrBon int,@Vanz char(10),@NrLin int,
	@TipDoc char(2),@Client char(13),@Cod char(20),@AreSerii int,@Serie char(20),@Coef float,@Cant float,
	@CotaTVA float,@SumaTVA float,@Pret float,@Disc float,@Barcod char(20),@TipNom char(1),
	@LM char(20),@Com char(20),@DScad datetime,@CategP char(2),@PctLiv char(20),
	@NrBK char(20),@Jurn char(3),@AP418 int,@CtFact char(13),
	
	@ExcGest char(30),@ExcCont char(13),
	@GestSt char(9),@CodISt char(20),@Stoc float,@StCl8 int,@ExcCl8 int,@ContOrd char(13),@SerieSt char(20),
	@CantRam float,@CantDesc float,@NrDoc char(8),@NrTE char(8),@NrRM char(8),@CodIPrim char(13),
	@PretDisc float,@PValuta float,@PVanz float,@PretAm float,@TVAunit float,
	@TVAPoz float,@TVADesc float,@CantExc8 float,@CtStoc char(13),@PStoc float,@TertRM char(13),
	@CasaAnt int,@DataAnt datetime,@NrBonAnt int,@VanzAnt char(10)

exec luare_date_par 'GE','SUBPRO',0,0,@Sb output
exec luare_date_par 'GE','SERII',@Serii output,0,''
exec luare_date_par 'PO','DETBON',@DetBon output,0,''
exec luare_date_par 'PG',@GestBon,0,0,@Gestiuni output
if charindex(';'+RTrim(@GestBon)+';',';'+RTrim(@Gestiuni)+';')=0
	set @Gestiuni=RTrim(@GestBon)+';'+RTrim(@Gestiuni)
set @AreListaGestiuni=(case when LTrim(RTrim(replace(replace(';'+RTrim(@Gestiuni)+';', ';'+RTrim(@GestBon)+';', ';'), ';', '')))='' then 0 else 1 end)
exec luare_date_par 'PO','NUTEAC',@NuTEAC output,0,''
exec luare_date_par 'PO','NUSTOCTE',@IgnStGest output,0,''
exec luare_date_par 'PO','CODINOUTE',@CodINouTE output,0,''
exec luare_date_par 'PO','CUSTSTCL8',@Cust8 output,0,''
exec luare_date_par 'PO','EXFACTCL8',@Excep8 output,0,''
exec luare_date_par 'PO','ORDGEST',@OrdGest output,0,''

select @TipG=tip_gestiune from gestiuni where subunitate=@Sb and cod_gestiune=@GestBon

declare tmpbon cursor for 
select (case when b.tip in ('11','21') and b.cod_produs<>'' then 0 else 1 end),b.casa_de_marcat,b.data,b.numar_bon,b.vinzator,b.numar_linie,
(case when b.tip='11' then 'TE' when b.factura_chitanta=1 then 'AC' else 'AP' end),b.client,b.cod_produs,
(case when @Serii=1 and left(isnull(n.UM_2,''),1)='Y' then 1 else 0 end),b.numar_document_incasare,
(case b.um when 2 then isnull(n.coeficient_conversie_1,0) when 3 then isnull(n.coeficient_conversie_2,0) else 1 end),
b.cantitate,b.cota_tva,b.tva,b.pret,b.discount,b.codplu,isnull(n.tip,''),
isnull(a.loc_de_munca,isnull(gestcor.loc_de_munca,'')),isnull(a.comanda,''),isnull(a.data_scadentei,dateadd(d, isnull(it.discount, 0), b.data)),isnull(a.categorie_de_pret,0),
isnull(a.punct_de_livrare,''),isnull(a.contract,''),isnull(a.agent,''),(case when left(isnull(a.explicatii,''),1)='1' then 1 else 0 end)
from bt b
left outer join pvbon a on b.casa_de_marcat=a.casa_de_marcat and b.factura_chitanta=a.chitanta and a.numar_bon=b.numar_bon
left outer join gestcor on gestcor.gestiune=b.loc_de_munca
left outer join nomencl n on n.cod=b.cod_produs
left outer join infotert it on b.tip<>'11' and b.factura_chitanta=0 and it.subunitate=@Sb and it.tert=b.client and it.identificator=''
where (@CasaBon=0 or b.casa_de_marcat=@CasaBon) and (@VanzBon='' or b.vinzator=@VanzBon) 
and b.data between (case when @Corel=1 then '01/01/1901' else @DataBon end) and @DataBon
and (@Corel=1 or b.numar_bon<=@NumarBon) and b.loc_de_munca=@GestBon 
and b.tip between (case when @PtTE=1 then '11' else '21' end) and (case when @PtTE=1 then '11' else 'ZZ' end)

open tmpbon
fetch next from tmpbon into @Incas,@Casa,@Data,@NrBon,@Vanz,@NrLin,@TipDoc,@Client,@Cod,@AreSerii,@Serie,@Coef,@Cant,@CotaTVA,@SumaTVA,@Pret,@Disc,@Barcod,@TipNom,@LM,@Com,@DScad,@CategP,@PctLiv,@NrBK,@Jurn,@AP418
select @CasaAnt=@Casa,@DataAnt=@Data,@NrBonAnt=@NrBon,@VanzAnt=@Vanz
set @nF=@@fetch_status

while @nF=0
begin
	set @Cant=round(convert(decimal(15,5),@Cant*@Coef),3)
	set @Pret=(case when @Coef=0 then 0 else round(convert(decimal(15,5),@Pret/@Coef),5) end)
	set @CantExc8=0
	if @Incas=0 and not (@TipDoc='AC' and @TipG='V')
	begin
		set @Serie=(case when @TipNom='S' or @AreSerii=1 then @Serie else '' end)
		set @CantRam=@Cant
		set @CtFact=(case when @TipDoc='AP' and @AP418=1 then '418' else '' end)
		set @PretDisc=round(convert(decimal(15,5),@Pret*(1-@Disc/100)),5)
		if @TipDoc<>'AP' --la facturi nu mai rotunjim pretul...
			if exists (select 1 from sysobjects where type in ('FN','IF') and name='rot_pret')
				set @PretDisc=dbo.rot_pret(@PretDisc,0)
			else
				set @PretDisc=round(@PretDisc,2)
		set @PValuta=(case when @TipDoc='AC' then round(convert(decimal(15,5),@Pret/(1+@CotaTVA/100)),5) else @Pret end)
		set @TVAunit=round(convert(decimal(15,4),@PretDisc*@CotaTVA/(100+(case when @TipDoc='AC' then @CotaTVA else 0 end))),2)
		set @PVanz=@PretDisc-(case when @TipDoc='AC' then @TVAunit else 0 end)
		set @PretAm=round(convert(decimal(15,4),@PretDisc+(case when @TipDoc='AP' then @TVAunit else 0 end)),2)
		set @TVADesc=0
		
		set @NrDoc=left((case when @TipDoc in ('AP','TE') then LTrim(Str(@NrBon)) when @TipDoc='AC' and @DetBon=1 then RTrim(@PrefixAC)+right(replace(str(@NrBon),' ','0'),5) else 'B'+LTrim(str(day(@Data)))+'G'+rtrim(@GestBon) end),8)
		set @ExcGest=RTrim(case when @TipDoc='TE' then @Client else '' end)+';'+RTrim(case when @AreListaGestiuni=1 and @IgnStGest=1 then @GestBon else '' end)
		set @ExcCont=RTrim(case when @Excep8=1 and @TipDoc<>'AC' then '8' else '' end)
		set @ContOrd=RTrim(case when @Excep8=1 and @TipDoc='AC' then '8' else '' end)
		
		while abs(@CantRam)>=0.001
		begin
			set @GestSt=null
			if @TipNom<>'S' begin
				exec iauPozitieStoc @Cod, '', @GestSt output, null, @CodISt output, @PStoc output, @Stoc output, @CtStoc output, null, null, null, null, @SerieSt output, 
					'', @Gestiuni, @ExcGest, @Data, '', @ExcCont, null, null, null, null, null, null, null, @Serie, 
					@ContOrd, @OrdGest
			end
			if @GestSt is null begin
				set @GestSt=@GestBon
				set @CodISt=(case when @TipNom<>'S' then '' else @Serie end)
				set @PStoc=@ExcCont
				set @Stoc=@CantRam
				set @CtStoc=''
				set @SerieSt=(case when @TipNom<>'S' then @Serie else '' end)
			end
			set @StCl8=(case when @Cust8=1 and left(@CtStoc,1)='8' then 1 else 0 end)
			set @ExcCl8=(case when @Excep8=1 then (case when left(@CtStoc,1)='8' then 1 else 2 end) else 0 end)
			
			if @CantRam>=0.001 and @CantRam>@Stoc set @CantDesc=@Stoc
			else set @CantDesc=@CantRam
			
			set @CantRam=@CantRam-@CantDesc
			
			if @TipDoc='TE'
			begin
				exec scriuTE @NrDoc,@Data,@GestSt,@Client,'',@Cod,@CodISt,'',0,@CantDesc,'',0,@CategP,'',0,@LM,@Com,'',@Jurn,5,@Barcod,0,@SerieSt,@Vanz,0,0,0
			end
			if  @StCl8=0 and @TipDoc='AC' and @NuTEAC=0 
			begin
				if @GestSt=@GestBon
					set @GestSt=(select top 1 [dbo].[fStrToken](val_alfanumerica, 1, ';') from par where Tip_parametru='PG' and Parametru=@GestBon)
				set @NrTE=left((case when @DetBon=1 then RTrim(@PrefixAC)+right(replace(str(@NrBon),' ','0'),5) else 'TE'+left(replace(convert(char(10),@Data,103),'/',''),4)+rtrim(@GestSt) end),8)
				set @CodIPrim=''
				exec scriuTE @NrTE,@Data,@GestSt,@GestBon,'',@Cod,@CodISt,@CodIPrim output,@CodINouTE,@CantDesc,'',@Pret,@CategP,'',0,@LM,@Com,'',@Jurn,5,@Barcod,0,@SerieSt,@Vanz,0,0,0
				
				set @GestSt=@GestBon
				set @CodISt=@CodIPrim
				if @ExcCl8=1
					set @CantExc8=@CantExc8+@CantDesc
			end
			if @TipDoc in ('AP','AC') and @StCl8=1
			begin
				set @NrRM=left((case when @TipDoc='AP' then LTrim(Str(@NrBon)) when @TipDoc='AC' and @DetBon=1 then RTrim(@PrefixAC)+right(replace(str(@NrBon),' ','0'),5) else 'RM'+left(replace(convert(char(10),@Data,103),'/',''),4)+rtrim(@GestSt) end),8)
				set @TertRM=isnull((select substring(denumire_gestiune,31,13) from gestiuni where subunitate=@Sb and cod_gestiune=@GestSt),'')
				set @CantDesc=-@CantDesc
				exec scriuReceptie 'RM',@NrRM,@Data,@TertRM,'',@Data,@Data,'','',@GestSt,@Cod,@CodISt,@CtStoc,'',@CantDesc,'',0,@PStoc,0,@Pret,@LM,@Com,'',@Jurn,'',5,@Barcod,0,'01/01/1901',@Vanz,@SerieSt,0,0,0,0,0,0
				
				set @CodIPrim=''
				set @CantDesc=-@CantDesc
				exec scriuReceptie 'RM',@NrRM,@Data,@TertRM,@NrRM,@Data,@Data,'408','',@GestBon,@Cod,@CodIPrim output,'','',@CantDesc,'',0,@PStoc,0,@Pret,@LM,@Com,'',@Jurn,'',5,@Barcod,0,'01/01/1901',@Vanz,@SerieSt,0,0,0,0,0,0
				set @GestSt=@GestBon
				set @CodISt=@CodIPrim
			end
			if @TipDoc='AP' or @TipDoc='AC' and @ExcCl8<>1
			begin
				set @TVAPoz=(case when abs(@CantRam)<0.001 then @SumaTVA-@TVADesc else 0 end)
				exec scriuAviz @TipDoc,@NrDoc,@Data,@Client,@PctLiv,@CtFact,@NrDoc,@Data,@DScad,@GestSt,@Cod,@CodISt,@CantDesc,@PValuta,'',0,@Disc,@PVanz,@CotaTVA,@TVAPoz output,@PretAm,@CategP,@LM,@Com,@NrBK,@Jurn,5,@Barcod,0,0,@SerieSt,@Vanz,0,0,0
				set @TVADesc=@TVADesc+@TVAPoz
			end
			if @TipDoc='AC' and @ExcCl8=1
			begin
				set @TVADesc=@TVADesc+round(convert(decimal(17,4),@CantDesc*@PVanz*@CotaTVA/100),2)
			end
		end
	end
	
	exec MutBTBP @Casa,@Vanz,@Data,@NrBon,@NrLin,@TipDoc,@Incas,@Cant,@CantExc8,@Corel
	
	fetch next from tmpbon into @Incas,@Casa,@Data,@NrBon,@Vanz,@NrLin,@TipDoc,@Client,@Cod,@AreSerii,@Serie,@Coef,@Cant,@CotaTVA,@SumaTVA,@Pret,@Disc,@Barcod,@TipNom,@LM,@Com,@DScad,@CategP,@PctLiv,@NrBK,@Jurn,@AP418
	set @nF=@@fetch_status
	if (@nF<>0 or @CasaAnt<>@Casa or @DataAnt<>@Data or @NrBonAnt<>@NrBon or @VanzAnt<>@Vanz) and exists (select 1 from sysobjects where type='P' and name='DescarcBonSP')
		exec DescarcBonSP @CasaAnt,@DataAnt,@NrBonAnt,@VanzAnt,@TipDoc,@NrDoc
	
	select @CasaAnt=@Casa,@DataAnt=@Data,@NrBonAnt=@NrBon,@VanzAnt=@Vanz
end
close tmpbon
deallocate tmpbon
