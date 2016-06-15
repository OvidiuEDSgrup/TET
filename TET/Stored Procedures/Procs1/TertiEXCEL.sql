--***
create procedure TertiEXCEL @idRulare int
as
if exists (select * from sysobjects where name='TertiEXCELSP' and type='P')
	exec TertiEXCELSP @idRulare
else
begin	
declare @parxml xml, @denumire varchar(80), @tiptert varchar(20), @tip_tva varchar(20), @judet varchar(50), @denjudet varchar(50), 
		@localitate varchar(50), @denlocalitate varchar(50), @denlm varchar(50)

select top 1 @parxml=parxml from ASiSRIA..ProceduriDeRulat
where idRulare=@idRulare

select  @denumire = replace(isnull(@parXML.value('(/*/@cod_tert)[1]','varchar(80)'),''), ' ', '%'),
		@tiptert=isnull(@parxml.value('(/*/@cod_tiptert)[1]', 'varchar(20)'),3),
		@tip_tva=isnull(@parxml.value('(/*/@cod_tip_tva)[1]', 'varchar(20)'),''),
		@judet=isnull(@parxml.value('(/*/@cod_judet)[1]', 'varchar(50)'), ''),
		@denjudet=isnull(@parxml.value('(/*/@denjudet)[1]', 'varchar(50)'), ''),
		@localitate=isnull(@parxml.value('(/*/@cod_localitate)[1]', 'varchar(50)'), ''),
		@denlocalitate=isnull(@parxml.value('(/*/@denlocalitate)[1]', 'varchar(50)'), ''),
		@denlm=isnull(@parxml.value('(/*/@denlm)[1]', 'varchar(50)'), '')

select 
	rtrim(isnull(t.Tert, '')) as Tert, 
	rtrim(isnull(t.Denumire, '')) as Denumire, 
	rtrim(t.cod_fiscal) as Cod_fiscal, 
	rtrim(isnull(it.Banca3, '')) as Nr_Ord_Reg, -- <== nr.ord.reg.
	rtrim(isnull(tari.denumire, '')) as Tara,
	rtrim(isnull(j.denumire, t.Judet)) as Judet, 
	rtrim(isnull(l.oras, t.Localitate)) as Localitate,
	rtrim(isnull(t.Adresa, '')) as Adresa, 
	rtrim(isnull(t.Telefon_fax, '')) as Telefon_fax, 
	rtrim(isnull(it.loc_munca, '')) as Locmunca, 
	rtrim(isnull(lm.denumire, '')) as Denlocmunca, 
	case when t.disccount_acordat=0 then '' else rtrim(convert(varchar(20),convert(decimal(12,2), t.disccount_acordat))) end as Discount, 
	rtrim(t.banca) as banca, rtrim(t.cont_in_banca) as Cont_in_banca,  
	rtrim(isnull(gt.Denumire, '')) as Grupa,
	--convert(int, t.tert_extern) as Decontari_in_valuta,
	(case tip.tip_tva when 'P' then 'Platitor' when 'N' then 'Neplatitor' when 'I' then 'La incasare' else 'Platitor' end) as Tip_tva,
	(case t.Tert_extern when 0 then 'Intern' when 1 then 'UE' when 2 then 'Extern' else '' end) as Tip_tert,
	convert(int, isnull(it.discount, 0)) as Interval_scadenta

from terti t
left join gterti gt on gt.Grupa=t.Grupa
left join infotert it on it.Tert=t.Tert and it.identificator=''
left join judete j on j.cod_judet = t.judet
left join tari on (tari.cod_tara = 'RO' and t.tert_extern = 0) or (t.tert_extern = 1 and tari.cod_tara = t.judet)
left join localitati l on l.cod_judet=t.judet and l.cod_oras=t.localitate
left join bancibnr b on b.cod=t.banca
left join lm on lm.cod=it.loc_munca 
outer apply (select top 1 tip_tva from tvapeterti tpt where tpt.Tert=t.Tert order by dela desc) as tip
where (@denumire='' or t.Denumire like '%'+@denumire+'%')
	and (@tiptert=3 or t.Tert_extern=@tiptert) 
	and (@tip_tva='' or tip.tip_tva=@tip_tva)
	and (@judet = '' or rtrim(isnull(j.cod_judet, t.Judet))=@judet or t.Judet=@denjudet)
	and (@localitate = '' or rtrim(isnull(l.cod_oras, t.Localitate))=@localitate or t.Localitate=@denlocalitate)
	and (@denlm = '' or lm.denumire=@denlm)
order by t.Denumire
end
