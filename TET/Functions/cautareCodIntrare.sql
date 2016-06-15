--***
create function cautareCodIntrare (@Cod char(20), @Gestiune char(9), @TipGestiune char(1), @CodIntrarePred varchar(20), 
@PretStoc float, @PretAmanunt float, @ContStoc char(13), @AcCodIPrimitor int, 
@StocPozitiv int, @DataJosStocuri datetime, @DataSusStocuri datetime, 
@Locatie char(13), @LM char(9), @Comanda char(40), @Contract char(20), @Furnizor char(20), @Lot char(20)) 
returns char(13) as 
begin
-- select dbo.cautareCodIntrare('801', '27.T', 'C', 'TRANSFBAAAAAA', 22.3, 0, '358', 0, 0, '1901-01-01', '1901-01-01', '', '', '', '', '', '')

declare @CodIntrare char(13), @Sb char(9)
	
select @codIntrarePred=rtrim(@CodIntrarePred),@StocPozitiv=isnull(@StocPozitiv, 0), @DataJosStocuri=isnull(@DataJosStocuri, '01/01/1901'), @DataSusStocuri=isnull(@DataSusStocuri, '01/01/1901'), 
	@Locatie=isnull(@Locatie, ''), @LM=isnull(@LM, ''), @Comanda=isnull(@Comanda, ''), 
	@Contract=isnull(@Contract, ''), @Furnizor=isnull(@Furnizor, ''), @Lot=isnull(@Lot, '')
	
set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
if isnull(@TipGestiune, '')=''
	set @TipGestiune=isnull((select max(tip_gestiune) from gestiuni where subunitate=@Sb and cod_gestiune=@Gestiune), '')
			
-- Daca este pusa o setare, atunci se incearca suprapunerea pe un cod intrare existent:
if @AcCodIPrimitor=1
begin
	declare @lucrCom int, @lucrBK int
	set @lucrCom=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='STOCPECOM'), 0)
	set @lucrBK=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='STOCCOML'), 0)
	-- Dau cod intrare primitor egal cod CodIntrarePredator daca nu exista pozitie in stoc la primitor
	if not exists(select 1 from stocuri s where subunitate=@Sb and tip_gestiune=@TipGestiune and cod_gestiune=@Gestiune and cod=@Cod and s.Cod_intrare=@CodIntrarePred)
		return @CodIntrarePred
	-- Dau cod intrare egal cod CodIntrarePredator daca am acelasi conditii de cont, pret de stoc, pret cu amanuntul, comanda
	if exists(select 1 from stocuri s where subunitate=@Sb and tip_gestiune=@TipGestiune and cod_gestiune=@Gestiune and cod=@Cod 
		and s.pret=@PretStoc and s.pret_cu_amanuntul=@PretAmanunt and s.Cod_intrare=@CodIntrarePred
		and (@lucrCom=0 or s.comanda=@comanda) and (@lucrBK=0 or s.Contract=@Contract)) --nu vine bine cont de stoc... and s.cont=@ContStoc 
		return @CodIntrarePred
	-- Incerc sa dau codprim=codpred+litere EXISTENT
	select top 1 @CodIntrare=s.Cod_intrare from stocuri s where subunitate=@Sb and tip_gestiune=@TipGestiune and cod_gestiune=@Gestiune and cod=@Cod 
		and s.pret=@PretStoc and s.pret_cu_amanuntul=@PretAmanunt 
		and (@lucrCom=0 or s.comanda=@comanda) and (@lucrBK=0 or s.Contract=@Contract) --nu vine bine cont de stoc... and s.cont=@ContStoc 
		and cod_intrare like rtrim(@CodIntrarePred)+'%' and len(cod_intrare)>len(@CodIntrarePred)
		order by len(rtrim(cod_intrare)) desc,rtrim(cod_intrare) desc
	if @CodIntrare is not null
		return @CodIntrare 
	--Verific daca �i pot da pe un cod de intrare existent
	select top 1 @CodIntrare=s.Cod_intrare from stocuri s where subunitate=@Sb and tip_gestiune=@TipGestiune and cod_gestiune=@Gestiune and cod=@Cod 
		and s.pret=@PretStoc and s.pret_cu_amanuntul=@PretAmanunt 
		and (@lucrCom=0 or s.comanda=@comanda) and (@lucrBK=0 or s.Contract=@Contract) --nu vine bine cont de stoc... and s.cont=@ContStoc 
	if @CodIntrare is not null
		return @CodIntrare
end
if isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='CODIVECH'), 0)=0 
/* Aici e noua varianta implicita*/
begin 
	declare @maxIdPozDoc int
	set @maxIdPozDoc=IDENT_CURRENT('pozdoc')
	set @CodIntrare='TI'+ltrim(str(@maxidPozDoc+1))
end
else -- se poate pune setarea ascuns pt. compatibilitate in urma
begin
	/* Daca nu am: caut codIntrarePred+litere*/
	if len(@CodIntrarePred)=13
		set @CodIntrarePred=left(@CodIntrarePred,12)
	select top 1 @CodIntrare=cod_intrare from stocuri where subunitate=@Sb and tip_gestiune=@TipGestiune and cod_gestiune=@Gestiune and cod=@Cod 
		and cod_intrare like rtrim(@CodIntrarePred)+'%[A-Z]' and len(cod_intrare)>len(@CodIntrarePred)
	order by len(rtrim(cod_intrare)) desc,rtrim(cod_intrare) desc

	if @CodIntrare is null
		set @CodIntrare=rtrim(@CodIntrarePred)+CHAR(64)
	/* Voi da cod intrare +A pana la ZZZZ*/
	declare @caracter char(1),@i int,@lungInit int
	set @lungInit=len(rtrim(@CodIntrare))
	set @i=@lungInit
	select @caracter=substring(@CodIntrare,@i,1)
	while @i>len(@CodIntrarePred) and @caracter='Z' -- ABZZ ->i va fi 2 pentru a il face ACAA
	begin
		set @i=@i-1
		select @caracter=substring(@CodIntrare,@i,1)
	end
	set @CodIntrare=substring(@CodIntrare,1,@i)
	if @i=len(@CodIntrarePred)
	begin		
		set @lungInit=@lungInit+1
	end
	else
	begin
		set @CodIntrare=substring(@CodIntrare,1,@i-1)+CHAR(ASCII(@caracter)+1)
	end
	/*Adaugam A-uri la final*/
	while @i<@lungInit
	begin
		set @CodIntrare=rtrim(@Codintrare)+'A'
		set @i=@i+1
	end
end
return @CodIntrare
end
