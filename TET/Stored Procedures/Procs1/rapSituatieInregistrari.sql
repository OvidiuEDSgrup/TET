--***
create procedure rapSituatieInregistrari(@sesiune varchar(50)='', @datajos datetime, @datasus datetime, 
		@ordine varchar(1)='0',	--> 0=data, 1=tip document, 2=numar document, 3=loc_de_munca, 4=cont creditor
		--filtre:
		@cont_debitor varchar(40)=null, @cont_creditor varchar(40)=null,
		@nrdoc varchar(40)=null, 
		@loc_de_munca varchar(40)=null, @cont varchar(40)=null, @tipDocLista varchar(300)=null
		)
as

begin
/*	CG/Contabilitate/Situatie inregistrari
declare @datajos datetime,@datasus datetime,@ordine nvarchar(1),@cont_debitor nvarchar(4000),@cont_creditor nvarchar(4000),@nrdoc nvarchar(4000),@loc_de_munca nvarchar(4000),@cont nvarchar(3)
select @datajos='2011-03-01 00:00:00',@datasus='2011-03-31 00:00:00',@ordine=N'0',@cont_debitor=NULL,@cont_creditor=NULL,@nrdoc=NULL,@loc_de_munca=NULL,@cont=N'105'
--*/
--exec fainregistraricontabile @datasus=@datasus

set transaction isolation level read uncommitted
if object_id('tempdb..#tmp') is not null drop table #tmp
if (@cont_debitor is null or @cont_creditor is null)
	select @cont_debitor=isnull(@cont_debitor,''), @cont_creditor=isnull(@cont_creditor,'')
--	declare @tipDocToate varchar(300)
--	select @tipDocToate=',AC,AE,AF,AI,AP,AS,C3,CB,CF,CI,CM,CO,DF,FB,FF,IC,IF,MA,ME,MI,MM,NC,PF,PI,PP,PS,RM,RS,SF,TE,'
if left(@tipDocLista,2)='<>'
	select @tipDocLista=null
if @tipDocLista<>''
begin
	--> filtrare pe grupe de tipuri documente:
	if @tipDocLista like '%pozadoc%' or @tipDocLista like '%altedoc%' select @tipDocLista=tip+','+@tipDocLista from pozadoc p group by p.tip
	if @tipDocLista like '%pozdoc%' or @tipDocLista like '%documente%' select @tipDocLista=p.tip+','+@tipDocLista from pozdoc p group by p.tip
	if @tipDocLista like '%compensari%' set @tipDocLista='CO,C3,CB,CF,'+@tipDocLista
	if @tipDocLista like '%fix%' set @tipDocLista='MA,ME,MI,MM,'+@tipDocLista
	if @tipDocLista like '%note%' set @tipDocLista='NC,MA,IC,PS,'+@tipDocLista

	set @tipDocLista=isnull(','+@tipDocLista+',','')
end
select @tipDocLista=','+rtrim(@tipDocLista)+',', @cont=@cont+'%'

declare @MI int, @ME int	--> MI = intrari mf, ME = iesiri MF
select	@MI=(case when charindex(',MI,',@tipdoclista)>0 then 1 else 0 end),
		@ME=(case when charindex(',ME,',@tipdoclista)>0 then 1 else 0 end)

create table #tmp(tip varchar(1), cont varchar(100))
if @cont_debitor<>''
begin
	select @cont_debitor=rtrim(@cont_debitor)+'%'
	insert into #tmp(tip, cont)
		select 'D' as tip,cont from arbconturi(@cont_debitor)
end
if @cont_creditor<>''
begin
	select @cont_creditor=rtrim(@cont_creditor)+'%'
	insert into #tmp(tip, cont)
		select 'C',cont from arbconturi(@cont_creditor)
end
		--filtrare locuri de munca pe utilizatori
declare @utilizator varchar(20), @eLmUtiliz int
select @utilizator=dbo.fiautilizator(@sesiune)
declare @LmUtiliz table(valoare varchar(200))
insert into @LmUtiliz(valoare)
	select cod from lmfiltrare where utilizator=@utilizator
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

select row_number() over (order by 
		(case @ordine when 0 then convert(char(10),data,102) when 1 then tip_document when 2 then numar_document when 3 then loc_de_munca else cont_creditor end)
	) as nr_crt,tip_document,(case when tip_document='PI' then substring(explicatii,4,charindex(' ',explicatii,4)-4) else numar_document end) as numar_document,data,
	cont_debitor,cont_creditor,suma,explicatii, 
	(case when @ordine=3 then p.loc_de_munca when @ordine=0 then convert(char(10),data,102) when @ordine=1 then p.tip_document
		when p.tip_document='PI' then substring(explicatii,4,charindex(' ',explicatii,4)-4) else p.numar_document end) as grupare,
	lm.denumire as nume_lm
from pozincon p
	left join lm on lm.cod=p.loc_de_munca
where data between @datajos and @datasus and subunitate='1' 
	and (@tipDocLista is null
			or ((charindex(','+Tip_document+',',@tipDocLista)>0) and
			(jurnal<>'MFX' or tip_document not in ('RM','AI','AP','AE'))
			or (@mi=1 and tip_document in ('RM','AI') and jurnal='MFX')
			or (@me=1 and tip_document in ('AP','AE') and jurnal='MFX'))
		)
	and (@nrdoc is null or ltrim(rtrim(numar_document)) like @nrdoc)
	and (@loc_de_munca is null or ltrim(rtrim(p.loc_de_munca)) like @loc_de_munca+'%') 
	and (@cont is null or ltrim(rtrim(p.cont_debitor)) like @cont or ltrim(rtrim(p.cont_creditor)) like @cont)
	and (@cont_debitor='' /*or isnull(p.cont_debitor,'')=''*/ or exists (select 1 from #tmp t where t.tip='D' and t.cont=p.cont_debitor))
	and	(@cont_creditor='' /*or isnull(p.cont_creditor,'')=''*/  or exists (select 1 from #tmp t where t.tip='C' and t.cont=p.cont_creditor))
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
order by grupare, data, tip_document, numar_document
--*/--*/--*/--*/
if object_id('tempdb..#tmp') is not null drop table #tmp
end
