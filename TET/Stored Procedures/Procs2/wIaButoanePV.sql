
create procedure wIaButoanePV @sesiune varchar(50), @parXML xml
as

declare
	@f_codButon varchar(50), @f_label varchar(500), @f_tipButon varchar(50), @f_activ varchar(10), @f_aparePV varchar(10), @f_apareOP varchar(10), 
	@f_procServer int, @f_tipIncasare varchar(50), @activ bit, @aparePV bit, @apareOP bit

select
	@f_codButon = @parXML.value('(/row/@f_codButon)[1]','varchar(50)'),
	@f_label = @parXML.value('(/row/@f_label)[1]','varchar(500)'),
	@f_tipButon = @parXML.value('(/row/@f_tipButon)[1]','varchar(50)'),
	@f_activ = @parXML.value('(/row/@f_activ)[1]','varchar(10)'),
	@f_aparePV = @parXML.value('(/row/@f_aparePV)[1]','varchar(10)'),
	@f_apareOP = @parXML.value('(/row/@f_apareOP)[1]','varchar(10)'),
	@f_procServer = @parXML.value('(/row/@f_procServer)[1]','int'),
	@f_tipIncasare = @parXML.value('(/row/@f_tipIncasare)[1]','varchar(50)')

select
	@activ = (case when @f_activ in ('1','Da') then 1 when @f_activ in ('0','Nu') then 0 else null end),
	@aparePV = (case when @f_aparePV in ('1','Da') then 1 when @f_aparePV in ('0','Nu') then 0 else null end),
	@apareOP = (case when @f_apareOP in ('1','Da') then 1 when @f_apareOP in ('0','Nu') then 0 else null end)

declare
	@tipIncasare table(tip int, denumire varchar(50))

if isnull(@f_tipIncasare,'') <> ''
begin
	insert into @tipIncasare(tip,denumire)
	select distinct tipIncasare as tip, dbo.denTipIncasare(tipIncasare) as denumire
	from butoanePv
	where isnull(tipIncasare,'')<>''
end

select top 100
	rtrim(isnull(b.codButon,'')) as codButon,
	rtrim(isnull(b.label,'')) as label,
	rtrim(isnull(b.tipButon,'')) as tipButon,
	rtrim(isnull(b.culoare,'')) as culoare,
	b.activ as activ,
	(case when b.activ=1 then 'Da' else 'Nu' end) as den_activ,
	b.ordine as ordine,
	b.ctrlkey as ctrlkey,
	(case when b.ctrlKey=1 then 'Da' else 'Nu' end) as den_ctrlkey,
	rtrim(isnull(b.tasta,'')) as tasta,
	isnull(b.procesarePeServer,0) as procServer,
	b.apareInPV as aparePV,
	(case when apareInPv=1 then 'Da' else 'Nu' end) as den_aparePV,
	b.apareInOperatii as apareOP,
	(case when b.apareInOperatii=1 then 'Da' else 'Nu' end) as den_apareOP,
	b.tipIncasare as tipIncasare,
	isnull(dbo.denTipIncasare(b.tipIncasare),isnull(b.tipIncasare,'')) as dentipIncasare,
	rtrim(isnull(b.meniu,'')) as meniuPV,
	rtrim(isnull(b.tip,'')) as tipPV,
	rtrim(isnull(b.subtip,'')) as subtipPV,
	rtrim(isnull(b.utilizator,'')) as utilizator
from butoanePv b
	left join @tipIncasare t on b.tipIncasare=t.tip
where
	(@f_codButon is null or b.codButon like '%' + @f_codButon + '%')
	and (@f_label is null or isnull(b.label,'') like '%' + @f_label + '%')
	and (@f_tipButon is null or isnull(b.tipButon,'') like '%' + @f_tipButon + '%')
	and (@activ is null or isnull(b.activ,0)=@activ)
	and (@aparePV is null or isnull(b.apareInPv,0)=@aparePV)
	and (@apareOP is null or isnull(b.apareInOperatii,0)=@apareOP)
	and (@f_procServer is null or isnull(b.procesarePeServer,0)=@f_procServer)
	and (@f_tipIncasare is null or isnull(t.denumire,'') like '%' + @f_tipIncasare + '%')
for xml raw
