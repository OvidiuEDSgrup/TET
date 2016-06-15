--***
create procedure formezConturiCM @Cod char(20), @CtStoc varchar(40) output, @Gestiune char(9), @CtCheltAntet varchar(40), @LM char(9), @Discount float, 
	@CtCoresp varchar(40) output, @CtInterm varchar(40) output, @CtVenit varchar(40) output, @CtAdaos varchar(40) output, @CtTVANx varchar(40) output 
as

declare @Sb char(9), @CentProf int, @Bugetari int, 
	@CtChPF varchar(40), @AnLMChPF int, @AnCtStPF int, @CtChAmb varchar(40), @CtChMarf varchar(40), @AnGestMarf int, 
	@CtDat60 varchar(40), @AnDat60 int, @AnLM60 int, @AnCtSt60 int, @AnGest30 int, @NrCarGest30 int, 
	@Ct378 varchar(40), @AnGest378 int, @AnGr378 int, @Ct4428 varchar(40), @AnGest4428 int, @ConturiIAS int, @CtCorAntetCM int, 
	@TipNom char(1), @GrNom char(13), @CtNom varchar(40), @TipGest char(1), 
	@LungSinteticCtStoc int, @ParinteCtStoc varchar(40), @BunicCtStoc varchar(40), @AnCtStoc varchar(40), 
	@AnCtCoresp varchar(40), @Ct602 varchar(40) 

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
exec luare_date_par 'GE', 'CENTPROF', @CentProf output, 0, ''
exec luare_date_par 'GE', 'BUGETARI', @Bugetari output, 0, ''
exec luare_date_par 'GE', 'CONTCP', @AnLMChPF output, 0, @CtChPF output
exec luare_date_par 'GE', 'ANCTSPRD', @AnCtStPF output, 0, ''
exec luare_date_par 'GE', 'CMCHAMBAL', 0, 0, @CtChAmb output
exec luare_date_par 'GE', 'CCCMARFA', @AnGestMarf output, 0, @CtChMarf output
exec luare_date_par 'GE', 'CONTDAT', @AnDat60 output, 0, @CtDat60 output
exec luare_date_par 'GE', 'CONTC', @AnLM60 output, 0, ''
exec luare_date_par 'GE', 'CONTANS', @AnCtSt60 output, 0, ''
exec luare_date_par 'GE', 'CONTS', @AnGest30 output, @NrCarGest30 output, ''
if @NrCarGest30=0 set @NrCarGest30=9
exec luare_date_par 'GE', 'CADAOS', @AnGest378 output, @AnGr378 output, @Ct378 output
exec luare_date_par 'GE', 'CNTVA', @AnGest4428 output, 0, @Ct4428 output
exec luare_date_par 'GE', 'CONTIAS', @ConturiIAS output, 0, ''
exec luare_date_par 'GE', 'CCORANTCM', @CtCorAntetCM output, 0, ''

set @TipNom=''
set @GrNom=''
set @CtNom=''
set @TipGest=''
set @ParinteCtStoc=''
set @BunicCtStoc=''
set @AnCtStoc=''


select @TipNom=tip, @GrNom=grupa, @CtNom=cont
from nomencl
where cod=isnull(@Cod,'')

select @TipGest=tip_gestiune
from gestiuni
where subunitate=@Sb and cod_gestiune=isnull(@Gestiune,'')

if isnull(@CtStoc, '')='' set @CtStoc=dbo.formezContStoc(isnull(@Gestiune,''), isnull(@Cod,''), isnull(@LM,''))

select @ParinteCtStoc=cont_parinte
from conturi
where subunitate=@Sb and cont=@CtStoc

select @BunicCtStoc=cont_parinte
from conturi
where @ParinteCtStoc<>'' and subunitate=@Sb and cont=@ParinteCtStoc

set @LungSinteticCtStoc=Len(RTrim(case when /*charindex('.', @CtStoc)=0 and */(Len(@ParinteCtStoc)<3 or Len(@ParinteCtStoc)=3 and left(@CtStoc, 3) in ('302', '303')) 
	then @CtStoc when Len(@BunicCtStoc)<=3 then @ParinteCtStoc else @BunicCtStoc end))
--set @AnCtStoc=(case when @ParinteCtStoc<>'' then substring(@CtStoc, len(@ParinteCtStoc)+1, 13) else '' end)
set @AnCtStoc=RTrim(substring(@CtStoc, @LungSinteticCtStoc + 1, 20))

if ISNULL(@CtCoresp, '')=''
	set @CtCoresp=null 
if ISNULL(@CtInterm, '')=''
	set @CtInterm=null 
set @CtVenit=null 
set @CtAdaos=null 
set @CtTVANx=null

if @CtCoresp is null and @CtCorAntetCM=1 and isnull(@CtCheltAntet, '')<>''
	set @CtCoresp=@CtCheltAntet
if @CtCoresp is null and left(@CtStoc, 1)='8'
	set @CtCoresp=''
if @CtCoresp is null and left(@CtStoc, 4)='5328'
	set @CtCoresp='604'
if @CtCoresp is null
begin
	set @Ct602=(case when left(@CtStoc, 3) in ('302', 'x303') then '60'+RTrim(substring(@CtStoc, 3, @LungSinteticCtStoc-2)) else '' end)
	
	set @AnCtCoresp=(case 
		when left(@CtStoc, 3)='371' and @AnGestMarf=1 then '.'+isnull(@Gestiune,'') 
		when @AnDat60=1 and left(@CtStoc, 2)<>'34' then '.'+@CtDat60 
		when @CentProf=1 and left(@CtStoc, 2)='34' and @AnLMChPF=1 or left(@CtStoc, 2)<>'34' and @AnLM60=1 then '.'+isnull(@LM,'') 
		when left(@CtStoc, 2)='30' and @AnCtSt60=1 and not (left(@CtStoc, 3) in ('302', '303') and len(@ParinteCtStoc)<=3) 
			or @AnCtStPF=1 and @TipNom='P' then @AnCtStoc else '' end)
	
	set @CtCoresp=(case 
		when left(@CtStoc, 2) in ('33', '34') then @CtChPF 
		when left(@CtStoc, 3)='381' then @CtChAmb 
		when left(@CtStoc, 3) in ('301', '351') then '601' 
		when @Ct602<>'' then @Ct602 
		when @CtChMarf<>'' then @CtChMarf
		when @ConturiIAS=1 then '602' else '601' end)
	set @CtCoresp=RTrim(@CtCoresp)+RTrim(@AnCtCoresp)
end

if left(@CtStoc, 1)='8'
	set @CtInterm=''
if @CtInterm is null and left(@CtStoc, 3) not in ('300', '301', '302', '308') and left(@CtCoresp, 3) in ('600', '601', '602')
	set @CtInterm=(case when left(@CtCoresp, 3)='600' or @ConturiIAS=1 and left(@CtCoresp, 3)='601' then (case when @Bugetari=1 then '' when @ConturiIAS=1 then '301' else '300' end) else '30'+RTrim(substring(@CtCoresp, 3, 11))+(case when @AnGest30=1 then '.'+left(isnull(@Gestiune,''), @NrCarGest30) else '' end) end)
if @CtInterm is null
	set @CtInterm=''

set @CtVenit=(case when left(@CtStoc, 1)='8' or @Discount=0 then '' else '308' end)

set @CtAdaos=(case when @TipGest in ('A', 'V') and left(@CtStoc, 2) in ('35', '37') then RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(isnull(@Gestiune,'')) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end) else '' end)

set @CtTVANx=(case when @TipGest in ('A', 'V') and left(@CtStoc, 2) in ('35', '37') then RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(isnull(@Gestiune,'')) else '' end) else '' end)
