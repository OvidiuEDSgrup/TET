--***
create procedure iauPozitieStoc @Cod char(20), 
	@TipGestiune char(1) output, @Gestiune char(20) output, @Data datetime output, @CodIntrare char(13) output, 
	@PretStoc float output, @Stoc float output, @ContStoc char(13) output, @DataExpirarii datetime output, 
	@TVAneex float output, @PretAm float output, @Locatie char(30) output, @Serie char(20) output, 
	
	@FltTipGest char(1)=null, @FltGestiuni char(200)=null, @FltExcepGestiuni char(200)=null, @FltData datetime=null, 
	@FltCont char(13)=null, @FltExcepCont char(13)=null, @FltDataExpirarii datetime=null, @FltLocatie char(30)=null, 
	@FltLM char(9)=null, @FltComanda char(40)=null, @FltCntr char(20)=null, @FltFurn char(13)=null, @FltLot char(13)=null, 
	@FltSerie char(20)=null, 
	
	@OrdCont char(13)=null, @OrdGestLista int=null
as

if @FltTipGest is null set @FltTipGest=''
if @FltGestiuni is null set @FltGestiuni=''
if @FltExcepGestiuni is null set @FltExcepGestiuni=''
if isnull(@FltData, '01/01/1901')<='01/01/1901' set @FltData='12/31/2999'
if @FltCont is null set @FltCont=''
if @FltExcepCont is null set @FltExcepCont=''
if isnull(@FltDataExpirarii, '01/01/1901')<='01/01/1901' set @FltDataExpirarii='12/31/2999'
if @FltLocatie is null set @FltLocatie=''
if @FltLM is null set @FltLM=''
if @FltComanda is null set @FltComanda=''
if @FltCntr is null set @FltCntr=''
if @FltFurn is null set @FltFurn=''
if @FltLot is null set @FltLot=''
if @FltSerie is null set @FltSerie=''
if @OrdCont is null set @OrdCont=''
if @OrdGestLista is null set @OrdGestLista=0

declare @Sb char(9), @LIFO int, @FIFOdExp int, @IesiriStocZi int, @IesiriStocLuna int, @Serii int, @AreSerii int,
	@AmListaGestiuni int, @AmListaExcepGestiuni int 

set @Sb=''
set @LIFO=0
set @FIFOdExp=0
set @IesiriStocZi=0
set @Serii=0
set @IesiriStocLuna=0
select 
	@Sb=(case when tip_parametru='GE' and parametru='SUBPRO' then val_alfanumerica else @Sb end),
	@LIFO=(case when tip_parametru='GE' and parametru='LIFO' then val_logica else @LIFO end),
	@FIFOdExp=(case when tip_parametru='GE' and parametru='FIFODEXP' then val_logica else @FIFOdExp end),
	@IesiriStocZi=(case when tip_parametru='GE' and parametru='IESSLAZI' then val_logica else @IesiriStocZi end),
	@IesiriStocLuna=(case when tip_parametru='GE' and parametru='IESLUNCRT' then val_logica else @IesiriStocLuna end),
	@Serii=(case when tip_parametru='GE' and parametru='SERII' then val_logica else @Serii end)
from par where tip_parametru in ('GE')
	
set @AreSerii=(case when @Serii=1 and isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' then 1 else 0 end) 

set @FltGestiuni=LTrim(RTrim(replace(@FltGestiuni, ',', ';')))
while @FltGestiuni<>'' and left(@FltGestiuni, 1) in (';', ' ')
	set @FltGestiuni=substring(@FltGestiuni, 2, len(@FltGestiuni)-1)
while right(rtrim(@FltGestiuni), 1)=';'
	set @FltGestiuni=left(@FltGestiuni, len(@FltGestiuni)-1)
set @AmListaGestiuni=(case when len(@FltGestiuni)>0 and charindex(';', @FltGestiuni)>0 then 1 else 0 end)
if @AmListaGestiuni=1
	set @FltGestiuni=';'+RTrim(@FltGestiuni)+';'

set @FltExcepGestiuni=LTrim(RTrim(replace(@FltExcepGestiuni, ',', ';')))
while @FltExcepGestiuni<>'' and left(@FltExcepGestiuni, 1) in (';', ' ')
	set @FltExcepGestiuni=substring(@FltExcepGestiuni, 2, len(@FltExcepGestiuni)-1)
while right(rtrim(@FltExcepGestiuni), 1)=';'
	set @FltExcepGestiuni=left(@FltExcepGestiuni, len(@FltExcepGestiuni)-1)
set @AmListaExcepGestiuni=(case when len(@FltExcepGestiuni)>0 and charindex(';', @FltExcepGestiuni)>0 then 1 else 0 end)
if @AmListaExcepGestiuni=1
	set @FltExcepGestiuni=';'+RTrim(@FltExcepGestiuni)+';'

set @TipGestiune=null
set @Gestiune=null
set @Data=null
set @CodIntrare=null
set @PretStoc=null
set @Stoc=null
set @ContStoc=null
set @DataExpirarii=null
set @TVAneex=null
set @PretAm=null
set @Locatie=null
set @Serie=null

select top 1 @TipGestiune=s.tip_gestiune, @Gestiune=s.cod_gestiune, @Data=s.data, @CodIntrare=s.cod_intrare, @PretStoc=s.pret, 
	@Stoc=(case when @AreSerii=1 then isnull(sr.stoc, 0) else s.stoc end), 
	@ContStoc=s.cont, @DataExpirarii=s.data_expirarii, @TVAneex=s.TVA_neexigibil, @PretAm=s.pret_cu_amanuntul, 
	@Locatie=s.locatie, @Serie=isnull(sr.serie, '')
from stocuri s
left outer join serii sr on @AreSerii=1 and sr.subunitate=s.subunitate and sr.tip_gestiune=s.tip_gestiune 
	and sr.gestiune=s.cod_gestiune and sr.cod=s.cod and sr.cod_intrare=s.cod_intrare
where s.subunitate=@Sb and s.cod=@Cod and (@FltTipGest='' and s.tip_gestiune not in ('F', 'T') or s.tip_gestiune=@FltTipGest)
and (case when @AreSerii=1 then isnull(sr.stoc, 0) else s.stoc end)>=0.001
and (@AmListaGestiuni=1 or @FltGestiuni='' or s.cod_gestiune=@FltGestiuni) 
and (@AmListaGestiuni=0 or charindex(';'+RTrim(s.cod_gestiune)+';',@FltGestiuni)>0)
and (@AmListaExcepGestiuni=1 or @FltExcepGestiuni='' or s.cod_gestiune<>@FltExcepGestiuni)
and (@AmListaExcepGestiuni=0 or charindex(';'+RTrim(s.cod_gestiune)+';',@FltExcepGestiuni)=0)
and (@IesiriStocZi=0 or s.data<=@FltData) and (@IesiriStocLuna=0 or s.data<=dbo.eom(@FltData))
and (@FltCont='' or s.cont like rtrim(@FltCont)+'%')
and (@FltExcepCont='' or s.cont not like rtrim(@FltExcepCont)+'%')
and s.data_expirarii<=@FltDataExpirarii 
and (@FltLocatie='' or s.locatie=@FltLocatie)
and (@FltLM='' or @FltLM=s.loc_de_munca)
and (@FltComanda='' or @FltComanda=s.comanda)
and (@FltCntr='' or @FltCntr=s.contract)
and (@FltFurn='' or @FltFurn=s.furnizor)
and (@FltLot='' or @FltLot=s.lot)
and (@FltSerie='' or isnull(sr.serie, '')=@FltSerie)

order by (case when @OrdCont='' then 0 when s.cont like rtrim(@OrdCont)+'%' then 1 else 2 end), 
(case when @OrdGestLista=1 then charindex(';'+RTrim(s.cod_gestiune)+';',@FltGestiuni) else 0 end),
(case when @LIFO=0 and @FIFOdExp=0 then s.data else '01/01/1901' end) ASC,
(case when @LIFO=1 then s.data else '01/01/1901' end) DESC,
(case when @FIFOdExp=1 then s.data_expirarii else '01/01/1901' end) ASC,
s.cod_intrare
