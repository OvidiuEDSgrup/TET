--***
Create procedure [dbo].[wIaPreturiNomenclator]   @sesiune varchar(30), @parXML XML
as

begin
	if exists(select * from sysobjects where name='wIaPreturiNomenclatorSP' and type='P')
	begin
		exec wIaPreturiNomenclatorSP @sesiune, @parXML 
		return
	end

declare @cod varchar(20),@cautare varchar(100), @lista_categpret int, @nrcateg int, @nrcategmax int
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
set @cautare=@parXML.value('(/row/@_cautare)[1]','varchar(100)')
set @cautare='%'+isnull(@cautare,'')+'%'
set @lista_categpret=(case when exists (select 1 from fPropUtiliz(@sesiune) where cod_proprietate='CATEGPRET' and valoare<>'')then 1 else 0 end)
select @nrcateg =count(1) from categpret 
if LEN(@cautare)>2
	set @nrcateg=0 -- daca foloseste cautarea se afiseaza istoricul de preturi
else
	set @nrcategmax=4

select rtrim(cod_produs) as cod,
rtrim(cp.categorie) as catpret,
rtrim(cp.Denumire) as 'dencategpret',
rtrim(p.tip_pret) as tippret,
dtp.denumire as dentippret,
convert(char(10),data_inferioara,101) as data_inferioara,
convert(char(10),data_superioara,101) as data_superioara,
convert(decimal(12,3),p.Pret_vanzare) as pret_vanzare,
convert(decimal(12,3),p.Pret_cu_amanuntul) as pret_cu_amanuntul,
rank() over (partition by cp.categorie, tip_pret, p.umprodus order by data_inferioara desc) as ranc, 
(case when getdate() > data_superioara then '#808080' -- istorie
	else '#000000' end)  as culoare,
	rtrim(nullif(um.um,'')) um,
	rtrim(isnull(nullif(um.denumire,''),'['+rtrim(um1.Denumire)+']')) denum,
	convert(decimal(12,2),isnull(u.coeficient,1)) as coeficientum,
	convert(Decimal(12,3),convert(decimal(12,2),isnull(u.coeficient,1))*convert(decimal(12,3),p.Pret_cu_amanuntul)) as pretum
into #pret
from preturi p
inner join categpret cp on p.UM=cp.Categorie
inner join dbo.fTipPret() dtp on p.tip_pret=dtp.tipPret
left outer join fPropUtiliz(@sesiune) fp on cod_proprietate='CATEGPRET' and cp.categorie=fp.valoare
LEFT JOIN UMProdus u on u.cod=p.Cod_produs and p.umprodus=u.UM
LEFT JOIN UM on um.UM=u.UM
left join nomencl n on p.cod_produs=n.cod
left join um um1 on n.um=um1.um
where p.Cod_produs=@cod
and rtrim(cp.Denumire) like @cautare
and (@lista_categpret=0 OR fp.valoare is not null)
and (@nrcateg<@nrcategmax or getdate() between data_inferioara and data_superioara)

select * from #pret
where @nrcateg<@nrcategmax or ranc=1
for xml raw

drop table #pret

end
