create view yso_vIaTerti as
--/*
select rtrim(t.tert) as tert, rtrim(t.denumire) as dentert, rtrim(t.cod_fiscal) as codfiscal, 
rtrim(t.localitate) as localitate, rtrim(isnull(l.oras, t.Localitate)) as denlocalitate, 
rtrim(case when isnull(it.zile_inc, 0)=0 then t.judet else '' end) as judet, rtrim(isnull(j.denumire, t.judet)) as denjudet, 
rtrim(case when isnull(it.zile_inc, 0)>0 then t.judet else '' end) as tara, rtrim(isnull(tari.denumire, '')) as dentara, 
rtrim(t.adresa) as adresa, 
rtrim(case when par.val_logica=1 then left(t.adresa, 30) else '' end) as strada,
rtrim(case when par.val_logica=1 then substring(t.adresa, 31, 8) else '' end) as numar,
rtrim(case when par.val_logica=1 then substring(t.adresa, 39, 6) else '' end) as bloc,
rtrim(case when par.val_logica=1 then substring(t.adresa, 45, 5) else '' end) as scara,
rtrim(case when par.val_logica=1 then substring(t.adresa, 50, 3) else '' end) as apartament,
rtrim(case when par.val_logica=1 then substring(t.adresa, 53, 8) else '' end) as codpostal,
rtrim(telefon_fax) as telefonfax, 
rtrim(t.banca) as banca, rtrim(isnull(b.denumire, '')) as denbanca, rtrim(t.cont_in_banca) as continbanca, 
convert(int, t.tert_extern) as decontarivaluta, rtrim(t.grupa) as grupa, rtrim(isnull(g.denumire, '')) as dengrupa, 
rtrim(t.cont_ca_furnizor) as contfurn, rtrim(isnull(cf.denumire_cont, '')) as dencontfurn, 
rtrim(t.cont_ca_beneficiar) as contben, rtrim(isnull(cb.denumire_cont, '')) as dencontben, 
convert(char(10), (case when t.sold_ca_furnizor<=693961 then '01/01/1901' when t.sold_ca_furnizor>1000000 then '12/31/2999' else dateadd(d, t.sold_ca_furnizor-693961, '01/01/1901') end), 101) as datatert,
convert(int, t.sold_ca_beneficiar) as categpret, rtrim(isnull(categpret.denumire, '')) as dencategpret,
convert(decimal(14, 2), t.sold_maxim_ca_beneficiar) as soldmaxben, convert(decimal(7, 2), t.disccount_acordat) as discount, 
convert(int, isnull(it.sold_ben, 0)) as termenlivrare, convert(int, isnull(it.discount, 0)) as termenscadenta, 
rtrim(isnull(it.nume_delegat, '')) as reprezentant, rtrim(isnull(it.eliberat, '')) as functiereprezentant, 
rtrim(isnull(it.loc_munca, '')) as lm, rtrim(isnull(lm.denumire, '')) as denlm,
rtrim(isnull(it.descriere, '')) as responsabil, rtrim(isnull(p.nume, '')) as denresponsabil,
rtrim(isnull(it.cont_in_banca2, '')) as info1, rtrim(isnull(it.cont_in_banca3, '')) as info2, rtrim(isnull(it.observatii, '')) as info3, 
rtrim(isnull(it.banca3, '')) as nrordreg, 
rtrim(isnull(it.e_mail, '')) as email, 
isnull(it.zile_inc, 0) as tiptert,
(case when it.zile_inc=1 then 'UE' when it.zile_inc=2 then 'Extern' else 'Intern' end) as denTiptert, 
--(case when isnull(it.grupa13, '')='1' then 1 else 0 end) as neplatitortva,
/*Se inlocuieste cu tipTva*/
isnull(ttva.tip_tva,'N') as tiptva,
isnull(it.indicator, 0) as nomspec,
convert(decimal(13, 2), isnull(ff.sold, 0)) as soldfurn, convert(decimal(13, 2), isnull(fb.sold, 0)) as soldben, 
(case when isnull(ff.sold, 0)=0 and isnull(fb.sold, 0)=0 then '#808080' -- fara sold
	when exists(select 1 from proprietati where Cod_proprietate='CI8' and tip='TERT' and valoare='42' and cod=t.Tert) then'#0000FF' 
	when exists(select 1 from proprietati where Cod_proprietate='CI8' and tip='TERT' and valoare='43' and cod=t.Tert) then'#FF0000' 
	else '#000000' end)  as culoare 
--*/select *
from terti t   
left join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
left join judete j on isnull(it.zile_inc, 0)=0 and j.cod_judet=t.judet
left join tari on isnull(it.zile_inc, 0)>0 and tari.cod_tara=t.judet
left join localitati l on l.cod_judet=t.judet and l.cod_oras=t.localitate
left join bancibnr b on b.cod=t.banca
left join gterti g on t.grupa=g.grupa
left join conturi cf on cf.subunitate=t.subunitate and cf.cont=t.cont_ca_furnizor
left join conturi cb on cb.subunitate=t.subunitate and cb.cont=t.cont_ca_beneficiar
left join categpret on categpret.categorie=t.sold_ca_beneficiar
left join lm on lm.cod=it.loc_munca
left join personal p on p.marca=it.descriere
left join par on par.Tip_parametru='GE' AND par.Parametru='ADRCOMP'
left join (select t1.tert, sum(sold) as sold from facturi,terti t1 
	where t1.Subunitate=facturi.Subunitate and t1.tert=facturi.tert and facturi.subunitate='1' and tip=0x54 group by t1.tert) ff on ff.tert=t.tert
left join (select t1.tert, sum(sold) as sold from facturi,terti t1 
	where t1.Subunitate=facturi.Subunitate and t1.tert=facturi.tert and facturi.subunitate='1' and tip=0x46 group by t1.tert) fb on fb.tert=t.tert
outer apply (select top 1 t.tert,isnull(tv.tip_tva,(case when isnull(TipTVA.tip_tva,'P')='I' then 'I' else 'P' end)) as tip_tva
		from (select top 1 tip_tva from TvaPeTerti where TipF='B' and Tert is null and dela<=GETDATE() order by dela desc) tipTva
			cross join TvaPeTerti tv 
		where tv.tipf='F' and t.tert=tv.tert
		order by dela desc
		) ttva
--where t.Denumire like '%abracom%'
