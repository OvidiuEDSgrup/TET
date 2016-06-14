
--declare @dData datetime,@cCod nvarchar(4000),@tipgest nvarchar(1),@cGestiune nvarchar(4000),@grupare nvarchar(1),
--		@tipstoc nvarchar(1),@grPret bit,@locm nvarchar(4000),@cont nvarchar(4000),@ordonare nvarchar(1), @tip_pret int, @grupa varchar(20)
--select	@dData='2012-04-30 00:00:00',@cCod=null,@tipgest=N'D',@cGestiune='101',@tip_pret=N'0',@grupare=N'0',@tipstoc=N'D',@grPret=0,
--		@locm=NULL,@cont=NULL,@ordonare=N'd', @grupa=null


select ff.gestiune,ff. cod,ff. stoc_scriptic,ff. pret,ff. valoare,ff. val_unit,ff. data,ff. cod_intrare,ff. loc_de_munca,
rtrim(n.denumire) as denumire,rtrim(n.um)as um, (case when @tipstoc='F' then rtrim(p.nume) else
 rtrim(g.denumire_gestiune) end) as den_gest, l.Denumire as nume_lm, ff.locatie, lc.Descriere as descriere_locatie,
 ff.furnizor, t.Denumire as denumire_furnizor from
(select max(t.gestiune) as gestiune, t.cod, sum(t.stoc_scriptic) as stoc_scriptic, max(t.pret) as pret, 
(case when abs(sum(t.stoc_scriptic))<0.001 then 0 else sum(t.stoc_scriptic*pret) end) as valoare, 
(case when abs(sum(t.stoc_scriptic))<0.001 then 0 else sum(t.stoc_scriptic*pret)/sum(t.stoc_scriptic) end) as val_unit, 
min(t.data) as data, max(t.cod_intrare) as cod_intrare, MAX(loc_de_munca) as loc_de_munca,
MAX(t.locatie) as locatie, MAX(t.furnizor) as furnizor
from
(select a.gestiune as gestiune, a.cont, a.cod as cod, a.data as data, a.data_expirarii, a.cod_intrare, 
(case when gs.tip_gestiune ='A' then a.pret_cu_amanuntul else a.pret end) as pret, 
(case when a.tip_miscare='I' then a.cantitate else -a.cantitate end) as stoc_scriptic, 
--    (case when @grupare=0 then '' else loc_de_munca end) as 
loc_de_munca, coalesce(nullif(a.locatie,''),sl.Locatie,'') as locatie, a.furnizor
from dbo.fStocuri (@dData, @dData, @cCod,@cGestiune, null, @grupa, @tipstoc, @cont, 0, '', @locm, '', '', '', '') a
--from dbo.fStocuri(@dData, @dData, @cCod,@cGestiune, null, '', @tipstoc, '', 0, '', '', '', '', '', '')
left join gestiuni gs on a.gestiune=gs.cod_gestiune 
left join stoclim sl on sl.Subunitate='1' and sl.Tip_gestiune=gs.Tip_gestiune and sl.Cod_gestiune=a.gestiune 
	and sl.Cod=a.cod and sl.Data= '2999-12-31'
)t
group by gestiune, cod, pret --(case when @grPret=0 then '' else pret end)
having abs(sum(t.stoc_scriptic))>0.0001 or abs(sum(t.stoc_scriptic*t.pret))>0.001) ff
inner join nomencl n on ff.cod=n.cod
left join gestiuni g on ff.gestiune=g.cod_gestiune 
left join personal p on ff.gestiune=p.marca
left join lm l on l.cod=ff.loc_de_munca
left join locatii lc on lc.Cod_gestiune=ff.gestiune and lc.Cod_locatie=ff.locatie
left join terti t on t.Tert=ff.furnizor
--group by ff.gestiune, ff.loc_de_munca
order by (case when @grupare=1 then ff.loc_de_munca else ff.gestiune end), (case when @ordonare='c' then ff.cod else n.Denumire end)


--120 48 006 0